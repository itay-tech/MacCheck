import SwiftUI

struct HistorySummaryCard: View {
    let currentScore: Int
    let previousScore: Int?
    let scoreChange: Int?
    let lastScanDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            if let previousScore, let scoreChange {
                comparisonContent(previousScore: previousScore, scoreChange: scoreChange)
            } else {
                Text("History will appear after your next scan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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
        .macCheckPanel()
    }

    // MARK: - Private

    private func comparisonContent(previousScore: Int, scoreChange: Int) -> some View {
        HStack(spacing: MacCheckTheme.Spacing.lg) {
            historyMetric(
                title: "Current Score",
                value: "\(currentScore)",
                tint: HealthScoreColor.color(for: currentScore)
            )

            historyMetric(
                title: "Previous Score",
                value: "\(previousScore)",
                tint: HealthScoreColor.color(for: previousScore)
            )

            historyMetric(
                title: "Score Change",
                value: formattedChange(scoreChange),
                tint: changeColor(scoreChange)
            )
        }
    }

    private func historyMetric(title: String, value: String, tint: Color) -> some View {
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
    VStack(spacing: MacCheckTheme.Spacing.lg) {
        HistorySummaryCard(
            currentScore: 92,
            previousScore: 88,
            scoreChange: 4,
            lastScanDate: Date()
        )

        HistorySummaryCard(
            currentScore: 92,
            previousScore: nil,
            scoreChange: nil,
            lastScanDate: Date()
        )
    }
    .padding()
    .frame(width: 720)
}
