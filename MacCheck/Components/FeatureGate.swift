import SwiftUI

struct FeatureGate<Content: View>: View {
    let feature: ProFeature
    @Binding var showPaywall: Bool
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var entitlementManager: EntitlementManager

    var body: some View {
        if entitlementManager.hasAccess(to: feature) {
            content()
        } else {
            LockedFeatureView(feature: feature) {
                showPaywall = true
            }
        }
    }
}

#Preview {
    @Previewable @State var showPaywall = false

    return FeatureGate(feature: .predictions, showPaywall: $showPaywall) {
        Text("Pro content")
    }
    .environmentObject(EntitlementManager())
    .padding()
}
