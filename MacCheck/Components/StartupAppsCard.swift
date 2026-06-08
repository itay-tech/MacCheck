import SwiftUI

struct StartupAppsCard: View {
    let apps: [StartupAppInfo]
    var isLimitedData: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            tableHeader

            if apps.isEmpty {
                Text(isLimitedData ? "Limited startup data available" : "No startup items found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, MacCheckTheme.Spacing.sm)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        if index > 0 {
                            Divider()
                                .padding(.leading, 44)
                        }
                        tableRow(app)
                    }
                }
            }

            if isLimitedData && !apps.isEmpty {
                Text("Limited startup data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .macCheckPanel()
    }

    // MARK: - Private

    private var tableHeader: some View {
        HStack(spacing: MacCheckTheme.Spacing.md) {
            Text("Application")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Bundle ID")
                .frame(width: 220, alignment: .leading)
            Text("Status")
                .frame(width: 88, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .padding(.bottom, MacCheckTheme.Spacing.xs)
    }

    private func tableRow(_ app: StartupAppInfo) -> some View {
        HStack(spacing: MacCheckTheme.Spacing.md) {
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                Circle()
                    .fill(statusColor(app.isEnabled).opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text(String(app.name.prefix(1)))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(statusColor(app.isEnabled))
                    }

                Text(app.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(app.bundleIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)

            Text(app.statusDisplayName)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(app.isEnabled).opacity(0.12))
                .foregroundStyle(statusColor(app.isEnabled))
                .clipShape(Capsule())
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.vertical, MacCheckTheme.Spacing.sm)
    }

    private func statusColor(_ isEnabled: Bool?) -> Color {
        switch isEnabled {
        case true: .green
        case false: .secondary
        case nil: .orange
        }
    }
}

#Preview {
    StartupAppsCard(
        apps: StartupAppsService().fetchStartupApps().apps,
        isLimitedData: StartupAppsService().fetchStartupApps().isLimitedData
    )
    .padding()
    .frame(width: 720)
}
