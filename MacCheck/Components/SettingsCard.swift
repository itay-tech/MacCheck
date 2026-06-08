import SwiftUI

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(MacCheckTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: MacCheckTheme.Spacing.md)
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
