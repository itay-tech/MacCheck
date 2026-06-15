import Combine
import Foundation
import StoreKit

/// StoreKit 2 purchase and entitlement layer for MacCheck Pro Lifetime.
@MainActor
final class StoreKitManager: ObservableObject {

    static let lifetimeProductID = "com.raytech.MacCheck.pro.lifetime"
    static let productLoadFailureMessage = "Unable to load purchase information."

    static var allProductIDs: [String] {
        [lifetimeProductID]
    }

    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var productLoadError: String?
    @Published private(set) var purchaseError: String?
    @Published private(set) var purchaseSuccessMessage: String?
    @Published private(set) var restoreNotice: String?

    private let entitlementManager: EntitlementManager
    private var transactionListener: Task<Void, Never>?
    private var productLoadTask: Task<Void, Never>?
    private var hasAttemptedProductLoad = false
    private(set) var lastRequestedProductIDs: [String] = []
    private(set) var lastLoadedProductsCount = 0
    private(set) var lastReturnedProductIDs: [String] = []
    private(set) var lastProductLoadErrorDescription: String?

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        transactionListener = listenForTransactionUpdates()

        print("[StoreKit] Startup instance=\(ObjectIdentifier(self))")
        Task {
            await start()
        }
    }

    deinit {
        transactionListener?.cancel()
        productLoadTask?.cancel()
    }

    var displayPrice: String {
        lifetimeProduct?.displayPrice ?? "Price unavailable"
    }

    var canPurchase: Bool {
        lifetimeProduct != nil && !isPurchasing
    }

    var purchaseButtonDisabledReason: String {
        if entitlementManager.isPro {
            return "User already owns Pro"
        }
        if isPurchasing {
            return "Purchase in progress"
        }
        if isLoadingProducts {
            return "Products still loading"
        }
        if lifetimeProduct == nil {
            if let productLoadError {
                return productLoadError
            }
            if hasAttemptedProductLoad {
                return "Product unavailable after load attempt"
            }
            return "Products not loaded yet"
        }
        return "Enabled"
    }

    var storeKitConfigurationHint: String {
        let environment = ProcessInfo.processInfo.environment
        let candidateKeys = [
            "STOREKIT_CONFIGURATION_FILE_PATH",
            "IDEStoreKitConfigurationPath",
            "XCODE_STOREKIT_CONFIGURATION_PATH"
        ]

        for key in candidateKeys {
            if let value = environment[key], !value.isEmpty {
                return "detected via \(key): \(value)"
            }
        }

        return "not detectable at runtime (use Xcode Run with Scheme → Run → Options → StoreKit Configuration = MacCheck.storekit)"
    }

    // MARK: - Startup

    func start() async {
        await loadProductsIfNeeded()
        await refreshEntitlements()
    }

    /// Loads products once, or waits for an in-flight load. Safe to call from paywall onAppear.
    func loadProductsIfNeeded(force: Bool = false) async {
        if !force, lifetimeProduct != nil {
            print("[StoreKit] Product already cached: \(Self.lifetimeProductID)")
            printPaywallDiagnostics(context: "loadProductsIfNeeded skipped (cached)")
            return
        }

        if let productLoadTask {
            print("[StoreKit] Waiting for in-flight product load")
            await productLoadTask.value
            printPaywallDiagnostics(context: "loadProductsIfNeeded waited for in-flight load")
            return
        }

        let task = Task { @MainActor in
            await performProductLoad(force: force)
        }
        productLoadTask = task
        await task.value
        productLoadTask = nil
    }

    /// Backward-compatible entry point used by callers expecting an unconditional reload attempt.
    func loadProducts() async {
        await loadProductsIfNeeded(force: true)
    }

    func printPaywallDiagnostics(context: String) {
        print("[Paywall] Diagnostics (\(context))")
        print("[StoreKit] instance=\(ObjectIdentifier(self))")
        print("[StoreKit] StoreKit configuration: \(storeKitConfigurationHint)")
        print("[StoreKit] Requested product IDs: \(lastRequestedProductIDs.isEmpty ? Self.allProductIDs : lastRequestedProductIDs)")
        print("[StoreKit] Products loaded: \(lastLoadedProductsCount)")
        print("[StoreKit] Product IDs returned: \(lastReturnedProductIDs)")
        if let product = lifetimeProduct {
            print("[StoreKit] Found product: \(product.id) (\(product.displayPrice))")
        } else if hasAttemptedProductLoad {
            print("[StoreKit] Missing expected product: \(Self.lifetimeProductID)")
        }
        if let lastProductLoadErrorDescription {
            print("[StoreKit] Product load error: \(lastProductLoadErrorDescription)")
        }
        print("[Paywall] lifetimeProduct == nil: \(lifetimeProduct == nil)")
        print("[Paywall] isLoadingProducts: \(isLoadingProducts)")
        print("[Paywall] isPurchasing: \(isPurchasing)")
        print("[Paywall] canPurchase: \(canPurchase)")
        print("[Paywall] Disabled reason: \(purchaseButtonDisabledReason)")
        print("[Paywall] productLoadError: \(productLoadError ?? "nil")")
        print("[Paywall] Purchase button \(canPurchase ? "enabled" : "disabled")")
        print("[StoreKit] Current entitlement state: isPro=\(entitlementManager.isPro)")
    }

    // MARK: - Purchase

    func purchaseLifetime() async {
        if lifetimeProduct == nil {
            await loadProductsIfNeeded(force: true)
        }

        guard let product = lifetimeProduct else {
            purchaseError = Self.productLoadFailureMessage
            PostHogService.shared.track(.purchaseFailed(errorType: "product_unavailable"))
            printPaywallDiagnostics(context: "purchaseLifetime blocked")
            return
        }

        isPurchasing = true
        purchaseError = nil
        purchaseSuccessMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await handlePurchaseVerification(verification)

            case .userCancelled:
                break

            case .pending:
                purchaseError = "Purchase is pending approval."
                PostHogService.shared.track(.purchaseFailed(errorType: "pending"))

            @unknown default:
                purchaseError = "Purchase could not be completed."
                PostHogService.shared.track(.purchaseFailed(errorType: "unknown"))
            }
        } catch {
            purchaseError = error.localizedDescription
            PostHogService.shared.track(.purchaseFailed(errorType: "storekit_error"))
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        restoreNotice = nil
        defer { isPurchasing = false }

        do {
            try await StoreKit.AppStore.sync()
            await refreshEntitlements()

            if entitlementManager.isPro {
                restoreNotice = "Your MacCheck Pro purchase has been restored."
            } else {
                restoreNotice = "No previous purchase found."
            }
        } catch {
            restoreNotice = error.localizedDescription
        }
    }

    func clearPurchaseSuccess() {
        purchaseSuccessMessage = nil
    }

    func clearRestoreNotice() {
        restoreNotice = nil
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var ownsLifetime = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.lifetimeProductID else { continue }
            guard transaction.revocationDate == nil else { continue }

            ownsLifetime = true
        }

        entitlementManager.applyOwnership(isPro: ownsLifetime)
        print("[StoreKit] Current entitlement state: isPro=\(ownsLifetime)")
    }

    // MARK: - Private

    private func performProductLoad(force: Bool) async {
        isLoadingProducts = true
        productLoadError = nil
        defer {
            isLoadingProducts = false
            hasAttemptedProductLoad = true
        }

        let requestedIDs = Self.allProductIDs
        lastRequestedProductIDs = requestedIDs
        lastProductLoadErrorDescription = nil

        print("[StoreKit] Requesting products: \(requestedIDs)")

        do {
            let products = try await Product.products(for: requestedIDs)
            lastLoadedProductsCount = products.count
            lastReturnedProductIDs = products.map(\.id)

            print("[StoreKit] Products loaded: \(products.count)")
            print("[StoreKit] Product IDs returned: \(lastReturnedProductIDs)")

            if let product = products.first(where: { $0.id == Self.lifetimeProductID }) {
                lifetimeProduct = product
                productLoadError = nil
                print("[StoreKit] Found product: \(product.id) (\(product.displayPrice))")
            } else {
                if lifetimeProduct == nil {
                    productLoadError = Self.productLoadFailureMessage
                    PostHogService.shared.track(.productLoadFailed(reason: "product_missing"))
                } else {
                    print("[StoreKit] Reload returned 0 matching products; keeping cached product")
                }
                print("[StoreKit] Missing expected product: \(Self.lifetimeProductID)")
            }
        } catch {
            lastLoadedProductsCount = 0
            lastReturnedProductIDs = []
            lastProductLoadErrorDescription = error.localizedDescription

            if lifetimeProduct == nil {
                productLoadError = Self.productLoadFailureMessage
                PostHogService.shared.track(.productLoadFailed(reason: "storekit_error"))
            } else {
                print("[StoreKit] Reload failed; keeping cached product")
            }
            print("[StoreKit] Product load failed: \(error.localizedDescription)")
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.lifetimeProductID else { return }
            await refreshEntitlements()
            await transaction.finish()

        case .unverified:
            break
        }
    }

    private func handlePurchaseVerification(_ verification: VerificationResult<Transaction>) async {
        switch verification {
        case .verified(let transaction):
            guard transaction.productID == Self.lifetimeProductID else {
                purchaseError = "Unexpected product purchased."
                PostHogService.shared.track(.purchaseFailed(errorType: "unexpected_product"))
                return
            }

            await refreshEntitlements()
            await transaction.finish()
            purchaseSuccessMessage = "MacCheck Pro unlocked successfully."
            PostHogService.shared.track(.purchaseCompleted(productID: transaction.productID))

        case .unverified:
            purchaseError = "Purchase could not be verified."
            PostHogService.shared.track(.purchaseFailed(errorType: "verification_failed"))
        }
    }
}
