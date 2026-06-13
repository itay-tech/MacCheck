import SwiftUI

/// Presents the paywall sheet with the same StoreKitManager / EntitlementManager instances from the app root.
struct ProPaywallSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    @EnvironmentObject private var storeKitManager: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ProPaywallView()
                .environmentObject(storeKitManager)
                .environmentObject(entitlementManager)
        }
    }
}

extension View {
    func proPaywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(ProPaywallSheetModifier(isPresented: isPresented))
    }
}
