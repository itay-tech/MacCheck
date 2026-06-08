import SwiftUI

struct ProUpgradeToolbarContent: ToolbarContent {
    @Binding var showPaywall: Bool

    @EnvironmentObject private var entitlementManager: EntitlementManager

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if entitlementManager.isPro {
                ProBadge()
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("Upgrade")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    @Previewable @State var showPaywall = false

    return NavigationStack {
        Text("Preview")
            .toolbar {
                ProUpgradeToolbarContent(showPaywall: $showPaywall)
            }
    }
    .environmentObject(EntitlementManager())
}
