import SwiftUI

struct DashboardSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var help: DashboardHelpText? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        help: DashboardHelpText? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.help = help
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: MacCheckTheme.Spacing.xs) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    if let help {
                        DashboardHelpIcon(help: help)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            trailing()
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
            title: "Startup & Background Items",
            subtitle: "Enabled items that may affect login and background performance.",
            systemImage: "power.circle",
            trailing: {
                Text("Score: 84/100")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        )
    }
    .padding()
    .frame(width: 520)
}
