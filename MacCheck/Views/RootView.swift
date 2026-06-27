import StoreKit
import SwiftUI

struct RootView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @ObservedObject var historyViewModel: HistoryViewModel
    @ObservedObject var chartsViewModel: ChartsViewModel
    @ObservedObject var predictionsViewModel: PredictionsViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var reportsViewModel: ReportsViewModel
    @ObservedObject var analyticsConsentManager: AnalyticsConsentManager
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.requestReview) private var requestReview
    @State private var selection: AppSection = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
                .id(selection)
        }
        .analyticsConsent(
            consentManager: analyticsConsentManager,
            isPro: entitlementManager.isPro
        )
        .onChange(of: selection) { _, newSelection in
            PostHogService.shared.track(.tabOpened(tabName: newSelection.rawValue))

            if AppStoreReviewManager.shared.recordNavigation() {
                requestReview()
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(AppSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
        }
        .navigationTitle("MacCheck")
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView(
                viewModel: dashboardViewModel,
                onViewHistory: { selection = .history }
            )
        case .history:
            HistoryView(viewModel: historyViewModel)
        case .charts:
            ChartsView(viewModel: chartsViewModel)
        case .predictions:
            PredictionsView(viewModel: predictionsViewModel)
        case .reports:
            ReportsView(viewModel: reportsViewModel)
        case .settings:
            SettingsView(viewModel: settingsViewModel)
        }
    }
}

#Preview {
    let store = AppStore()
    return RootView(
        dashboardViewModel: store.dashboardViewModel,
        historyViewModel: store.historyViewModel,
        chartsViewModel: store.chartsViewModel,
        predictionsViewModel: store.predictionsViewModel,
        settingsViewModel: store.settingsViewModel,
        reportsViewModel: store.reportsViewModel,
        analyticsConsentManager: store.analyticsConsentManager
    )
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .environmentObject(store.analyticsConsentManager)
        .frame(width: 1100, height: 800)
}
