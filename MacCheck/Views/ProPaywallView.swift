import SwiftUI

/// Backward-compatible entry point. Prefer `PaywallView` for new code.
struct ProPaywallView: View {
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var body: some View {
        PaywallView()
            .environmentObject(storeKitManager)
            .environmentObject(entitlementManager)
    }
}

#Preview {
    let entitlementManager = EntitlementManager()
    return ProPaywallView()
        .environmentObject(StoreKitManager(entitlementManager: entitlementManager))
        .environmentObject(entitlementManager)
}
