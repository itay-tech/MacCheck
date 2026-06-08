import SwiftUI

struct HistoryStatisticsSection: View {
    let statistics: HistoryStatistics?
    let hasFullAccess: Bool
    var onUnlock: () -> Void

    private let gridColumns = [
        GridItem(.adaptive(minimum: 200, maximum: 240), spacing: MacCheckTheme.Spacing.lg)
    ]

    private let lockedBenefits: [(icon: String, title: String)] = [
        ("arrow.up.circle", "Best Score Ever"),
        ("arrow.down.circle", "Lowest Score Ever"),
        ("thermometer.medium", "Highest Thermal State"),
        ("memorychip", "Highest Swap Usage"),
        ("chart.line.uptrend.xyaxis", "Long-term historical insights")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            DashboardSectionHeader(
                title: "History Statistics",
                subtitle: "Long-term insights from your saved health snapshots",
                systemImage: "chart.bar.doc.horizontal"
            )

            if hasFullAccess {
                proContent
            } else {
                lockedCard
            }
        }
    }

    // MARK: - Pro

    @ViewBuilder
    private var proContent: some View {
        if let statistics {
            LazyVGrid(columns: gridColumns, spacing: MacCheckTheme.Spacing.lg) {
                ForEach(statistics.items) { item in
                    StatisticCard(item: item)
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        Text("Statistics will become available as more history is collected.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .macCheckHeroCard()
    }

    // MARK: - Locked

    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    HStack(spacing: MacCheckTheme.Spacing.sm) {
                        Text("History Statistics")
                            .font(.headline)
                        ProBadge(compact: true)
                    }

                    Text("Unlock long-term records and milestones from your Mac health history.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                Text("Available with Pro:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(lockedBenefits, id: \.title) { benefit in
                    HStack(spacing: MacCheckTheme.Spacing.sm) {
                        Image(systemName: benefit.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 18)

                        Text(benefit.title)
                            .font(.subheadline)
                    }
                }
            }

            Button {
                onUnlock()
            } label: {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Image(systemName: "crown.fill")
                    Text("Unlock MacCheck Pro")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .macCheckHeroCard()
    }
}

#Preview("Pro — With statistics") {
    HistoryStatisticsSection(
        statistics: HistoryStatistics(items: [
            StatisticItem(
                id: "best-score",
                title: "Best Score Ever",
                value: "94",
                subtitle: nil,
                occurrenceDate: Date(),
                systemImage: "arrow.up.circle"
            ),
            StatisticItem(
                id: "average-score",
                title: "Average Score",
                value: "88",
                subtitle: "Across 7 snapshots",
                occurrenceDate: nil,
                systemImage: "sum"
            )
        ]),
        hasFullAccess: true,
        onUnlock: {}
    )
    .padding()
    .frame(width: 980)
}

#Preview("Pro — Empty") {
    HistoryStatisticsSection(statistics: nil, hasFullAccess: true, onUnlock: {})
        .padding()
        .frame(width: 760)
}

#Preview("Free — Locked") {
    HistoryStatisticsSection(statistics: nil, hasFullAccess: false, onUnlock: {})
        .padding()
        .frame(width: 760)
}
