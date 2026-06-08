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

            HStack(spacing: MacCheckTheme.Spacing.sm) {
                infoPill(label: "Serial", value: systemInfo.serialNumberDisplay)
                if let chipName = systemInfo.chipName {
                    infoPill(label: "Chip", value: chipName)
                }
                infoPill(label: "macOS", value: systemInfo.macOSVersion)
            }
        }
        .macCheckCard(padding: MacCheckTheme.Spacing.md)
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
