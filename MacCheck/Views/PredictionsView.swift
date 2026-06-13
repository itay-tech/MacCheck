import SwiftUI

struct PredictionsView: View {
    @ObservedObject var viewModel: PredictionsViewModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if entitlementManager.hasAccess(to: .predictions) {
                    proContent
                } else {
                    lockedContent
                }
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("Predictions")
            .toolbar { toolbarContent }
        }
        .proPaywallSheet(isPresented: $showPaywall)
        .onAppear {
            if entitlementManager.hasAccess(to: .predictions) {
                viewModel.refreshIfNeeded()
            }
        }
    }

    // MARK: - Locked

    private var lockedContent: some View {
        ScrollView {
            PredictionsLockedPage {
                showPaywall = true
            }
            .padding(.vertical, MacCheckTheme.Spacing.xl)
        }
    }

    // MARK: - Pro Content

    private var proContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                DashboardSectionHeader(
                    title: "Predictions",
                    subtitle: "Intelligent forecasts from your local health history.",
                    systemImage: "sparkles"
                )

                if viewModel.predictions.hasEnoughHistory {
                    predictionsContent
                } else {
                    insufficientHistoryState
                }
            }
            .padding(MacCheckTheme.Spacing.xl)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
    }

    private var predictionsContent: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
            if let summary = viewModel.summary {
                PredictionSummaryHero(model: summary)
            }

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                DashboardSectionHeader(
                    title: "Forecasts",
                    subtitle: "Individual outlooks across key subsystems",
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                forecastGrid
            }
        }
    }

    private var forecastGrid: some View {
        VStack(spacing: MacCheckTheme.Spacing.lg) {
            PredictionCard(
                model: viewModel.predictions.storageForecast,
                isEmphasized: true
            )
            PredictionCard(model: viewModel.predictions.batteryForecast)
            PredictionCard(model: viewModel.predictions.healthScoreForecast)
            PredictionCard(model: viewModel.predictions.memoryRiskForecast)
            PredictionCard(model: viewModel.predictions.thermalRiskForecast)
        }
    }

    private var insufficientHistoryState: some View {
        VStack(spacing: MacCheckTheme.Spacing.md) {
            Image(systemName: "clock.badge.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(PredictionsPageData.insufficientHistoryMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("\(viewModel.predictions.snapshotCount) of \(PredictionEngine.minimumSnapshots) snapshots collected")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(MacCheckTheme.Spacing.xxl)
        .macCheckHeroCard()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ProUpgradeToolbarContent(showPaywall: $showPaywall)
    }
}

#Preview("Pro") {
    let store = AppStore()
    return PredictionsView(viewModel: store.predictionsViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 900, height: 800)
}
