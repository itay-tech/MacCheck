import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    private var hasFullHistoryAccess: Bool {
        entitlementManager.hasAccess(to: .history)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasAnySnapshots {
                    historyContent
                } else {
                    fullEmptyState
                }
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("History")
            .toolbar {
                ProUpgradeToolbarContent(showPaywall: $showPaywall)
            }
            .task {
                viewModel.refresh()
            }
        }
        .proPaywallSheet(isPresented: $showPaywall, source: .history)
    }

    // MARK: - Content

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                if let historyError = viewModel.historyError {
                    historyWarningBanner(historyError)
                }

                DashboardSectionHeader(
                    title: "History",
                    subtitle: "Track how your Mac health changes over time.",
                    systemImage: "clock.arrow.circlepath"
                )

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Score Overview",
                        subtitle: "Latest health score compared to your previous scan",
                        systemImage: "heart.text.square"
                    )

                    HistoryOverviewCard(
                        currentScore: viewModel.currentScore,
                        previousScore: viewModel.previousScore,
                        scoreChange: viewModel.scoreChange,
                        lastScanDate: viewModel.lastScanDate
                    )
                }

                TrendAnalysisSection(
                    trendItems: viewModel.trendItems,
                    hasComparableHistory: viewModel.hasComparableHistory
                )

                HistoryStatisticsSection(
                    statistics: viewModel.statistics,
                    hasFullAccess: hasFullHistoryAccess,
                    onUnlock: { showPaywall = true }
                )

                if !viewModel.recentSnapshots.isEmpty {
                    snapshotListSection
                }
            }
            .padding(MacCheckTheme.Spacing.xl)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
    }

    private var snapshotListSection: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            DashboardSectionHeader(
                title: "Recent Snapshots",
                subtitle: hasFullHistoryAccess
                    ? "Up to 100 most recent daily health records"
                    : "Latest 2 daily health records",
                systemImage: "list.bullet.rectangle"
            )

            RecentSnapshotsCard(
                snapshots: displayedSnapshots,
                showsUpgradePrompt: !hasFullHistoryAccess,
                onUnlock: { showPaywall = true }
            )
        }
    }

    private var displayedSnapshots: [HealthSnapshot] {
        let limit = hasFullHistoryAccess
            ? viewModel.recentSnapshots.count
            : HistoryViewModel.freeSnapshotLimit
        return Array(viewModel.recentSnapshots.prefix(limit))
    }

    private func historyWarningBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MacCheckTheme.Spacing.md)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))
    }

    private var fullEmptyState: some View {
        VStack(spacing: MacCheckTheme.Spacing.lg) {
            if let historyError = viewModel.historyError {
                historyWarningBanner(historyError)
                    .frame(maxWidth: 420)
            }

            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: MacCheckTheme.Spacing.sm) {
                Text("History will appear after your next scan.")
                    .font(.title3.weight(.semibold))
                Text("MacCheck keeps one snapshot per day and compares your Mac health over time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MacCheckTheme.Spacing.xl)
    }
}

#Preview("With history") {
    let store = AppStore()
    return HistoryView(viewModel: store.historyViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 900, height: 700)
}

#Preview("Empty") {
    HistoryView(viewModel: HistoryViewModel(historyService: HistoryService()))
        .frame(width: 900, height: 700)
}
