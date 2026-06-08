import Combine
import Foundation
import StoreKit

/// StoreKit 2 purchase and entitlement layer for MacCheck Pro Lifetime.
@MainActor
final class StoreKitManager: ObservableObject {

    static let lifetimeProductID = "com.raytech.MacCheck.pro.lifetime"

    static var allProductIDs: [String] {
        [lifetimeProductID]
    }

    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var purchaseError: String?
    @Published private(set) var purchaseSuccessMessage: String?
    @Published private(set) var restoreNotice: String?

    private let entitlementManager: EntitlementManager
    private var transactionListener: Task<Void, Never>?

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        transactionListener = listenForTransactionUpdates()

        Task {
            await start()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var displayPrice: String {
        lifetimeProduct?.displayPrice ?? "Price unavailable"
    }

    var canPurchase: Bool {
        lifetimeProduct != nil && !isPurchasing
    }

    // MARK: - Startup

    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: Self.allProductIDs)
            lifetimeProduct = products.first(where: { $0.id == Self.lifetimeProductID })
        } catch {
            lifetimeProduct = nil
            purchaseError = "Unable to load App Store pricing."
        }
    }

    // MARK: - Purchase

    func purchaseLifetime() async {
        guard let product = lifetimeProduct else {
            purchaseError = "Product unavailable. Please try again later."
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

            @unknown default:
                purchaseError = "Purchase could not be completed."
            }
        } catch {
            purchaseError = error.localizedDescription
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
    }

    // MARK: - Private

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
                return
            }

            await refreshEntitlements()
            await transaction.finish()
            purchaseSuccessMessage = "MacCheck Pro unlocked successfully."

        case .unverified:
            purchaseError = "Purchase could not be verified."
        }
    }
}
