import SwiftUI

struct LockedFeatureView: View {
    let feature: ProFeature
    var onUnlock: (() -> Void)?

    var body: some View {
        VStack(spacing: MacCheckTheme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(spacing: MacCheckTheme.Spacing.xs) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Text(feature.displayName)
                        .font(.headline)
                    ProBadge(compact: true)
                }

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Unlock MacCheck Pro") {
                onUnlock?()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(MacCheckTheme.Spacing.xl)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))
    }
}

#Preview {
    LockedFeatureView(feature: .predictions)
        .padding()
        .frame(width: 360)
}
