import SwiftUI

struct ReportsLockedPage: View {
    var onUnlock: () -> Void

    private let benefits: [(icon: String, title: String, detail: String)] = [
        ("heart.text.square", "Health Report", "Professional PDF with system info, scores, insights, and recommendations."),
        ("magnifyingglass.circle", "Used Mac Inspection", "Certification PDF with A–D grading for buying or selling a Mac.")
    ]

    var body: some View {
        VStack(spacing: MacCheckTheme.Spacing.xxl) {
            hero

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
                ForEach(benefits, id: \.title) { benefit in
                    benefitRow(
                        icon: benefit.icon,
                        title: benefit.title,
                        detail: benefit.detail
                    )
                }
            }
            .padding(MacCheckTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)

            Button {
                onUnlock()
            } label: {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Image(systemName: "crown.fill")
                    Text("Unlock Pro Reports")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
    }

    private var hero: some View {
        VStack(spacing: MacCheckTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(MacCheckTheme.proGradient.opacity(0.18))
                    .frame(width: 88, height: 88)

                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(MacCheckTheme.proGradient)
            }

            VStack(spacing: MacCheckTheme.Spacing.xs) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Text("Pro Reports")
                        .font(.title2.weight(.bold))
                    ProBadge()
                }

                Text("Generate professional health reports and used Mac inspection certificates.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
