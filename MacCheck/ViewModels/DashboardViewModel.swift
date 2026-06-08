import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published private(set) var report: HealthReport?
    @Published private(set) var recommendations: [Recommendation] = []
    @Published private(set) var isLoading = false
    @Published private(set) var historyError: String?

    private let batteryService: BatteryService
    private let storageService: StorageService
    private let memoryService: MemoryService
    private let thermalService: ThermalService
    private let startupAppsService: StartupAppsService
    private let systemInfoService: SystemInfoService
    private let healthScoreService: HealthScoreService
    private let insightsService: InsightsService
    private let recommendationsService: RecommendationsService
    private let historyService: HistoryService

    init(
        batteryService: BatteryService,
        storageService: StorageService,
        memoryService: MemoryService,
        thermalService: ThermalService,
        startupAppsService: StartupAppsService,
        systemInfoService: SystemInfoService,
        healthScoreService: HealthScoreService,
        insightsService: InsightsService,
        recommendationsService: RecommendationsService,
        historyService: HistoryService
    ) {
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
    }

    /// Loads the initial report once; skips if a load is already in progress or complete.
    func loadInitialReportIfNeeded() {
        guard report == nil, !isLoading else { return }
        loadReport()
    }

    func loadReport() {
        isLoading = true
        recommendations = []

        let battery = batteryService.fetchBatteryInfo()
        let storage = storageService.fetchStorageInfo()
        let memory = memoryService.fetchMemoryInfo()
        let thermal = thermalService.fetchThermalInfo()
        let startupResult = startupAppsService.fetchStartupApps()
        let systemInfo = systemInfoService.fetchSystemInfo()

        let scoreBreakdown = healthScoreService.calculateScore(
            battery: battery,
            storage: storage,
            memory: memory,
            startupApps: startupResult.apps,
            thermal: thermal
        )

        let reportDraft = HealthReport(
            generatedAt: Date(),
            scoreBreakdown: scoreBreakdown,
            systemInfo: systemInfo,
            battery: battery,
            storage: storage,
            memory: memory,
            thermal: thermal,
            startupApps: startupResult.apps,
            isStartupDataLimited: startupResult.isLimitedData,
            insights: [],
            recommendations: []
        )

        let insights = insightsService.generateInsights(from: reportDraft)

        let reportWithInsights = HealthReport(
            generatedAt: reportDraft.generatedAt,
            scoreBreakdown: scoreBreakdown,
            systemInfo: systemInfo,
            battery: battery,
            storage: storage,
            memory: memory,
            thermal: thermal,
            startupApps: startupResult.apps,
            isStartupDataLimited: startupResult.isLimitedData,
            insights: insights,
            recommendations: []
        )

        let recommendations = recommendationsService.generateRecommendations(from: reportWithInsights)

        self.recommendations = recommendations

        let finalReport = HealthReport(
            generatedAt: reportDraft.generatedAt,
            scoreBreakdown: scoreBreakdown,
            systemInfo: systemInfo,
            battery: battery,
            storage: storage,
            memory: memory,
            thermal: thermal,
            startupApps: startupResult.apps,
            isStartupDataLimited: startupResult.isLimitedData,
            insights: insights,
            recommendations: recommendations
        )

        report = finalReport

        do {
            try historyService.recordSnapshot(from: finalReport)
            historyError = nil
        } catch {
            historyError = historyService.lastSaveErrorMessage
        }

        isLoading = false
    }
}
