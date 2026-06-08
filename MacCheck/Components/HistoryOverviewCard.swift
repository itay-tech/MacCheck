import SwiftUI

struct HistoryOverviewCard: View {
    let currentScore: Int?
    let previousScore: Int?
    let scoreChange: Int?
    let lastScanDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            if let currentScore {
                HStack(spacing: MacCheckTheme.Spacing.lg) {
                    overviewMetric(
                        title: "Current Score",
                        value: "\(currentScore)",
                        tint: HealthScoreColor.color(for: currentScore)
                    )

                    overviewMetric(
                        title: "Previous Score",
                        value: previousScore.map(String.init) ?? "—",
                        tint: previousScore.map { HealthScoreColor.color(for: $0) } ?? .secondary
                    )

                    overviewMetric(
                        title: "Score Change",
                        value: scoreChange.map(formattedChange) ?? "—",
                        tint: scoreChange.map(changeColor) ?? .secondary
                    )
                }
            }

            if let lastScanDate {
                HStack {
                    Text("Last Scan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(lastScanDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .macCheckPanel()
    }

    // MARK: - Private

    private func overviewMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MacCheckTheme.Spacing.md)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }

    private func formattedChange(_ change: Int) -> String {
        if change > 0 { return "+\(change)" }
        if change < 0 { return "\(change)" }
        return "0"
    }

    private func changeColor(_ change: Int) -> Color {
        if change > 0 { return .green }
        if change < 0 { return .red }
        return .secondary
    }
}

#Preview {
    HistoryOverviewCard(
        currentScore: 92,
        previousScore: 88,
        scoreChange: 4,
        lastScanDate: Date()
    )
    .padding()
    .frame(width: 720)
}
