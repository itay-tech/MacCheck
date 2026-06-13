import SwiftUI

struct ChartsView: View {
    @ObservedObject var viewModel: ChartsViewModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                    DashboardSectionHeader(
                        title: "Charts",
                        subtitle: "Visualize your Mac health trends over time.",
                        systemImage: "chart.xyaxis.line"
                    )

                    HealthScoreLineChart(viewModel: viewModel.charts.healthScore)
                        .equatable()

                    proChartsSection
                }
                .padding(MacCheckTheme.Spacing.xl)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("Charts")
            .toolbar { toolbarContent }
        }
        .proPaywallSheet(isPresented: $showPaywall)
        .onAppear {
            viewModel.refreshIfNeeded()
        }
    }

    // MARK: - Pro Charts

    private var proChartsSection: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                DashboardSectionHeader(
                    title: "Advanced Charts",
                    subtitle: "Deeper historical views across key subsystems",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                if !entitlementManager.isPro {
                    ProBadge(compact: true)
                }
            }

            FeatureGate(feature: .advancedCharts, showPaywall: $showPaywall) {
                LazyVStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                    BatteryHealthLineChart(viewModel: viewModel.charts.batteryHealth)
                        .equatable()
                    StorageUsageLineChart(viewModel: viewModel.charts.storageUsage)
                        .equatable()
                    SwapUsageLineChart(viewModel: viewModel.charts.swapUsage)
                        .equatable()
                    ThermalHistoryChart(viewModel: viewModel.charts.thermalHistory)
                        .equatable()
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ProUpgradeToolbarContent(showPaywall: $showPaywall)
    }
}

#Preview {
    let store = AppStore()
    return ChartsView(viewModel: store.chartsViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 900, height: 800)
}
