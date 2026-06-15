import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published private(set) var report: HealthReport?
    @Published private(set) var isLoading = false
    @Published private(set) var historyError: String?
    @Published private(set) var lastRefreshCompletedAt: Date?

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
        guard !isLoading else {
            print("[Dashboard] Refresh skipped — load already in progress")
            return
        }

        isLoading = true
        let refreshStartedAt = Date()
        print("[Dashboard] Refresh started at \(refreshStartedAt.formatted(date: .abbreviated, time: .standard))")

        defer { isLoading = false }

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

        let generatedAt = Date()

        let metricsReport = HealthReport(
            generatedAt: generatedAt,
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

        let insights = insightsService.generateInsights(from: metricsReport)
        let reportWithInsights = HealthReport(
            generatedAt: generatedAt,
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

        let finalReport = HealthReport(
            generatedAt: generatedAt,
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
        lastRefreshCompletedAt = Date()
        printRefreshDiagnostics(report: finalReport, refreshCompletedAt: lastRefreshCompletedAt!)

        do {
            try historyService.recordSnapshot(from: finalReport)
            historyError = nil
        } catch {
            historyError = historyService.lastSaveErrorMessage
        }
    }

    private func printRefreshDiagnostics(report: HealthReport, refreshCompletedAt: Date) {
        print("[Dashboard] report generatedAt: \(report.generatedAt.formatted(date: .abbreviated, time: .standard))")
        print("[Dashboard] health score: \(report.healthScore)")
        print("[Dashboard] insights count: \(report.insights.count)")
        print("[Dashboard] first insight title: \(report.insights.first?.title ?? "none")")
        print("[Dashboard] refresh timestamp: \(refreshCompletedAt.formatted(date: .abbreviated, time: .standard))")
    }
}
