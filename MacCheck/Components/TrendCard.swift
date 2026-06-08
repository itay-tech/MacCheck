import SwiftUI

struct TrendCard: View {
    let item: TrendItem

    private let cardHeight: CGFloat = 176

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                Image(systemName: item.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(trendColor)
                    .frame(width: 20)

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Spacer(minLength: 0)

                Text(item.directionLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trendColor.opacity(0.12))
                    .foregroundStyle(trendColor)
                    .clipShape(Capsule())
            }

            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: MacCheckTheme.Spacing.md) {
                metricColumn(label: "Current", value: item.currentValue)
                metricColumn(label: "Previous", value: item.previousValue)
                metricColumn(label: "Change", value: item.changeValue, tint: trendColor)
            }
        }
        .padding(MacCheckTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - Private

    private var trendColor: Color {
        switch item.trend {
        case .positive: .green
        case .negative: .red
        case .neutral: .secondary
        }
    }

    private func metricColumn(label: String, value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TrendCard(
        item: TrendItem(
            id: "health-score-trend",
            title: "Health Score Trend",
            systemImage: "heart.text.square",
            currentValue: "92",
            previousValue: "88",
            changeValue: "+4",
            directionLabel: "Improved",
            summary: "Health score improved by 4 points",
            trend: .positive
        )
    )
    .padding()
    .frame(width: 340)
}
