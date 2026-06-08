import SwiftUI

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            DashboardSectionHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )
            content()
        }
    }
}
