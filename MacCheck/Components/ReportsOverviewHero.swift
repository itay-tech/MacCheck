import SwiftUI

struct ReportsOverviewHero: View {
    let overview: ReportsOverviewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
                Image(systemName: "doc.richtext.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    Text("Professional Reports")
                        .font(.title2.weight(.bold))

                    Text("Generate polished PDF health reports and used Mac inspection certificates.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let score = overview.currentHealthScore {
                HStack(spacing: MacCheckTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                        Text("Current Health Score")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)

                        Text("\(score)")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(HealthScoreColor.color(for: score))

                        Text(HealthScoreColor.label(for: score))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MacCheckTheme.Spacing.lg)
                    .background(MacCheckTheme.tertiaryFill)
                    .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))

                    VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                        Text("Available Reports")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)

                        Text("2")
                            .font(.largeTitle.weight(.bold))

                        Text("Health Report & Inspection Certificate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MacCheckTheme.Spacing.lg)
                    .background(MacCheckTheme.tertiaryFill)
                    .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))
                }
            }
        }
        .macCheckHeroCard()
    }
}
