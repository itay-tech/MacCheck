import Foundation

enum HistoryChartBuilder {

    // MARK: - Health Score

    static func healthScore(from snapshots: [HealthSnapshot]) -> HistoryLineChartViewModel {
        let sorted = chronologicallySorted(snapshots)
        let points = sorted.map {
            ChartDataPoint(id: $0.id, date: $0.timestamp, value: Double($0.overallHealthScore))
        }

        guard points.count >= 2 else {
            return .needsMoreData(
                title: "Health Score Over Time",
                subtitle: "Daily overall health score",
                systemImage: "heart.text.square",
                pointStyle: .healthScore,
                yAxisFormat: .integer
            )
        }

        let change = Int(points.last!.value.rounded()) - Int(points.first!.value.rounded())
        return .ready(
            title: "Health Score Over Time",
            subtitle: "Daily overall health score",
            systemImage: "heart.text.square",
            dataPoints: points,
            axisGranularity: ChartAxisGranularity.forSnapshotCount(points.count),
            yAxisDomain: 0...100,
            yAxisTickValues: [0, 25, 50, 75, 100],
            yAxisFormat: .integer,
            pointStyle: .healthScore,
            summaryTitle: "Health Score Trend",
            summaryText: summaryForChange(change),
            summaryTrend: trendForChange(change)
        )
    }

    // MARK: - Battery

    static func batteryHealth(from snapshots: [HealthSnapshot]) -> HistoryLineChartViewModel {
        let sorted = chronologicallySorted(snapshots)
        let batterySnapshots = sorted.filter { $0.hasBattery && $0.batteryHealthPercentage != nil }

        guard !batterySnapshots.isEmpty else {
            return .unavailable(
                title: "Battery Health Over Time",
                subtitle: "Battery health percentage history",
                systemImage: "battery.100",
                message: "Battery history is unavailable on this Mac.",
                pointStyle: .battery,
                yAxisFormat: .percentage
            )
        }

        let points = batterySnapshots.map {
            ChartDataPoint(id: $0.id, date: $0.timestamp, value: $0.batteryHealthPercentage!)
        }

        guard points.count >= 2 else {
            return .needsMoreData(
                title: "Battery Health Over Time",
                subtitle: "Battery health percentage history",
                systemImage: "battery.100",
                pointStyle: .battery,
                yAxisFormat: .percentage
            )
        }

        let change = points.last!.value - points.first!.value
        return .ready(
            title: "Battery Health Over Time",
            subtitle: "Battery health percentage history",
            systemImage: "battery.100",
            dataPoints: points,
            axisGranularity: ChartAxisGranularity.forSnapshotCount(points.count),
            yAxisDomain: 0...100,
            yAxisTickValues: [0, 25, 50, 75, 100],
            yAxisFormat: .percentage,
            pointStyle: .battery,
            summaryTitle: "Battery Trend",
            summaryText: String(format: "%+.1f%% since first scan", change),
            summaryTrend: trendForChange(Int(change.rounded()))
        )
    }

    // MARK: - Storage

    static func storageUsage(from snapshots: [HealthSnapshot]) -> HistoryLineChartViewModel {
        buildBytesChart(
            from: snapshots,
            title: "Storage Usage Over Time",
            subtitle: "Used storage in gigabytes",
            systemImage: "internaldrive",
            pointStyle: .storage,
            value: { Double($0.storageUsedBytes) }
        )
    }

    // MARK: - Swap

    static func swapUsage(from snapshots: [HealthSnapshot]) -> HistoryLineChartViewModel {
        buildBytesChart(
            from: snapshots,
            title: "Swap Usage Over Time",
            subtitle: "Swap memory usage in gigabytes",
            systemImage: "memorychip",
            pointStyle: .memory,
            value: { Double($0.swapUsedBytes) }
        )
    }

    // MARK: - Thermal

    static func thermalHistory(from snapshots: [HealthSnapshot]) -> HistoryLineChartViewModel {
        let sorted = chronologicallySorted(snapshots)
        let knownSnapshots = sorted.filter { $0.thermalStatus != .unknown }

        guard !knownSnapshots.isEmpty else {
            return .unavailable(
                title: "Thermal History Over Time",
                subtitle: "Thermal severity over time",
                systemImage: "thermometer.medium",
                message: "Thermal history is unavailable for these snapshots.",
                pointStyle: .thermal,
                yAxisFormat: .thermalSeverity,
                yAxisDomain: 0...3
            )
        }

        let points = knownSnapshots.map {
            ChartDataPoint(
                id: $0.id,
                date: $0.timestamp,
                value: Double(thermalSeverity($0.thermalStatus))
            )
        }

        guard points.count >= 2 else {
            return .needsMoreData(
                title: "Thermal History Over Time",
                subtitle: "Thermal severity over time",
                systemImage: "thermometer.medium",
                pointStyle: .thermal,
                yAxisFormat: .thermalSeverity,
                yAxisDomain: 0...3
            )
        }

        let change = Int(points.last!.value.rounded()) - Int(points.first!.value.rounded())
        return .ready(
            title: "Thermal History Over Time",
            subtitle: "Thermal severity over time",
            systemImage: "thermometer.medium",
            dataPoints: points,
            axisGranularity: ChartAxisGranularity.forSnapshotCount(points.count),
            yAxisDomain: 0...3,
            yAxisTickValues: [0, 1, 2, 3],
            yAxisFormat: .thermalSeverity,
            pointStyle: .thermal,
            summaryTitle: "Thermal Trend",
            summaryText: thermalSummary(for: change),
            summaryTrend: thermalTrend(for: change)
        )
    }

    // MARK: - Private

    private static func buildBytesChart(
        from snapshots: [HealthSnapshot],
        title: String,
        subtitle: String,
        systemImage: String,
        pointStyle: ChartPointStyle,
        value: (HealthSnapshot) -> Double
    ) -> HistoryLineChartViewModel {
        let sorted = chronologicallySorted(snapshots)
        let points = sorted.map { ChartDataPoint(id: $0.id, date: $0.timestamp, value: value($0)) }

        guard points.count >= 2 else {
            return .needsMoreData(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                pointStyle: pointStyle,
                yAxisFormat: .gigabytes,
                yAxisDomain: 0...1
            )
        }

        let valuesGB = points.map { $0.value / 1_073_741_824.0 }
        let maxGB = valuesGB.max() ?? 1
        let domainUpper = max(maxGB * 1.15, 1)

        let firstGB = valuesGB.first ?? 0
        let lastGB = valuesGB.last ?? 0
        let deltaGB = lastGB - firstGB

        return .ready(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            dataPoints: points,
            axisGranularity: ChartAxisGranularity.forSnapshotCount(points.count),
            yAxisDomain: 0...domainUpper,
            yAxisTickValues: nil,
            yAxisFormat: .gigabytes,
            pointStyle: pointStyle,
            summaryTitle: "Usage Trend",
            summaryText: bytesTrendSummary(deltaGB: deltaGB),
            summaryTrend: trendForBytesChange(deltaGB)
        )
    }

    private static func chronologicallySorted(_ snapshots: [HealthSnapshot]) -> [HealthSnapshot] {
        snapshots.sorted { $0.timestamp < $1.timestamp }
    }

    private static func trendForChange(_ change: Int) -> ComparisonTrend {
        if change > 0 { return .positive }
        if change < 0 { return .negative }
        return .neutral
    }

    private static func summaryForChange(_ change: Int) -> String {
        if change > 0 { return "+\(change) points since first scan" }
        if change < 0 { return "\(change) points since first scan" }
        return "0 points since first scan"
    }

    private static func trendForBytesChange(_ deltaGB: Double) -> ComparisonTrend {
        if deltaGB > 0.05 { return .negative }
        if deltaGB < -0.05 { return .positive }
        return .neutral
    }

    private static func bytesTrendSummary(deltaGB: Double) -> String {
        if abs(deltaGB) < 0.05 { return "Usage remained stable since first scan" }
        let sign = deltaGB > 0 ? "+" : "−"
        return "\(sign)\(gigabyteAmountString(from: deltaGB)) since first scan"
    }

    private static func gigabyteAmountString(from gigabytes: Double) -> String {
        let absValue = abs(gigabytes)
        if absValue >= 10 { return String(format: "%.0f GB", absValue) }
        return String(format: "%.1f GB", absValue)
    }

    private static func thermalSeverity(_ status: ThermalStatus) -> Int {
        switch status {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        case .unknown: -1
        }
    }

    private static func thermalSummary(for change: Int) -> String {
        if change < 0 { return "Thermal state improved since first scan" }
        if change > 0 { return "Thermal state worsened since first scan" }
        return "Thermal state remained stable since first scan"
    }

    private static func thermalTrend(for change: Int) -> ComparisonTrend {
        if change < 0 { return .positive }
        if change > 0 { return .negative }
        return .neutral
    }
}
