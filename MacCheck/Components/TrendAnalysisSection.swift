import SwiftUI

struct TrendAnalysisSection: View {
    let trendItems: [TrendItem]
    let hasComparableHistory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            DashboardSectionHeader(
                title: "Trend Analysis",
                subtitle: "How key health metrics are moving over time",
                systemImage: "chart.line.uptrend.xyaxis"
            )

            if hasComparableHistory {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: MacCheckTheme.Spacing.lg),
                        GridItem(.flexible(), spacing: MacCheckTheme.Spacing.lg)
                    ],
                    spacing: MacCheckTheme.Spacing.lg
                ) {
                    ForEach(trendItems) { item in
                        TrendCard(item: item)
                    }
                }
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        Text("Trend analysis will become available after another scan is collected.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .macCheckHeroCard()
    }
}

#Preview("With trends") {
    TrendAnalysisSection(
        trendItems: [
            TrendItem(
                id: "health-score-trend",
                title: "Health Score Trend",
                systemImage: "heart.text.square",
                currentValue: "92",
                previousValue: "88",
                changeValue: "+4",
                directionLabel: "Improved",
                summary: "Health score improved by 4 points",
                trend: .positive
            ),
            TrendItem(
                id: "storage-trend",
                title: "Storage Trend",
                systemImage: "internaldrive",
                currentValue: "320 GB",
                previousValue: "308 GB",
                changeValue: "+12 GB",
                directionLabel: "Declined",
                summary: "Storage usage increased by 12 GB",
                trend: .negative
            )
        ],
        hasComparableHistory: true
    )
    .padding()
    .frame(width: 760)
}

#Preview("Empty") {
    TrendAnalysisSection(trendItems: [], hasComparableHistory: false)
        .padding()
        .frame(width: 760)
}
