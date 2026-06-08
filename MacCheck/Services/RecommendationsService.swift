import Foundation

/// Rule-based recommendations engine. Uses health report data and generated insights.
struct RecommendationsService {

    func generateRecommendations(from report: HealthReport) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        recommendations.append(contentsOf: batteryRecommendations(from: report))
        recommendations.append(contentsOf: storageRecommendations(from: report))
        recommendations.append(contentsOf: memoryRecommendations(from: report))
        recommendations.append(contentsOf: startupRecommendations(from: report))
        recommendations.append(contentsOf: thermalRecommendations(from: report))
        recommendations.append(contentsOf: generalRecommendations(from: report))

        return recommendations.sorted { $0.priority < $1.priority }
    }

    // MARK: - Battery

    private func batteryRecommendations(from report: HealthReport) -> [Recommendation] {
        guard report.battery.hasBattery else { return [] }

        var items: [Recommendation] = []
        let battery = report.battery

        if battery.condition == .replaceNow || battery.condition == .replaceSoon {
            items.append(makeRecommendation(
                title: "Plan Battery Replacement",
                description: "macOS reports your battery condition as \(battery.condition.displayName.lowercased()). Schedule a replacement to restore portable use and performance.",
                priority: .high,
                category: .battery
            ))
        } else if let health = battery.healthPercentage {
            if health < 60 {
                items.append(makeRecommendation(
                    title: "Plan Battery Replacement",
                    description: "Battery health is at \(Int(health.rounded()))%. A replacement will help avoid unexpected shutdowns and reduced runtime.",
                    priority: .high,
                    category: .battery
                ))
            } else if health < 80 {
                items.append(makeRecommendation(
                    title: "Monitor Battery Wear",
                    description: "Battery health is at \(Int(health.rounded()))%. Check capacity periodically in System Settings → Battery.",
                    priority: .medium,
                    category: .battery
                ))
            }
        }

        if battery.cycleCount >= 800, battery.healthPercentage != nil {
            items.append(makeRecommendation(
                title: "Track Battery Cycle Count",
                description: "Your battery has \(battery.cycleCount) charge cycles. Monitor health over the next few months.",
                priority: .low,
                category: .battery
            ))
        }

        if hasInsight(matching: "battery", severity: .critical, in: report.insights), items.isEmpty {
            items.append(makeRecommendation(
                title: "Address Battery Health",
                description: "Battery insights indicate a critical issue. Review battery status in System Settings.",
                priority: .high,
                category: .battery
            ))
        }

        return items
    }

    // MARK: - Storage

    private func storageRecommendations(from report: HealthReport) -> [Recommendation] {
        var items: [Recommendation] = []
        let storage = report.storage
        let freePercentage = storage.freePercentage

        switch StorageStatus.from(freePercentage: freePercentage) {
        case .critical:
            items.append(makeRecommendation(
                title: "Free Storage Space",
                description: "Less than 10% of your disk is free. Delete large unused files, empty Trash, and move archives to external storage.",
                priority: .high,
                category: .storage
            ))
            items.append(makeRecommendation(
                title: "Remove Large Unused Files",
                description: "Open About This Mac → Storage to find large apps, downloads, and system data you can remove.",
                priority: .high,
                category: .storage
            ))
        case .warning:
            items.append(makeRecommendation(
                title: "Free Storage Space",
                description: "Only \(Int((freePercentage * 100).rounded()))% of disk space is free. Clear caches and old downloads before space runs out.",
                priority: .medium,
                category: .storage
            ))
        case .healthy:
            break
        }

        if report.storageScore < 70 {
            items.append(makeRecommendation(
                title: "Improve Available Storage",
                description: "Storage health score is \(report.storageScore)/100. Aim to keep at least 20% of your drive free.",
                priority: .medium,
                category: .storage
            ))
        }

        return items
    }

    // MARK: - Memory

    private func memoryRecommendations(from report: HealthReport) -> [Recommendation] {
        var items: [Recommendation] = []
        let memory = report.memory
        let swapLabel = ByteFormatter.swapString(from: memory.swapUsedBytes)

        switch memory.status {
        case .critical:
            items.append(makeRecommendation(
                title: "Reduce Memory-Heavy Applications",
                description: "Memory pressure is critical. Quit apps you are not using, especially browsers with many tabs and creative tools.",
                priority: .high,
                category: .memory
            ))
            items.append(makeRecommendation(
                title: "Restart Memory-Intensive Apps",
                description: "Restart apps that have been running for a long time to release leaked memory. Swap usage is \(swapLabel).",
                priority: .high,
                category: .memory
            ))
        case .warning:
            items.append(makeRecommendation(
                title: "Reduce Memory-Heavy Applications",
                description: "Your Mac is under memory pressure. Close unused windows and apps to improve responsiveness.",
                priority: .medium,
                category: .memory
            ))
        case .healthy:
            let swapRatio = memory.totalMemoryBytes > 0
                ? Double(memory.swapUsedBytes) / Double(memory.totalMemoryBytes)
                : 0
            if swapRatio >= 0.25 {
                items.append(makeRecommendation(
                    title: "Restart Memory-Intensive Apps",
                    description: "Swap usage (\(swapLabel)) is elevated. Restarting heavy apps can free memory without a full reboot.",
                    priority: .low,
                    category: .memory
                ))
            }
        }

        if report.memoryScore < 60 {
            items.append(makeRecommendation(
                title: "Relieve Memory Pressure",
                description: "Memory health score is \(report.memoryScore)/100. Reduce open apps and consider a restart if performance feels sluggish.",
                priority: .medium,
                category: .memory
            ))
        }

        return items
    }

    // MARK: - Startup

    private func startupRecommendations(from report: HealthReport) -> [Recommendation] {
        var items: [Recommendation] = []
        let enabledCount = report.startupApps.filter { $0.isEnabled != false }.count

        if enabledCount >= 9 {
            items.append(makeRecommendation(
                title: "Review Startup Applications",
                description: "\(enabledCount) items launch at login. Open System Settings → General → Login Items and disable apps you do not need at startup.",
                priority: .high,
                category: .startup
            ))
        } else if enabledCount >= 5 {
            items.append(makeRecommendation(
                title: "Review Startup Applications",
                description: "\(enabledCount) items launch at login. Disabling unused login items can speed up boot and free resources.",
                priority: .medium,
                category: .startup
            ))
        } else if enabledCount >= 3 {
            items.append(makeRecommendation(
                title: "Review Startup Applications",
                description: "Periodically review login items in System Settings → General → Login Items to keep startup lean.",
                priority: .low,
                category: .startup
            ))
        }

        if report.startupScore < 65 && enabledCount > 0 {
            items.append(makeRecommendation(
                title: "Trim Login Items",
                description: "Startup score is \(report.startupScore)/100. Fewer login items generally mean faster boots.",
                priority: .medium,
                category: .startup
            ))
        }

        return items
    }

    // MARK: - Thermal

    private func thermalRecommendations(from report: HealthReport) -> [Recommendation] {
        switch report.thermal.status {
        case .serious, .critical:
            return [
                makeRecommendation(
                    title: "Close Heavy Applications",
                    description: "Your Mac is running hot. Quit browsers with many tabs, video editors, and other CPU-intensive apps to reduce heat.",
                    priority: .high,
                    category: .thermal
                ),
                makeRecommendation(
                    title: "Check Ventilation",
                    description: "Make sure vents are unobstructed and your Mac has room to breathe. Avoid using it on soft surfaces that block airflow.",
                    priority: .high,
                    category: .thermal
                ),
                makeRecommendation(
                    title: "Let Your Mac Cool Down",
                    description: "Pause demanding work for a few minutes. macOS will restore full performance once thermal state improves.",
                    priority: .medium,
                    category: .thermal
                )
            ]
        case .fair:
            return [
                makeRecommendation(
                    title: "Monitor Thermal Load",
                    description: "Thermal state is fair. Reduce background activity if performance feels sluggish.",
                    priority: .low,
                    category: .thermal
                )
            ]
        case .nominal, .unknown:
            return []
        }
    }

    // MARK: - General

    private func generalRecommendations(from report: HealthReport) -> [Recommendation] {
        var items: [Recommendation] = []
        let criticalInsightCount = report.insights.filter { $0.severity == .critical }.count

        if report.overallScore < 50 {
            items.append(makeRecommendation(
                title: "Improve Overall System Health",
                description: "Your overall health score is \(report.overallScore)/100. Address battery, storage, memory, thermal, and startup items shown above.",
                priority: .high,
                category: .general
            ))
        } else if report.overallScore < 70 {
            items.append(makeRecommendation(
                title: "Improve Overall System Health",
                description: "Your overall health score is \(report.overallScore)/100. Focus on the highest-priority areas in this report.",
                priority: .medium,
                category: .general
            ))
        }

        if criticalInsightCount >= 2 {
            items.append(makeRecommendation(
                title: "Address Critical Issues First",
                description: "\(criticalInsightCount) critical insights were detected. Resolve storage, memory, thermal, or battery issues before other optimizations.",
                priority: .high,
                category: .general
            ))
        }

        if report.overallScore >= 85 && items.isEmpty {
            items.append(makeRecommendation(
                title: "Keep Up Regular Checkups",
                description: "Your Mac is in good shape. Run MacCheck periodically to catch issues early.",
                priority: .low,
                category: .general
            ))
        }

        return items
    }

    // MARK: - Helpers

    private func hasInsight(
        matching keyword: String,
        severity: InsightSeverity,
        in insights: [HealthInsight]
    ) -> Bool {
        insights.contains { insight in
            insight.severity == severity
                && (insight.title.localizedCaseInsensitiveContains(keyword)
                    || insight.description.localizedCaseInsensitiveContains(keyword))
        }
    }

    private func makeRecommendation(
        title: String,
        description: String,
        priority: RecommendationPriority,
        category: RecommendationCategory
    ) -> Recommendation {
        Recommendation(
            id: UUID(),
            title: title,
            description: description,
            priority: priority,
            category: category
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
