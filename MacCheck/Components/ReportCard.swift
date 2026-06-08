import SwiftUI

/// Display-only report card. Export buttons live in `ReportsView` so clicks are never clipped or blocked.
struct ReportCard: View {
    let model: ReportCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            header

            if let summary = model.summary {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.isReady {
                metricsGrid
            } else if let message = model.unavailableMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MacCheckTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background { cardBackground }
        .overlay { cardBorder }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
            .fill(MacCheckTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
                    .fill(MacCheckTheme.heroTint)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 14, x: 0, y: 6)
            .allowsHitTesting(false)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
            .strokeBorder(Color.accentColor.opacity(0.14), lineWidth: 1)
            .allowsHitTesting(false)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
            Image(systemName: model.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .padding(10)
                .background(Color.accentColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                Text(model.title)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)

                Text(model.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ],
            alignment: .leading,
            spacing: MacCheckTheme.Spacing.md
        ) {
            ForEach(model.metrics) { metric in
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    Text(metric.value)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MacCheckTheme.Spacing.md)
                .background(MacCheckTheme.tertiaryFill)
                .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
            }
        }
    }
}
