import Foundation

enum HistoryStatisticsBuilder {

    static func build(from snapshots: [HealthSnapshot], calendar: Calendar = .current) -> HistoryStatistics? {
        guard snapshots.count >= 2 else { return nil }

        let chronologicallySorted = snapshots.sorted { $0.timestamp < $1.timestamp }
        let oldest = chronologicallySorted.first!
        let latest = chronologicallySorted.last!

        var items: [StatisticItem] = [
            bestScoreItem(from: snapshots),
            averageScoreItem(from: snapshots),
            daysTrackedItem(from: snapshots, calendar: calendar),
            storageGrowthItem(latest: latest, oldest: oldest),
            highestSwapItem(from: snapshots),
            lowestScoreItem(from: snapshots)
        ]

        if let batteryItem = batteryChangeItem(latest: latest, oldest: oldest) {
            items.insert(batteryItem, at: 3)
        }

        if let thermalItem = highestThermalStateItem(from: snapshots) {
            items.append(thermalItem)
        }

        return HistoryStatistics(items: items)
    }

    // MARK: - Statistics

    private static func bestScoreItem(from snapshots: [HealthSnapshot]) -> StatisticItem {
        let best = snapshots.map(\.overallHealthScore).max() ?? 0
        let occurrence = mostRecentSnapshot(
            where: { $0.overallHealthScore == best },
            in: snapshots
        )
        return StatisticItem(
            id: "best-score",
            title: "Best Score Ever",
            value: "\(best)",
            subtitle: nil,
            occurrenceDate: occurrence?.timestamp,
            systemImage: "arrow.up.circle"
        )
    }

    private static func averageScoreItem(from snapshots: [HealthSnapshot]) -> StatisticItem {
        let scores = snapshots.map(\.overallHealthScore)
        let average = Double(scores.reduce(0, +)) / Double(scores.count)
        let rounded = Int(average.rounded())
        return StatisticItem(
            id: "average-score",
            title: "Average Score",
            value: "\(rounded)",
            subtitle: "Across \(snapshots.count) snapshots",
            occurrenceDate: nil,
            systemImage: "sum"
        )
    }

    private static func daysTrackedItem(
        from snapshots: [HealthSnapshot],
        calendar: Calendar
    ) -> StatisticItem {
        let uniqueDays = Set(snapshots.map { calendar.startOfDay(for: $0.timestamp) })
        return StatisticItem(
            id: "days-tracked",
            title: "Days Tracked",
            value: "\(uniqueDays.count)",
            subtitle: "Unique calendar days with data",
            occurrenceDate: nil,
            systemImage: "calendar"
        )
    }

    private static func batteryChangeItem(
        latest: HealthSnapshot,
        oldest: HealthSnapshot
    ) -> StatisticItem? {
        guard latest.hasBattery,
              oldest.hasBattery,
              let latestHealth = latest.batteryHealthPercentage,
              let oldestHealth = oldest.batteryHealthPercentage
        else {
            return nil
        }

        let delta = latestHealth - oldestHealth
        return StatisticItem(
            id: "battery-change",
            title: "Battery Change Since First Scan",
            value: formattedSignedPercentage(delta),
            subtitle: "From first to most recent snapshot",
            occurrenceDate: nil,
            systemImage: "battery.100"
        )
    }

    private static func storageGrowthItem(
        latest: HealthSnapshot,
        oldest: HealthSnapshot
    ) -> StatisticItem {
        let delta = latest.storageUsedBytes - oldest.storageUsedBytes
        return StatisticItem(
            id: "storage-growth",
            title: "Storage Growth Since First Scan",
            value: formattedSignedGigabytes(delta),
            subtitle: "Change in used storage over time",
            occurrenceDate: nil,
            systemImage: "internaldrive"
        )
    }

    private static func highestSwapItem(from snapshots: [HealthSnapshot]) -> StatisticItem {
        let highestSwap = snapshots.map(\.swapUsedBytes).max() ?? 0
        let occurrence = mostRecentSnapshot(
            where: { $0.swapUsedBytes == highestSwap },
            in: snapshots
        )
        return StatisticItem(
            id: "highest-swap",
            title: "Highest Swap Usage Ever",
            value: gigabyteAmountString(from: highestSwap),
            subtitle: nil,
            occurrenceDate: occurrence?.timestamp,
            systemImage: "memorychip"
        )
    }

    private static func lowestScoreItem(from snapshots: [HealthSnapshot]) -> StatisticItem {
        let lowest = snapshots.map(\.overallHealthScore).min() ?? 0
        let occurrence = mostRecentSnapshot(
            where: { $0.overallHealthScore == lowest },
            in: snapshots
        )
        return StatisticItem(
            id: "lowest-score",
            title: "Lowest Score Ever",
            value: "\(lowest)",
            subtitle: nil,
            occurrenceDate: occurrence?.timestamp,
            systemImage: "arrow.down.circle"
        )
    }

    private static func highestThermalStateItem(from snapshots: [HealthSnapshot]) -> StatisticItem? {
        let knownSnapshots = snapshots.filter { $0.thermalStatus != .unknown }
        guard let worstStatus = knownSnapshots
            .map(\.thermalStatus)
            .max(by: { thermalSeverity($0) < thermalSeverity($1) })
        else {
            return nil
        }

        let occurrence = mostRecentSnapshot(
            where: { $0.thermalStatus == worstStatus },
            in: knownSnapshots
        )

        return StatisticItem(
            id: "highest-thermal-state",
            title: "Highest Thermal State Ever",
            value: worstStatus.displayName,
            subtitle: nil,
            occurrenceDate: occurrence?.timestamp,
            systemImage: "thermometer.medium"
        )
    }

    private static func mostRecentSnapshot(
        where predicate: (HealthSnapshot) -> Bool,
        in snapshots: [HealthSnapshot]
    ) -> HealthSnapshot? {
        snapshots
            .filter(predicate)
            .max(by: { $0.timestamp < $1.timestamp })
    }

    // MARK: - Formatting

    private static func formattedSignedPercentage(_ delta: Double) -> String {
        let formatted = String(format: "%+.1f%%", delta)
        return formatted
    }

    private static func formattedSignedGigabytes(_ deltaBytes: Int64) -> String {
        if deltaBytes == 0 { return "0 GB" }
        let sign = deltaBytes > 0 ? "+" : "−"
        return "\(sign)\(gigabyteAmountString(from: deltaBytes))"
    }

    private static func gigabyteAmountString(from bytes: Int64) -> String {
        let gigabytes = abs(Double(bytes)) / 1_073_741_824.0
        if gigabytes >= 10 {
            return String(format: "%.0f GB", gigabytes)
        }
        return String(format: "%.1f GB", gigabytes)
    }

    private static func thermalSeverity(_ status: ThermalStatus) -> Int {
        switch status {
        case .nominal: return 0
        case .fair: return 1
        case .serious: return 2
        case .critical: return 3
        case .unknown: return -1
        }
    }
}
