import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onViewHistory: (() -> Void)?
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @StateObject private var tooltipState = DashboardTooltipState()
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
        .proPaywallSheet(isPresented: $showPaywall, source: .unknown)
        .task {
            viewModel.loadInitialReportIfNeeded()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func dashboardContent(_ report: HealthReport) -> some View {
        ZStack(alignment: .topLeading) {
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
                        title: "Startup & Background Items",
                        subtitle: "Enabled items that may affect login and background performance.",
                        systemImage: "power.circle",
                        help: .startupItems,
                        trailing: {
                            startupScoreLabel(report.startupScore)
                        }
                    )

                    StartupAppsCard(
                        apps: report.startupApps.visibleForScoring,
                        isLimitedData: report.isStartupDataLimited
                    )
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Insights",
                        subtitle: "What your system data means",
                        systemImage: "lightbulb",
                        help: .insights
                    )

                    InsightsCard(insights: report.insights)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    DashboardSectionHeader(
                        title: "Recommendations",
                        subtitle: "Suggested next steps, prioritized by impact",
                        systemImage: "checklist",
                        help: .recommendations
                    )

                    RecommendationsCard(recommendations: report.recommendations)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    FeatureGate(feature: .predictions, showPaywall: $showPaywall) {
                        predictionsSection(report)
                    }
                }
            }
                .id(report.generatedAt)
                .padding(MacCheckTheme.Spacing.xl)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }

            DashboardTooltipHost()
        }
        .coordinateSpace(name: DashboardCoordinateSpace.root)
        .environmentObject(tooltipState)
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
                BatteryCard(
                    battery: report.battery,
                    batteryScore: report.batteryScore
                )
                .frame(maxWidth: .infinity)
                StorageCard(
                    storage: report.storage,
                    storageScore: report.storageScore
                )
                .frame(maxWidth: .infinity)
            }

            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.lg) {
                MemoryCard(
                    memory: report.memory,
                    memoryScore: report.memoryScore
                )
                .frame(maxWidth: .infinity)
                ThermalCard(thermal: report.thermal, thermalScore: report.thermalScore)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func startupScoreLabel(_ score: Int) -> some View {
        Text("Score: \(score)/100")
            .font(.caption.weight(.semibold))
            .foregroundStyle(HealthScoreColor.color(for: score))
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
                PostHogService.shared.track(.dashboardRefresh)
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
