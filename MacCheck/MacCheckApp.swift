import SwiftUI

@main
struct MacCheckApp: App {
    @State private var appStore = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView(
                dashboardViewModel: appStore.dashboardViewModel,
                historyViewModel: appStore.historyViewModel,
                chartsViewModel: appStore.chartsViewModel,
                predictionsViewModel: appStore.predictionsViewModel,
                settingsViewModel: appStore.settingsViewModel,
                reportsViewModel: appStore.reportsViewModel,
                analyticsConsentManager: appStore.analyticsConsentManager
            )
                .environmentObject(appStore.entitlementManager)
                .environmentObject(appStore.storeKitManager)
                .environmentObject(appStore.analyticsConsentManager)
        }
        .defaultSize(width: 1100, height: 800)
    }
}
