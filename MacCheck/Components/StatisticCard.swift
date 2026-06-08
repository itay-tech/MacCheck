import SwiftUI

struct StatisticCard: View {
    let item: StatisticItem

    private let cardHeight: CGFloat = 132

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                Image(systemName: item.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 20, height: 20)
                    .padding(6)
                    .background(statusColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))

                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let occurrenceDate = item.occurrenceDate {
                    Text(occurrenceDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let subtitle = item.subtitle {
                Spacer(minLength: 0)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Spacer(minLength: 0)
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

    private var statusColor: Color {
        semanticStatus.color
    }

    private var semanticStatus: StatisticStatus {
        switch item.id {
        case "best-score", "average-score", "lowest-score":
            return .healthScore(scoreValue)

        case "battery-change":
            return .delta(signedDeltaValue)

        case "storage-growth":
            return storageGrowthStatus

        case "highest-swap":
            return swapUsageStatus

        case "highest-thermal-state":
            return thermalStatusStyle

        case "days-tracked":
            return .informational

        default:
            return .informational
        }
    }

    private var scoreValue: Int {
        Int(item.value) ?? 0
    }

    private var signedDeltaValue: Double {
        let normalized = item.value
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "GB", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(normalized) ?? 0
    }

    private var storageGrowthStatus: StatisticStatus {
        let delta = signedDeltaValue
        if delta <= 0 { return .positive }
        if delta <= 10 { return .warning }
        return .negative
    }

    private var swapUsageStatus: StatisticStatus {
        // Mirrors memory severity language from MemoryStatus.resolve:
        // warning around moderate swap pressure, critical for heavy swap.
        let highestSwapGB = abs(signedDeltaValue)
        if highestSwapGB >= 6.5 { return .negative }
        if highestSwapGB >= 3.2 { return .warning }
        return .positive
    }

    private var thermalStatusStyle: StatisticStatus {
        switch item.value.lowercased() {
        case "nominal":
            return .positive
        case "fair":
            return .warning
        case "serious", "critical":
            return .negative
        default:
            return .informational
        }
    }
}

private enum StatisticStatus {
    case positive
    case warning
    case negative
    case informational
    case healthScore(Int)
    case delta(Double)

    var color: Color {
        switch self {
        case .positive:
            return .green
        case .warning:
            return .orange
        case .negative:
            return .red
        case .informational:
            return .blue
        case .healthScore(let score):
            return HealthScoreColor.color(for: score)
        case .delta(let value):
            if value > 0 { return .green }
            if value < 0 { return .red }
            return .orange
        }
    }
}

#Preview {
    StatisticCard(
        item: StatisticItem(
            id: "best-score",
            title: "Best Score Ever",
            value: "94",
            subtitle: nil,
            occurrenceDate: Date(),
            systemImage: "arrow.up.circle"
        )
    )
    .padding()
    .frame(width: 220)
}
