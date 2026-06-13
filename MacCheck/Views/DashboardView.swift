import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onViewHistory: (() -> Void)?
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Analyzing your Mac…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let report = viewModel.report {
                    dashboardContent(report)
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "desktopcomputer.trianglebadge.exclamationmark",
                        description: Text("Unable to load health data.")
                    )
                }
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("MacCheck")
            .toolbar { toolbarContent }
        }
        .proPaywallSheet(isPresented: $showPaywall)
        .task {
            viewModel.loadInitialReportIfNeeded()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func dashboardContent(_ report: HealthReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                HealthScoreCard(
                    breakdown: report.scoreBreakdown,
                    generatedAt: report.generatedAt
                )

                viewHistoryLink

                SystemInfoCard(systemInfo: report.systemInfo)

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "System Metrics",
                        subtitle: "Key performance indicators at a glance",
                        systemImage: "gauge.with.dots.needle.67percent"
                    )

                    kpiGrid(report)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Startup Applications",
                        subtitle: "Items configured to launch at login",
                        systemImage: "power.circle"
                    )

                    StartupAppsCard(
                        apps: report.startupApps,
                        isLimitedData: report.isStartupDataLimited
                    )
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Insights",
                        subtitle: "What your system data means",
                        systemImage: "lightbulb"
                    )

                    InsightsCard(insights: report.insights)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Recommendations",
                        subtitle: "Suggested next steps, prioritized by impact",
                        systemImage: "checklist"
                    )

                    RecommendationsCard(recommendations: viewModel.recommendations)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    FeatureGate(feature: .predictions, showPaywall: $showPaywall) {
                        predictionsSection(report)
                    }

                    FeatureGate(feature: .history, showPaywall: $showPaywall) {
                        historySection(report)
                    }
                }
            }
            .padding(MacCheckTheme.Spacing.xl)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var viewHistoryLink: some View {
        if let onViewHistory {
            HStack {
                Spacer()
                Button(action: onViewHistory) {
                    Label("View History", systemImage: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, MacCheckTheme.Spacing.xs)
        }
    }

    private func kpiGrid(_ report: HealthReport) -> some View {
        VStack(spacing: MacCheckTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.lg) {
                BatteryCard(battery: report.battery)
                    .frame(maxWidth: .infinity)
                StorageCard(storage: report.storage)
                    .frame(maxWidth: .infinity)
            }

            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.lg) {
                MemoryCard(memory: report.memory)
                    .frame(maxWidth: .infinity)
                ThermalCard(thermal: report.thermal, thermalScore: report.thermalScore)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func predictionsSection(_ report: HealthReport) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Predictions")
                    .font(.headline)
                ProBadge(compact: true)
            }

            HStack(spacing: MacCheckTheme.Spacing.lg) {
                predictionTile(
                    title: "Disk Full In",
                    value: report.storage.analysis.daysUntilFull.map { "\($0) days" } ?? "—",
                    icon: "internaldrive"
                )
                predictionTile(
                    title: "Battery Replace",
                    value: report.battery.replacementPredictionMonths.map { "~\($0) mo" } ?? "—",
                    icon: "battery.100"
                )
                predictionTile(
                    title: "Top Growth",
                    value: report.storage.analysis.topGrowingCategory.displayName,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .macCheckCard()
    }

    private func historySection(_ report: HealthReport) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)
                Text("Storage History")
                    .font(.headline)
                ProBadge(compact: true)
            }

            VStack(spacing: MacCheckTheme.Spacing.sm) {
                ForEach(report.storage.snapshots.sorted(by: { $0.date > $1.date })) { snapshot in
                    HStack {
                        Text(snapshot.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ByteFormatter.string(from: snapshot.usedBytes))
                            .font(.caption.weight(.medium))
                        Text("(\(Int(snapshot.usedPercentage * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .macCheckCard()
    }

    private func predictionTile(title: String, value: String, icon: String) -> some View {
        VStack(spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MacCheckTheme.Spacing.md)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ProUpgradeToolbarContent(showPaywall: $showPaywall)

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                viewModel.loadReport()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")
        }
    }
}

#Preview {
    let store = AppStore()
    return DashboardView(viewModel: store.dashboardViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 1000, height: 800)
}
