import Foundation

enum ComparisonTrend: Equatable {
    case positive
    case negative
    case neutral
}

struct HistoryComparisonItem: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let currentValue: String
    let previousValue: String
    let deltaValue: String
    let trend: ComparisonTrend
}

enum HistoryComparisonBuilder {

    static func build(current: HealthSnapshot, previous: HealthSnapshot) -> [HistoryComparisonItem] {
        var items: [HistoryComparisonItem] = []

        items.append(intDeltaItem(
            id: "overall-score",
            title: "Overall Health Score",
            systemImage: "heart.text.square",
            current: current.overallHealthScore,
            previous: previous.overallHealthScore,
            higherIsBetter: true
        ))

        if current.hasBattery, previous.hasBattery {
            items.append(optionalPercentageItem(
                id: "battery-health",
                title: "Battery Health",
                systemImage: "battery.100",
                current: current.batteryHealthPercentage,
                previous: previous.batteryHealthPercentage,
                higherIsBetter: true
            ))
        }

        items.append(bytesDeltaItem(
            id: "storage-used",
            title: "Storage Used",
            systemImage: "internaldrive",
            currentBytes: current.storageUsedBytes,
            previousBytes: previous.storageUsedBytes,
            lowerIsBetter: true
        ))

        items.append(percentageDeltaItem(
            id: "free-storage",
            title: "Free Storage",
            systemImage: "externaldrive.badge.checkmark",
            current: current.storageFreePercentage,
            previous: previous.storageFreePercentage,
            higherIsBetter: true
        ))

        items.append(bytesDeltaItem(
            id: "memory-used",
            title: "Memory Used",
            systemImage: "memorychip",
            currentBytes: current.memoryUsedBytes,
            previousBytes: previous.memoryUsedBytes,
            lowerIsBetter: true
        ))

        items.append(bytesDeltaItem(
            id: "swap-used",
            title: "Swap Used",
            systemImage: "arrow.left.arrow.right",
            currentBytes: current.swapUsedBytes,
            previousBytes: previous.swapUsedBytes,
            lowerIsBetter: true
        ))

        items.append(intDeltaItem(
            id: "startup-apps",
            title: "Startup Apps",
            systemImage: "power.circle",
            current: current.startupAppsCount,
            previous: previous.startupAppsCount,
            higherIsBetter: false
        ))

        items.append(thermalStatusItem(current: current, previous: previous))

        return items
    }

    // MARK: - Private

    private static func intDeltaItem(
        id: String,
        title: String,
        systemImage: String,
        current: Int,
        previous: Int,
        higherIsBetter: Bool
    ) -> HistoryComparisonItem {
        let delta = current - previous
        return HistoryComparisonItem(
            id: id,
            title: title,
            systemImage: systemImage,
            currentValue: "\(current)",
            previousValue: "\(previous)",
            deltaValue: formattedSigned(delta),
            trend: trend(forDelta: delta, higherIsBetter: higherIsBetter)
        )
    }

    private static func optionalPercentageItem(
        id: String,
        title: String,
        systemImage: String,
        current: Double?,
        previous: Double?,
        higherIsBetter: Bool
    ) -> HistoryComparisonItem {
        let currentValue = current.map { "\(Int($0.rounded()))%" } ?? "—"
        let previousValue = previous.map { "\(Int($0.rounded()))%" } ?? "—"

        let delta: Int
        let deltaText: String
        if let current, let previous {
            delta = Int(current.rounded()) - Int(previous.rounded())
            deltaText = formattedSigned(delta, suffix: "%")
        } else {
            delta = 0
            deltaText = "—"
        }

        return HistoryComparisonItem(
            id: id,
            title: title,
            systemImage: systemImage,
            currentValue: currentValue,
            previousValue: previousValue,
            deltaValue: deltaText,
            trend: deltaText == "—" ? .neutral : trend(forDelta: delta, higherIsBetter: higherIsBetter)
        )
    }

    private static func percentageDeltaItem(
        id: String,
        title: String,
        systemImage: String,
        current: Double,
        previous: Double,
        higherIsBetter: Bool
    ) -> HistoryComparisonItem {
        let currentPercent = Int((current * 100).rounded())
        let previousPercent = Int((previous * 100).rounded())
        let delta = currentPercent - previousPercent

        return HistoryComparisonItem(
            id: id,
            title: title,
            systemImage: systemImage,
            currentValue: "\(currentPercent)%",
            previousValue: "\(previousPercent)%",
            deltaValue: formattedSigned(delta, suffix: "%"),
            trend: trend(forDelta: delta, higherIsBetter: higherIsBetter)
        )
    }

    private static func bytesDeltaItem(
        id: String,
        title: String,
        systemImage: String,
        currentBytes: Int64,
        previousBytes: Int64,
        lowerIsBetter: Bool
    ) -> HistoryComparisonItem {
        let delta = currentBytes - previousBytes
        let higherIsBetter = !lowerIsBetter

        return HistoryComparisonItem(
            id: id,
            title: title,
            systemImage: systemImage,
            currentValue: ByteFormatter.string(from: currentBytes),
            previousValue: ByteFormatter.string(from: previousBytes),
            deltaValue: formattedBytesDelta(delta),
            trend: trend(forDelta: Int(delta.signum()), higherIsBetter: higherIsBetter)
        )
    }

    private static func thermalStatusItem(
        current: HealthSnapshot,
        previous: HealthSnapshot
    ) -> HistoryComparisonItem {
        let currentSeverity = thermalSeverity(current.thermalStatus)
        let previousSeverity = thermalSeverity(previous.thermalStatus)
        let delta = currentSeverity - previousSeverity

        let deltaText: String
        let trend: ComparisonTrend
        if current.thermalStatus == previous.thermalStatus {
            deltaText = "Unchanged"
            trend = .neutral
        } else if delta < 0 {
            deltaText = "Improved"
            trend = .positive
        } else if delta > 0 {
            deltaText = "Worsened"
            trend = .negative
        } else {
            deltaText = "Changed"
            trend = .neutral
        }

        return HistoryComparisonItem(
            id: "thermal-status",
            title: "Thermal Status",
            systemImage: "thermometer.medium",
            currentValue: current.thermalStatus.displayName,
            previousValue: previous.thermalStatus.displayName,
            deltaValue: deltaText,
            trend: trend
        )
    }

    private static func thermalSeverity(_ status: ThermalStatus) -> Int {
        switch status {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        case .unknown: 4
        }
    }

    private static func trend(forDelta delta: Int, higherIsBetter: Bool) -> ComparisonTrend {
        if delta == 0 { return .neutral }
        if higherIsBetter {
            return delta > 0 ? .positive : .negative
        }
        return delta < 0 ? .positive : .negative
    }

    private static func formattedSigned(_ value: Int, suffix: String = "") -> String {
        if value > 0 { return "+\(value)\(suffix)" }
        if value < 0 { return "\(value)\(suffix)" }
        return "0\(suffix)"
    }

    private static func formattedBytesDelta(_ delta: Int64) -> String {
        if delta == 0 { return "0" }
        let sign = delta > 0 ? "+" : "−"
        return "\(sign)\(ByteFormatter.string(from: abs(delta)))"
    }
}

private extension Int64 {
    var signum: Int {
        if self > 0 { return 1 }
        if self < 0 { return -1 }
        return 0
    }
}
