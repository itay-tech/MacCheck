import Foundation

struct HealthReport: Equatable {
    let generatedAt: Date
    let scoreBreakdown: HealthScoreBreakdown
    let systemInfo: SystemInfo
    let battery: BatteryInfo
    let storage: StorageInfo
    let memory: MemoryInfo
    let thermal: ThermalInfo
    let startupApps: [StartupAppInfo]
    let isStartupDataLimited: Bool
    let insights: [HealthInsight]
    let recommendations: [Recommendation]

    var overallScore: Int { scoreBreakdown.overallScore }
    var batteryScore: Int? { scoreBreakdown.batteryScore }
    var storageScore: Int { scoreBreakdown.storageScore }
    var memoryScore: Int { scoreBreakdown.memoryScore }
    var startupScore: Int { scoreBreakdown.startupScore }
    var thermalScore: Int? { scoreBreakdown.thermalScore }
    var healthScore: Int { overallScore }
}
