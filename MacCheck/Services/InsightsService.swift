import Foundation

/// Rule-based insights engine. Analyzes a completed health report without AI or predictions.
struct InsightsService {

    func generateInsights(from report: HealthReport) -> [HealthInsight] {
        var insights: [HealthInsight] = []

        insights.append(contentsOf: overallInsights(from: report))
        insights.append(contentsOf: batteryInsights(from: report))
        insights.append(contentsOf: storageInsights(from: report))
        insights.append(contentsOf: memoryInsights(from: report))
        insights.append(contentsOf: startupInsights(from: report))
        insights.append(contentsOf: thermalInsights(from: report))

        return insights.sorted { $0.severity < $1.severity }
    }

    // MARK: - Overall

    private func overallInsights(from report: HealthReport) -> [HealthInsight] {
        let score = report.overallScore

        if score >= 85 {
            return [makeInsight(
                title: "Mac Is in Great Shape",
                description: "Your overall health score is \(score)/100. All major systems look healthy.",
                severity: .info
            )]
        }

        if score >= 70 {
            return [makeInsight(
                title: "Overall Health Is Good",
                description: "Your overall health score is \(score)/100. A few areas could use attention.",
                severity: .info
            )]
        }

        if score >= 50 {
            return [makeInsight(
                title: "Overall Health Needs Attention",
                description: "Your overall health score is \(score)/100. Review the areas below to improve performance.",
                severity: .warning
            )]
        }

        return [makeInsight(
            title: "Overall Health Is Critical",
            description: "Your overall health score is \(score)/100. Multiple systems need immediate attention.",
            severity: .critical
        )]
    }

    // MARK: - Battery

    private func batteryInsights(from report: HealthReport) -> [HealthInsight] {
        let battery = report.battery

        guard battery.hasBattery else {
            return [makeInsight(
                title: "No Internal Battery",
                description: "This Mac does not include an internal battery. Battery health is not applicable.",
                severity: .info
            )]
        }

        var insights: [HealthInsight] = []

        if let health = battery.healthPercentage {
            if health >= 85 {
                insights.append(makeInsight(
                    title: "Battery Is Healthy",
                    description: "Battery health is at \(Int(health.rounded()))% with \(battery.cycleCount) charge cycles.",
                    severity: .info
                ))
            } else if health >= 70 {
                insights.append(makeInsight(
                    title: "Battery Health Is Below Average",
                    description: "Battery health is at \(Int(health.rounded()))%. Monitor capacity over the coming months.",
                    severity: .warning
                ))
            } else if health >= 60 {
                insights.append(makeInsight(
                    title: "Battery Health Is Declining",
                    description: "Battery health is at \(Int(health.rounded()))%. Consider planning a replacement.",
                    severity: .warning
                ))
            } else {
                insights.append(makeInsight(
                    title: "Battery Health Is Low",
                    description: "Battery health is at \(Int(health.rounded()))%. Replacement may be needed soon.",
                    severity: .critical
                ))
            }
        } else {
            insights.append(makeInsight(
                title: "Battery Health Unavailable",
                description: "This Mac reports charge level but not full health metrics. Cycle count: \(battery.cycleCount).",
                severity: .info
            ))
        }

        switch battery.cycleCount {
        case 1_000...:
            insights.append(makeInsight(
                title: "High Battery Cycle Count",
                description: "\(battery.cycleCount) charge cycles recorded. Battery wear is expected at this stage.",
                severity: .warning
            ))
        case 800..<1_000:
            insights.append(makeInsight(
                title: "Elevated Battery Cycle Count",
                description: "\(battery.cycleCount) charge cycles recorded. Keep an eye on battery health.",
                severity: .info
            ))
        default:
            break
        }

        if battery.condition == .replaceNow || battery.condition == .replaceSoon {
            insights.append(makeInsight(
                title: "Battery Replacement Recommended",
                description: "macOS reports the battery condition as \(battery.condition.displayName.lowercased()).",
                severity: .critical
            ))
        }

        return insights
    }

    // MARK: - Storage

    private func storageInsights(from report: HealthReport) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let storage = report.storage
        let freePercentage = Int((storage.freePercentage * 100).rounded())
        let storageScore = report.storageScore

        switch StorageStatus.from(freePercentage: storage.freePercentage) {
        case .healthy:
            insights.append(makeInsight(
                title: "Storage Is Healthy",
                description: "\(freePercentage)% of disk space is free. Storage score: \(storageScore)/100.",
                severity: .info
            ))
        case .warning:
            insights.append(makeInsight(
                title: "Storage Space Is Running Low",
                description: "Only \(freePercentage)% of disk space is free. Storage score: \(storageScore)/100.",
                severity: .warning
            ))
        case .critical:
            insights.append(makeInsight(
                title: "Storage Space Is Critically Low",
                description: "Only \(freePercentage)% of disk space is free. Free up space to avoid system issues.",
                severity: .critical
            ))
        }

        if storageScore < 50 {
            insights.append(makeInsight(
                title: "Storage Score Is Low",
                description: "Storage health score is \(storageScore)/100 based on available free space.",
                severity: .critical
            ))
        } else if storageScore < 70 {
            insights.append(makeInsight(
                title: "Storage Score Could Improve",
                description: "Storage health score is \(storageScore)/100. Consider clearing unused files.",
                severity: .warning
            ))
        }

        return insights
    }

    // MARK: - Memory

    private func memoryInsights(from report: HealthReport) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let memory = report.memory
        let memoryScore = report.memoryScore
        let swapLabel = ByteFormatter.swapString(from: memory.swapUsedBytes)

        switch memory.status {
        case .critical:
            insights.append(makeInsight(
                title: "Memory Pressure Is Affecting Performance",
                description: "Memory pressure is critical. Swap used: \(swapLabel). Memory score: \(memoryScore)/100.",
                severity: .critical
            ))
        case .warning:
            insights.append(makeInsight(
                title: "Memory Pressure Detected",
                description: "Your Mac is under memory pressure. Swap used: \(swapLabel). Memory score: \(memoryScore)/100.",
                severity: .warning
            ))
        case .healthy:
            if memory.swapUsedBytes > 0 {
                insights.append(makeInsight(
                    title: "Memory Is Under Control",
                    description: "Memory pressure is normal. Swap used: \(swapLabel). Memory score: \(memoryScore)/100.",
                    severity: .info
                ))
            } else {
                insights.append(makeInsight(
                    title: "Memory Is Healthy",
                    description: "No significant memory pressure detected. Memory score: \(memoryScore)/100.",
                    severity: .info
                ))
            }
        }

        let swapRatio = memory.totalMemoryBytes > 0
            ? Double(memory.swapUsedBytes) / Double(memory.totalMemoryBytes)
            : 0

        if swapRatio >= 0.50 {
            insights.append(makeInsight(
                title: "Swap Usage Is Very High",
                description: "Swap usage (\(swapLabel)) is over 50% of installed RAM, which can slow your Mac.",
                severity: .critical
            ))
        } else if swapRatio >= 0.25 {
            insights.append(makeInsight(
                title: "Swap Usage Is Elevated",
                description: "Swap usage (\(swapLabel)) is significant relative to installed RAM.",
                severity: .warning
            ))
        }

        if memoryScore < 50 {
            insights.append(makeInsight(
                title: "Memory Score Is Low",
                description: "Memory health score is \(memoryScore)/100 due to pressure and swap usage.",
                severity: .critical
            ))
        }

        return insights
    }

    // MARK: - Startup

    private func startupInsights(from report: HealthReport) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let enabledCount = report.startupApps.filter { $0.isEnabled != false }.count
        let startupScore = report.startupScore

        if report.isStartupDataLimited {
            insights.append(makeInsight(
                title: "Limited Startup Data",
                description: "Only partial startup item data is available due to system access limits.",
                severity: .info
            ))
        }

        switch enabledCount {
        case 0...3:
            insights.append(makeInsight(
                title: "Startup Load Is Light",
                description: "\(enabledCount) startup items enabled. Startup score: \(startupScore)/100.",
                severity: .info
            ))
        case 4...8:
            insights.append(makeInsight(
                title: "Moderate Startup Load",
                description: "\(enabledCount) startup items enabled. Startup score: \(startupScore)/100.",
                severity: .info
            ))
        case 9...12:
            insights.append(makeInsight(
                title: "Heavy Startup Load",
                description: "\(enabledCount) items launch at login, which can slow boot times. Startup score: \(startupScore)/100.",
                severity: .warning
            ))
        default:
            insights.append(makeInsight(
                title: "Very Heavy Startup Load",
                description: "\(enabledCount) items launch at login. Consider reducing login items. Startup score: \(startupScore)/100.",
                severity: .warning
            ))
        }

        if startupScore < 60 {
            insights.append(makeInsight(
                title: "Startup Score Is Low",
                description: "Startup health score is \(startupScore)/100 due to the number of login items.",
                severity: .warning
            ))
        }

        return insights
    }

    // MARK: - Thermal

    private func thermalInsights(from report: HealthReport) -> [HealthInsight] {
        let thermal = report.thermal
        let thermalScoreSuffix = report.thermalScore.map { " Thermal score: \($0)/100." } ?? ""

        switch thermal.status {
        case .nominal:
            return [makeInsight(
                title: "Thermal State Is Nominal",
                description: "Your Mac's thermal state is normal.\(thermalScoreSuffix)",
                severity: .info
            )]
        case .fair:
            return [makeInsight(
                title: "Thermal Load Is Elevated",
                description: thermal.explanation + thermalScoreSuffix,
                severity: .warning
            )]
        case .serious:
            return [makeInsight(
                title: "Thermal State Is Serious",
                description: thermal.explanation + thermalScoreSuffix,
                severity: .critical
            )]
        case .critical:
            return [makeInsight(
                title: "Thermal Pressure Is Affecting Performance",
                description: thermal.explanation + thermalScoreSuffix,
                severity: .critical
            )]
        case .unknown:
            return [makeInsight(
                title: "Thermal State Unavailable",
                description: thermal.explanation,
                severity: .info
            )]
        }
    }

    // MARK: - Helpers

    private func makeInsight(
        title: String,
        description: String,
        severity: InsightSeverity
    ) -> HealthInsight {
        HealthInsight(
            id: UUID(),
            title: title,
            description: description,
            severity: severity
        )
    }
}

private extension BatteryCondition {
    var displayName: String {
        switch self {
        case .normal: "Normal"
        case .replaceSoon: "Replace Soon"
        case .replaceNow: "Replace Now"
        case .serviceRecommended: "Service Recommended"
        case .unknown: "Unknown"
        case .notAvailable: "Not Available"
        }
    }
}
