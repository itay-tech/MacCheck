import Foundation

struct TrendItem: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let currentValue: String
    let previousValue: String
    let changeValue: String
    let directionLabel: String
    let summary: String
    let trend: ComparisonTrend
}

enum TrendAnalysisBuilder {

    static func build(current: HealthSnapshot, previous: HealthSnapshot) -> [TrendItem] {
        var items: [TrendItem] = [
            healthScoreTrend(current: current, previous: previous),
            storageTrend(current: current, previous: previous),
            memoryTrend(current: current, previous: previous),
            startupAppsTrend(current: current, previous: previous),
            thermalTrend(current: current, previous: previous)
        ]

        if current.hasBattery, previous.hasBattery {
            items.insert(batteryTrend(current: current, previous: previous), at: 1)
        }

        return items
    }

    // MARK: - Trends

    private static func healthScoreTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        let delta = current.overallHealthScore - previous.overallHealthScore
        let trend = comparisonTrend(forDelta: delta, higherIsBetter: true)

        return TrendItem(
            id: "health-score-trend",
            title: "Health Score Trend",
            systemImage: "heart.text.square",
            currentValue: "\(current.overallHealthScore)",
            previousValue: "\(previous.overallHealthScore)",
            changeValue: formattedSigned(delta),
            directionLabel: directionLabel(for: trend),
            summary: healthScoreSummary(delta: delta, trend: trend),
            trend: trend
        )
    }

    private static func batteryTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        let currentPercent = current.batteryHealthPercentage.map { Int($0.rounded()) }
        let previousPercent = previous.batteryHealthPercentage.map { Int($0.rounded()) }

        let delta: Int
        let trend: ComparisonTrend
        if let currentPercent, let previousPercent {
            delta = currentPercent - previousPercent
            trend = comparisonTrend(forDelta: delta, higherIsBetter: true)
        } else {
            delta = 0
            trend = .neutral
        }

        return TrendItem(
            id: "battery-trend",
            title: "Battery Trend",
            systemImage: "battery.100",
            currentValue: currentPercent.map { "\($0)%" } ?? "—",
            previousValue: previousPercent.map { "\($0)%" } ?? "—",
            changeValue: currentPercent != nil && previousPercent != nil
                ? formattedSigned(delta, suffix: "%")
                : "—",
            directionLabel: directionLabel(for: trend),
            summary: batterySummary(delta: delta, trend: trend),
            trend: trend
        )
    }

    private static func storageTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        let delta = current.storageUsedBytes - previous.storageUsedBytes
        let trend = comparisonTrend(forDelta: Int(delta.signum()), higherIsBetter: false)

        return TrendItem(
            id: "storage-trend",
            title: "Storage Trend",
            systemImage: "internaldrive",
            currentValue: ByteFormatter.string(from: current.storageUsedBytes),
            previousValue: ByteFormatter.string(from: previous.storageUsedBytes),
            changeValue: formattedSignedGigabytes(delta),
            directionLabel: directionLabel(for: trend),
            summary: storageSummary(deltaBytes: delta),
            trend: trend
        )
    }

    private static func memoryTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        let delta = current.swapUsedBytes - previous.swapUsedBytes
        let trend = comparisonTrend(forDelta: Int(delta.signum()), higherIsBetter: false)

        return TrendItem(
            id: "memory-trend",
            title: "Memory Trend",
            systemImage: "memorychip",
            currentValue: ByteFormatter.swapString(from: current.swapUsedBytes),
            previousValue: ByteFormatter.swapString(from: previous.swapUsedBytes),
            changeValue: formattedSignedGigabytes(delta),
            directionLabel: directionLabel(for: trend),
            summary: swapSummary(deltaBytes: delta),
            trend: trend
        )
    }

    private static func startupAppsTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        let delta = current.startupAppsCount - previous.startupAppsCount
        let trend = comparisonTrend(forDelta: delta, higherIsBetter: false)

        return TrendItem(
            id: "startup-apps-trend",
            title: "Startup Apps Trend",
            systemImage: "power.circle",
            currentValue: "\(current.startupAppsCount)",
            previousValue: "\(previous.startupAppsCount)",
            changeValue: formattedSigned(delta),
            directionLabel: directionLabel(for: trend),
            summary: startupSummary(delta: delta, trend: trend),
            trend: trend
        )
    }

    private static func thermalTrend(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> TrendItem {
        if current.thermalStatus == .unknown || previous.thermalStatus == .unknown {
            return TrendItem(
                id: "thermal-trend",
                title: "Thermal Trend",
                systemImage: "thermometer.medium",
                currentValue: thermalDisplayValue(for: current.thermalStatus),
                previousValue: thermalDisplayValue(for: previous.thermalStatus),
                changeValue: "—",
                directionLabel: "Unavailable",
                summary: "Not enough thermal data",
                trend: .neutral
            )
        }

        let currentSeverity = thermalSeverity(current.thermalStatus)
        let previousSeverity = thermalSeverity(previous.thermalStatus)
        let delta = currentSeverity - previousSeverity

        let trend: ComparisonTrend
        let directionLabel: String
        let summary: String
        let changeValue: String

        if current.thermalStatus == previous.thermalStatus {
            trend = .neutral
            directionLabel = "Stable"
            summary = "Thermal state remained stable"
            changeValue = "Stable"
        } else if delta < 0 {
            trend = .positive
            directionLabel = "Improved"
            summary = "Thermal state improved"
            changeValue = "Improved"
        } else if delta > 0 {
            trend = .negative
            directionLabel = "Worsened"
            summary = "Thermal state worsened"
            changeValue = "Worsened"
        } else {
            trend = .neutral
            directionLabel = "Stable"
            summary = "Thermal state remained stable"
            changeValue = "Changed"
        }

        return TrendItem(
            id: "thermal-trend",
            title: "Thermal Trend",
            systemImage: "thermometer.medium",
            currentValue: current.thermalStatus.displayName,
            previousValue: previous.thermalStatus.displayName,
            changeValue: changeValue,
            directionLabel: directionLabel,
            summary: summary,
            trend: trend
        )
    }

    // MARK: - Summaries

    private static func healthScoreSummary(delta: Int, trend: ComparisonTrend) -> String {
        switch trend {
        case .positive:
            "Health score improved by \(abs(delta)) points"
        case .negative:
            "Health score declined by \(abs(delta)) points"
        case .neutral:
            "Health score remained unchanged"
        }
    }

    private static func batterySummary(delta: Int, trend: ComparisonTrend) -> String {
        switch trend {
        case .positive:
            "Battery health improved by \(abs(delta))%"
        case .negative:
            "Battery health declined by \(abs(delta))%"
        case .neutral:
            "Battery health remained unchanged"
        }
    }

    private static func storageSummary(deltaBytes: Int64) -> String {
        if deltaBytes == 0 {
            return "Storage usage remained stable"
        }
        let amount = gigabyteAmountString(from: deltaBytes)
        if deltaBytes > 0 {
            return "Storage usage increased by \(amount)"
        }
        return "Storage usage decreased by \(amount)"
    }

    private static func swapSummary(deltaBytes: Int64) -> String {
        if deltaBytes == 0 {
            return "Swap usage remained stable"
        }
        let amount = gigabyteAmountString(from: deltaBytes)
        if deltaBytes > 0 {
            return "Swap usage increased by \(amount)"
        }
        return "Swap usage decreased by \(amount)"
    }

    private static func startupSummary(delta: Int, trend: ComparisonTrend) -> String {
        switch trend {
        case .positive:
            "Startup apps decreased by \(abs(delta))"
        case .negative:
            "Startup apps increased by \(abs(delta))"
        case .neutral:
            "Startup apps remained unchanged"
        }
    }

    // MARK: - Helpers

    private static func comparisonTrend(forDelta delta: Int, higherIsBetter: Bool) -> ComparisonTrend {
        if delta == 0 { return .neutral }
        if higherIsBetter {
            return delta > 0 ? .positive : .negative
        }
        return delta < 0 ? .positive : .negative
    }

    private static func directionLabel(for trend: ComparisonTrend) -> String {
        switch trend {
        case .positive: "Improved"
        case .negative: "Declined"
        case .neutral: "Unchanged"
        }
    }

    private static func formattedSigned(_ value: Int, suffix: String = "") -> String {
        if value > 0 { return "+\(value)\(suffix)" }
        if value < 0 { return "\(value)\(suffix)" }
        return "0\(suffix)"
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

    private static func thermalDisplayValue(for status: ThermalStatus) -> String {
        status == .unknown ? "Unavailable" : status.displayName
    }

    private static func thermalSeverity(_ status: ThermalStatus) -> Int {
        switch status {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        case .unknown: 0
        }
    }
}

private extension Int64 {
    var signum: Int {
        if self > 0 { return 1 }
        if self < 0 { return -1 }
        return 0
    }
}
