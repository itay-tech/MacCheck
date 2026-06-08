import SwiftUI

struct RootView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @ObservedObject var historyViewModel: HistoryViewModel
    @ObservedObject var chartsViewModel: ChartsViewModel
    @ObservedObject var predictionsViewModel: PredictionsViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var reportsViewModel: ReportsViewModel
    @State private var selection: AppSection = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
                .id(selection)
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
        reportsViewModel: store.reportsViewModel
    )
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 1100, height: 800)
}
