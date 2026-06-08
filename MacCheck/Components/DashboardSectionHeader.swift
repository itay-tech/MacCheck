import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    var subtitle: String?
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, MacCheckTheme.Spacing.xs)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
        DashboardSectionHeader(
            title: "Health Overview",
            subtitle: "Live metrics from your Mac",
            systemImage: "square.grid.2x2"
        )
        DashboardSectionHeader(
            title: "Insights",
            subtitle: "What your system data means",
            systemImage: "lightbulb"
        )
    }
    .padding()
    .frame(width: 520)
}
