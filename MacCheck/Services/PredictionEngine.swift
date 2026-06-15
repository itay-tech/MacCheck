import Foundation

/// Pure prediction calculations from local history. Extend with new forecast types here.
enum PredictionEngine {

    static let minimumSnapshots = 7

    private static let warningStorageFraction = 0.80
    private static let criticalStorageFraction = 0.90
    private static let bytesPerGigabyte = 1_073_741_824.0

    // MARK: - Entry Point

    static func build(
        from snapshots: [HealthSnapshot],
        calendar: Calendar = .current
    ) -> PredictionsPageData {
        let sorted = chronologicallySorted(snapshots)
        let count = sorted.count

        guard count >= minimumSnapshots else {
            return .insufficientHistory(snapshotCount: count)
        }

        let confidence = confidence(for: count)

        return PredictionsPageData(
            snapshotCount: count,
            hasEnoughHistory: true,
            storageForecast: storageForecast(from: sorted, confidence: confidence, calendar: calendar),
            batteryForecast: batteryForecast(from: sorted, confidence: confidence, calendar: calendar),
            healthScoreForecast: healthScoreForecast(from: sorted, confidence: confidence, calendar: calendar),
            memoryRiskForecast: memoryRiskForecast(from: sorted, confidence: confidence, calendar: calendar),
            thermalRiskForecast: thermalRiskForecast(from: sorted, confidence: confidence, calendar: calendar)
        )
    }

    // MARK: - Confidence

    static func confidence(for snapshotCount: Int) -> PredictionConfidence {
        if snapshotCount < 14 { return .low }
        if snapshotCount <= 30 { return .medium }
        return .high
    }

    // MARK: - Storage Forecast

    private static func storageForecast(
        from snapshots: [HealthSnapshot],
        confidence: PredictionConfidence,
        calendar: Calendar
    ) -> PredictionCardModel {
        guard let latest = snapshots.last else {
            return unavailableCard(
                id: "storage",
                title: "Storage Forecast",
                subtitle: "Projected storage usage and fill-up timeline",
                systemImage: "internaldrive",
                message: "Storage history is unavailable.",
                confidence: confidence
            )
        }

        let points = snapshots.map { (date: $0.timestamp, value: Double($0.storageUsedBytes)) }
        let dailyGrowth = linearDailyRate(points: points, calendar: calendar)
        let currentUsed = latest.storageUsedBytes
        let totalBytes = max(latest.storageTotalBytes, 1)

        let warningBytes = Int64((Double(totalBytes) * warningStorageFraction).rounded())
        let criticalBytes = Int64((Double(totalBytes) * criticalStorageFraction).rounded())

        let daysUntilWarning = daysUntilThreshold(
            current: currentUsed,
            threshold: warningBytes,
            dailyGrowth: dailyGrowth
        )
        let daysUntilCritical = daysUntilThreshold(
            current: currentUsed,
            threshold: criticalBytes,
            dailyGrowth: dailyGrowth
        )

        let growthSummary = growthRateSummary(bytesPerDay: dailyGrowth)
        let warningSummary = daysSummary(daysUntilWarning, label: "Warning")
        let criticalSummary = daysSummary(daysUntilCritical, label: "Critical")
        let summary = "\(growthSummary)\n\(warningSummary) • \(criticalSummary)"

        return PredictionCardModel(
            id: "storage",
            title: "Storage Forecast",
            subtitle: "Projected storage usage and fill-up timeline",
            systemImage: "internaldrive",
            displayMode: .ready,
            summary: summary,
            metrics: [
                metric(id: "current-usage", label: "Current Usage", value: ByteFormatter.string(from: currentUsed)),
                metric(
                    id: "growth-rate",
                    label: "Average Growth Rate",
                    value: growthRateString(bytesPerDay: dailyGrowth),
                    tone: dailyGrowth > 0 ? .warning : .positive
                ),
                metric(
                    id: "days-warning",
                    label: "Estimated Days Until Warning",
                    value: daysValue(daysUntilWarning),
                    tone: daysTone(daysUntilWarning)
                ),
                metric(
                    id: "days-critical",
                    label: "Estimated Days Until Critical",
                    value: daysValue(daysUntilCritical),
                    tone: daysTone(daysUntilCritical)
                )
            ],
            confidence: confidence,
            riskLevel: storageRiskLevel(daysUntilWarning: daysUntilWarning, dailyGrowth: dailyGrowth)
        )
    }

    // MARK: - Battery Forecast

    private static func batteryForecast(
        from snapshots: [HealthSnapshot],
        confidence: PredictionConfidence,
        calendar: Calendar
    ) -> PredictionCardModel {
        let batterySnapshots = snapshots.filter { $0.hasBattery && $0.batteryHealthPercentage != nil }

        guard !batterySnapshots.isEmpty else {
            return unavailableCard(
                id: "battery",
                title: "Battery Forecast",
                subtitle: "Projected battery health decline",
                systemImage: "battery.100",
                message: "Battery history is unavailable on this Mac.",
                confidence: confidence
            )
        }

        guard batterySnapshots.count >= 2 else {
            return unavailableCard(
                id: "battery",
                title: "Battery Forecast",
                subtitle: "Projected battery health decline",
                systemImage: "battery.100",
                message: "More battery history is needed for a forecast.",
                confidence: confidence
            )
        }

        let points = batterySnapshots.map {
            (date: $0.timestamp, value: $0.batteryHealthPercentage!)
        }
        let dailyDecline = -linearDailyRate(points: points, calendar: calendar)
        let currentHealth = batterySnapshots.last!.batteryHealthPercentage!

        let monthsUntil85 = monthsUntilThreshold(
            current: currentHealth,
            threshold: 85,
            dailyDecline: dailyDecline
        )
        let monthsUntil80 = monthsUntilThreshold(
            current: currentHealth,
            threshold: 80,
            dailyDecline: dailyDecline
        )

        let summary: String
        if dailyDecline <= 0.01 {
            summary = "Battery health has remained stable over tracked history."
        } else {
            summary = "Declining by \(String(format: "%.2f", dailyDecline))% per day on average."
        }

        return PredictionCardModel(
            id: "battery",
            title: "Battery Forecast",
            subtitle: "Projected battery health decline",
            systemImage: "battery.100",
            displayMode: .ready,
            summary: summary,
            metrics: [
                metric(
                    id: "current-health",
                    label: "Current Battery Health",
                    value: "\(Int(currentHealth.rounded()))%",
                    tone: batteryHealthTone(currentHealth)
                ),
                metric(
                    id: "months-85",
                    label: "Estimated Months Until 85%",
                    value: monthsValue(monthsUntil85),
                    tone: monthsTone(monthsUntil85)
                ),
                metric(
                    id: "months-80",
                    label: "Estimated Months Until 80%",
                    value: monthsValue(monthsUntil80),
                    tone: monthsTone(monthsUntil80)
                )
            ],
            confidence: confidence,
            riskLevel: batteryRiskLevel(current: currentHealth, dailyDecline: dailyDecline)
        )
    }

    // MARK: - Health Score Forecast

    private static func healthScoreForecast(
        from snapshots: [HealthSnapshot],
        confidence: PredictionConfidence,
        calendar: Calendar
    ) -> PredictionCardModel {
        let points = snapshots.map {
            (date: $0.timestamp, value: Double($0.overallHealthScore))
        }
        let dailyChange = linearDailyRate(points: points, calendar: calendar)
        let current = snapshots.last!.overallHealthScore
        let forecast30 = clampScore(current + Int((dailyChange * 30).rounded()))
        let forecast90 = clampScore(current + Int((dailyChange * 90).rounded()))

        let trendWord: String
        if dailyChange > 0.05 {
            trendWord = "improving"
        } else if dailyChange < -0.05 {
            trendWord = "declining"
        } else {
            trendWord = "stable"
        }

        return PredictionCardModel(
            id: "health-score",
            title: "Health Score Forecast",
            subtitle: "Projected overall health score trend",
            systemImage: "heart.text.square",
            displayMode: .ready,
            summary: "Health score trend is \(trendWord) based on recent history.",
            metrics: [
                metric(
                    id: "current-score",
                    label: "Current Score",
                    value: "\(current)",
                    tone: .accent
                ),
                metric(
                    id: "forecast-30",
                    label: "30-Day Forecast",
                    value: "\(forecast30)",
                    tone: scoreTone(forecast30)
                ),
                metric(
                    id: "forecast-90",
                    label: "90-Day Forecast",
                    value: "\(forecast90)",
                    tone: scoreTone(forecast90)
                )
            ],
            confidence: confidence,
            riskLevel: healthScoreRiskLevel(forecast90: forecast90, dailyChange: dailyChange)
        )
    }

    // MARK: - Memory Risk Forecast

    private static func memoryRiskForecast(
        from snapshots: [HealthSnapshot],
        confidence: PredictionConfidence,
        calendar: Calendar
    ) -> PredictionCardModel {
        let (recentAvg, percentChange) = swapTrend(from: snapshots, calendar: calendar)
        let risk = memoryRiskLevel(percentChange: percentChange, recentAvgGB: recentAvg / bytesPerGigabyte)

        let summary: String
        if abs(percentChange) < 5 {
            summary = "Swap usage trend is stable."
        } else if percentChange > 0 {
            summary = "Swap usage has increased by \(Int(percentChange.rounded()))% over the last 30 days."
        } else {
            summary = "Swap usage has decreased by \(Int(abs(percentChange).rounded()))% over the last 30 days."
        }

        return PredictionCardModel(
            id: "memory",
            title: "Memory Risk Forecast",
            subtitle: "Swap usage trend and memory pressure risk",
            systemImage: "memorychip",
            displayMode: .ready,
            summary: summary,
            metrics: [
                metric(
                    id: "risk-level",
                    label: "Risk Level",
                    value: risk.rawValue,
                    tone: riskTone(risk)
                ),
                metric(
                    id: "recent-swap",
                    label: "Recent Avg Swap",
                    value: ByteFormatter.swapString(from: Int64(recentAvg.rounded())),
                    tone: .secondary
                ),
                metric(
                    id: "swap-change",
                    label: "30-Day Trend",
                    value: trendPercentString(percentChange),
                    tone: percentChange > 10 ? .warning : .positive
                )
            ],
            confidence: confidence,
            riskLevel: risk
        )
    }

    // MARK: - Thermal Risk Forecast

    private static func thermalRiskForecast(
        from snapshots: [HealthSnapshot],
        confidence: PredictionConfidence,
        calendar: Calendar
    ) -> PredictionCardModel {
        let known = snapshots.filter { $0.thermalStatus != .unknown }

        guard !known.isEmpty else {
            return unavailableCard(
                id: "thermal",
                title: "Thermal Risk Forecast",
                subtitle: "Thermal severity trend analysis",
                systemImage: "thermometer.medium",
                message: "Thermal history is unavailable for these snapshots.",
                confidence: confidence
            )
        }

        let (recentSeverity, increased) = thermalTrend(from: known, calendar: calendar)
        let risk = thermalRiskLevel(
            recentSeverity: recentSeverity,
            increased: increased,
            snapshots: known
        )

        let summary: String
        if !increased && recentSeverity < 0.75 {
            summary = "Thermal conditions have remained stable."
        } else if increased {
            summary = "Thermal severity has increased over recent scans."
        } else if recentSeverity >= 1.5 {
            summary = "Thermal conditions are elevated across recent scans."
        } else {
            summary = "Thermal conditions are generally fair with occasional variation."
        }

        return PredictionCardModel(
            id: "thermal",
            title: "Thermal Risk Forecast",
            subtitle: "Thermal severity trend analysis",
            systemImage: "thermometer.medium",
            displayMode: .ready,
            summary: summary,
            metrics: [
                metric(
                    id: "risk-level",
                    label: "Risk Level",
                    value: risk.rawValue,
                    tone: riskTone(risk)
                ),
                metric(
                    id: "recent-severity",
                    label: "Recent Avg Severity",
                    value: thermalSeverityLabel(recentSeverity),
                    tone: severityTone(recentSeverity)
                ),
                metric(
                    id: "thermal-trend",
                    label: "Trend",
                    value: increased ? "Worsening" : "Stable",
                    tone: increased ? .warning : .positive
                )
            ],
            confidence: confidence,
            riskLevel: risk
        )
    }

    // MARK: - Math Helpers

    private static func chronologicallySorted(_ snapshots: [HealthSnapshot]) -> [HealthSnapshot] {
        snapshots.sorted { $0.timestamp < $1.timestamp }
    }

    private static func linearDailyRate(
        points: [(date: Date, value: Double)],
        calendar: Calendar
    ) -> Double {
        guard let first = points.first, let last = points.last else { return 0 }
        let daySpan = max(
            1.0,
            Double(calendar.dateComponents([.day], from: first.date, to: last.date).day ?? 1)
        )
        return (last.value - first.value) / daySpan
    }

    private static func daysUntilThreshold(
        current: Int64,
        threshold: Int64,
        dailyGrowth: Double
    ) -> Int? {
        if dailyGrowth <= 0 { return nil }
        if current >= threshold { return 0 }
        let remaining = Double(threshold - current)
        return Int(ceil(remaining / dailyGrowth))
    }

    private static func monthsUntilThreshold(
        current: Double,
        threshold: Double,
        dailyDecline: Double
    ) -> Int? {
        guard dailyDecline > 0.01, current > threshold else { return nil }
        let days = (current - threshold) / dailyDecline
        return Int(ceil(days / 30.0))
    }

    private static func clampScore(_ value: Int) -> Int {
        min(100, max(0, value))
    }

    private static func swapTrend(
        from snapshots: [HealthSnapshot],
        calendar: Calendar
    ) -> (recentAvg: Double, percentChange: Double) {
        guard let latestDate = snapshots.last?.timestamp else {
            return (0, 0)
        }

        let cutoff = calendar.date(byAdding: .day, value: -30, to: latestDate) ?? latestDate
        let recent = snapshots.filter { $0.timestamp >= cutoff }
        let older = snapshots.filter { $0.timestamp < cutoff }

        let recentValues = (recent.isEmpty ? snapshots : recent).map { Double($0.swapUsedBytes) }
        let olderValues: [Double]
        if older.isEmpty {
            let midpoint = snapshots.count / 2
            olderValues = snapshots.prefix(midpoint).map { Double($0.swapUsedBytes) }
        } else {
            olderValues = older.map { Double($0.swapUsedBytes) }
        }

        let recentAvg = average(recentValues)
        let olderAvg = average(olderValues)
        let percentChange: Double
        if olderAvg > 0 {
            percentChange = ((recentAvg - olderAvg) / olderAvg) * 100
        } else {
            percentChange = recentAvg > 0 ? 100 : 0
        }

        return (recentAvg, percentChange)
    }

    private static func thermalTrend(
        from snapshots: [HealthSnapshot],
        calendar: Calendar
    ) -> (recentSeverity: Double, increased: Bool) {
        guard let latestDate = snapshots.last?.timestamp else {
            return (0, false)
        }

        let cutoff = calendar.date(byAdding: .day, value: -30, to: latestDate) ?? latestDate
        let recent = snapshots.filter { $0.timestamp >= cutoff }
        let older = snapshots.filter { $0.timestamp < cutoff }

        let recentValues = (recent.isEmpty ? snapshots : recent).map { Double(thermalSeverity($0.thermalStatus)) }
        let olderValues: [Double]
        if older.isEmpty {
            let midpoint = snapshots.count / 2
            olderValues = snapshots.prefix(midpoint).map { Double(thermalSeverity($0.thermalStatus)) }
        } else {
            olderValues = older.map { Double(thermalSeverity($0.thermalStatus)) }
        }

        let recentSeverity = average(recentValues)
        let olderSeverity = average(olderValues)
        let increased = recentSeverity > olderSeverity + 0.25

        return (recentSeverity, increased)
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

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Risk Levels

    private static func storageRiskLevel(daysUntilWarning: Int?, dailyGrowth: Double) -> PredictionRiskLevel {
        if dailyGrowth <= 0 { return .low }
        guard let daysUntilWarning else { return .low }
        if daysUntilWarning <= 30 { return .high }
        if daysUntilWarning <= 90 { return .moderate }
        return .low
    }

    private static func batteryRiskLevel(current: Double, dailyDecline: Double) -> PredictionRiskLevel {
        if current <= 80 { return .high }
        if dailyDecline > 0.05 || current <= 85 { return .moderate }
        return .low
    }

    private static func healthScoreRiskLevel(forecast90: Int, dailyChange: Double) -> PredictionRiskLevel {
        if forecast90 < 60 || dailyChange < -0.3 { return .high }
        if forecast90 < 75 || dailyChange < -0.1 { return .moderate }
        return .low
    }

    private static func memoryRiskLevel(percentChange: Double, recentAvgGB: Double) -> PredictionRiskLevel {
        if percentChange > 40 || recentAvgGB >= 6.5 { return .high }
        if percentChange > 10 || recentAvgGB >= 3.2 { return .moderate }
        return .low
    }

    private static func thermalRiskLevel(
        recentSeverity: Double,
        increased: Bool,
        snapshots: [HealthSnapshot]
    ) -> PredictionRiskLevel {
        let hasRecentCritical = snapshots.suffix(7).contains { $0.thermalStatus == .critical || $0.thermalStatus == .serious }
        if hasRecentCritical || recentSeverity >= 2 { return .high }
        if increased || recentSeverity >= 1 { return .moderate }
        return .low
    }

    // MARK: - Formatting

    private static func growthRateString(bytesPerDay: Double) -> String {
        let gbPerDay = bytesPerDay / bytesPerGigabyte
        if abs(gbPerDay) < 0.05 { return "Stable" }
        if gbPerDay >= 10 { return String(format: "%.0f GB/day", gbPerDay) }
        return String(format: "%.1f GB/day", gbPerDay)
    }

    private static func growthRateSummary(bytesPerDay: Double) -> String {
        let rate = growthRateString(bytesPerDay: bytesPerDay)
        if rate == "Stable" { return "Storage usage is stable" }
        return "Growing by \(rate)"
    }

    private static func daysValue(_ days: Int?) -> String {
        guard let days else { return "Not projected" }
        if days == 0 { return "Already reached" }
        return "In \(days) days"
    }

    private static func daysSummary(_ days: Int?, label: String) -> String {
        guard let days else { return "\(label): not projected" }
        if days == 0 { return "\(label): already reached" }
        return "\(label) in \(days) days"
    }

    private static func monthsValue(_ months: Int?) -> String {
        guard let months else { return "Not projected" }
        return "In \(months) months"
    }

    private static func trendPercentString(_ percent: Double) -> String {
        if abs(percent) < 1 { return "Stable" }
        let sign = percent > 0 ? "+" : "−"
        return "\(sign)\(Int(abs(percent).rounded()))%"
    }

    private static func thermalSeverityLabel(_ severity: Double) -> String {
        switch severity {
        case ..<0.5: "Nominal"
        case ..<1.5: "Fair"
        case ..<2.5: "Serious"
        default: "Critical"
        }
    }

    // MARK: - Card Builders

    private static func metric(
        id: String,
        label: String,
        value: String,
        tone: PredictionSemanticTone = .primary
    ) -> PredictionMetricRow {
        PredictionMetricRow(id: id, label: label, value: value, tone: tone)
    }

    private static func unavailableCard(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        message: String,
        confidence: PredictionConfidence
    ) -> PredictionCardModel {
        PredictionCardModel(
            id: id,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            displayMode: .unavailable(message),
            summary: nil,
            metrics: [],
            confidence: confidence,
            riskLevel: nil
        )
    }

    // MARK: - Semantic Tones

    private static func daysTone(_ days: Int?) -> PredictionSemanticTone {
        guard let days else { return .secondary }
        if days == 0 { return .negative }
        if days <= 30 { return .negative }
        if days <= 90 { return .warning }
        return .positive
    }

    private static func monthsTone(_ months: Int?) -> PredictionSemanticTone {
        guard let months else { return .secondary }
        if months <= 6 { return .negative }
        if months <= 12 { return .warning }
        return .positive
    }

    private static func batteryHealthTone(_ health: Double) -> PredictionSemanticTone {
        if health >= 85 { return .positive }
        if health >= 80 { return .warning }
        return .negative
    }

    private static func scoreTone(_ score: Int) -> PredictionSemanticTone {
        if score >= 80 { return .positive }
        if score >= 60 { return .warning }
        return .negative
    }

    private static func riskTone(_ risk: PredictionRiskLevel) -> PredictionSemanticTone {
        switch risk {
        case .low: .positive
        case .moderate: .warning
        case .high: .negative
        }
    }

    private static func severityTone(_ severity: Double) -> PredictionSemanticTone {
        if severity < 0.75 { return .positive }
        if severity < 1.5 { return .warning }
        return .negative
    }
}
