import SwiftUI

struct SystemInfoCard: View {
    let systemInfo: SystemInfo

    var body: some View {
        HStack(alignment: .center, spacing: MacCheckTheme.Spacing.lg) {
            Image(systemName: "desktopcomputer")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                Text(systemInfo.modelName)
                    .font(.headline)

                Text(systemInfo.modelIdentifier)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: MacCheckTheme.Spacing.md)

            ViewThatFits(in: .horizontal) {
                metricsRow
                metricsStack
            }
        }
        .macCheckCard(padding: MacCheckTheme.Spacing.md)
    }

    // MARK: - Metrics Layout

    private var metricsRow: some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            serialAndDisplayGroup
            if let chipName = systemInfo.chipName {
                infoPill(label: "Chip", value: chipName)
            }
            infoPill(label: "macOS", value: systemInfo.macOSVersion)
        }
    }

    private var metricsStack: some View {
        VStack(alignment: .trailing, spacing: MacCheckTheme.Spacing.sm) {
            serialAndDisplayGroup
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                if let chipName = systemInfo.chipName {
                    infoPill(label: "Chip", value: chipName)
                }
                infoPill(label: "macOS", value: systemInfo.macOSVersion)
            }
        }
    }

    private var serialAndDisplayGroup: some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            infoPill(label: "Serial", value: systemInfo.serialNumberDisplay)
            infoPill(label: "Display", value: systemInfo.displaySizeLabel)
        }
    }

    // MARK: - Private

    private func infoPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(minHeight: 36, alignment: .leading)
        .padding(.horizontal, MacCheckTheme.Spacing.sm)
        .padding(.vertical, MacCheckTheme.Spacing.xs)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }
}

#Preview {
    SystemInfoCard(systemInfo: SystemInfoService().fetchSystemInfo())
        .padding()
        .frame(width: 900)
}
