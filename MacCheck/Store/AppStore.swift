import SwiftUI

/// Shared dependency container injected at the app root.
@MainActor
final class AppStore {

    let entitlementManager: EntitlementManager
    let storeKitManager: StoreKitManager
    let batteryService: BatteryService
    let storageService: StorageService
    let memoryService: MemoryService
    let thermalService: ThermalService
    let startupAppsService: StartupAppsService
    let systemInfoService: SystemInfoService
    let healthScoreService: HealthScoreService
    let insightsService: InsightsService
    let recommendationsService: RecommendationsService
    let historyService: HistoryService
    let dashboardViewModel: DashboardViewModel
    let historyViewModel: HistoryViewModel
    let chartsViewModel: ChartsViewModel
    let predictionsViewModel: PredictionsViewModel
    let settingsViewModel: SettingsViewModel
    let reportsViewModel: ReportsViewModel

    init() {
        let entitlementManager = EntitlementManager()
        let storeKitManager = StoreKitManager(entitlementManager: entitlementManager)
        let batteryService = BatteryService()
        let storageService = StorageService()
        let memoryService = MemoryService()
        let thermalService = ThermalService()
        let startupAppsService = StartupAppsService()
        let systemInfoService = SystemInfoService()
        let healthScoreService = HealthScoreService()
        let insightsService = InsightsService()
        let recommendationsService = RecommendationsService()
        let historyService = HistoryService()

        self.entitlementManager = entitlementManager
        self.storeKitManager = storeKitManager
        print("[StoreKit] AppStore wired manager instance=\(ObjectIdentifier(storeKitManager))")
        self.batteryService = batteryService
        self.storageService = storageService
        self.memoryService = memoryService
        self.thermalService = thermalService
        self.startupAppsService = startupAppsService
        self.systemInfoService = systemInfoService
        self.healthScoreService = healthScoreService
        self.insightsService = insightsService
        self.recommendationsService = recommendationsService
        self.historyService = historyService
        self.historyViewModel = HistoryViewModel(historyService: historyService)
        self.chartsViewModel = ChartsViewModel(historyService: historyService)
        self.predictionsViewModel = PredictionsViewModel(historyService: historyService)
        self.settingsViewModel = SettingsViewModel(
            historyService: historyService,
            historyViewModel: historyViewModel,
            chartsViewModel: chartsViewModel,
            predictionsViewModel: predictionsViewModel
        )
        self.dashboardViewModel = DashboardViewModel(
            batteryService: batteryService,
            storageService: storageService,
            memoryService: memoryService,
            thermalService: thermalService,
            startupAppsService: startupAppsService,
            systemInfoService: systemInfoService,
            healthScoreService: healthScoreService,
            insightsService: insightsService,
            recommendationsService: recommendationsService,
            historyService: historyService
        )
        self.reportsViewModel = ReportsViewModel(dashboardViewModel: dashboardViewModel)
    }
}
