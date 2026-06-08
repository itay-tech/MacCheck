import SwiftUI

/// Backward-compatible entry point. Prefer `PaywallView` for new code.
struct ProPaywallView: View {
    var body: some View {
        PaywallView()
    }
}

#Preview {
    let entitlementManager = EntitlementManager()
    return ProPaywallView()
        .environmentObject(StoreKitManager(entitlementManager: entitlementManager))
        .environmentObject(entitlementManager)
}
