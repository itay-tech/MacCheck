import SwiftUI

/// Presents the paywall sheet with the same StoreKitManager / EntitlementManager instances from the app root.
struct ProPaywallSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    var source: PaywallSource

    @EnvironmentObject private var storeKitManager: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ProPaywallView()
                    .environmentObject(storeKitManager)
                    .environmentObject(entitlementManager)
            }
            .onChange(of: isPresented) { _, isShowing in
                if isShowing {
                    PostHogService.shared.track(.paywallViewed(source: source))
                }
            }
    }
}

extension View {
    func proPaywallSheet(isPresented: Binding<Bool>, source: PaywallSource = .unknown) -> some View {
        modifier(ProPaywallSheetModifier(isPresented: isPresented, source: source))
    }
}
