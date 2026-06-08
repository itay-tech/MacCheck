import Foundation

/// Synthesizes a page-level outlook from existing prediction card models.
/// Does not perform forecast calculations — presentation only.
enum PredictionSummaryBuilder {

    static func build(from page: PredictionsPageData) -> PredictionSummaryModel {
        let confidence = PredictionEngine.confidence(for: page.snapshotCount)
        let rankedRisks = rankRisks(from: page)
        let primary = rankedRisks.first

        return PredictionSummaryModel(
            title: PredictionSummaryModel.defaultTitle,
            outlookSentence: outlookSentence(from: page, rankedRisks: rankedRisks),
            primaryRiskSentence: primaryRiskSentence(for: primary),
            confidence: confidence,
            tone: outlookTone(for: rankedRisks)
        )
    }

    // MARK: - Outlook

    private static func outlookSentence(
        from page: PredictionsPageData,
        rankedRisks: [RankedRisk]
    ) -> String {
        if let months = limitingHealthyMonths(from: page) {
            if months >= 6 {
                return "Your Mac is expected to remain healthy for the next \(months) months."
            }
            if months >= 3 {
                return "Your Mac should stay healthy for roughly \(months) more months."
            }
            return "Your Mac may need attention within the next \(months) months."
        }

        let highest = rankedRisks.first?.level ?? .low
        switch highest {
        case .low:
            return "Your Mac is expected to remain healthy based on current trends."
        case .moderate:
            return "Your Mac is generally healthy, but one or more trends need monitoring."
        case .high:
            return "Your Mac may need attention in the near term based on recent trends."
        }
    }

    private static func primaryRiskSentence(for risk: RankedRisk?) -> String {
        guard let risk else {
            return "No significant risks detected across tracked metrics."
        }
        return "\(risk.displayName) is currently the biggest risk."
    }

    private static func outlookTone(for rankedRisks: [RankedRisk]) -> PredictionSemanticTone {
        guard let highest = rankedRisks.first?.level else { return .positive }
        switch highest {
        case .low: return .positive
        case .moderate: return .warning
        case .high: return .negative
        }
    }

    // MARK: - Risk Ranking

    private struct RankedRisk {
        let id: String
        let displayName: String
        let level: PredictionRiskLevel
        let weight: Int
    }

    private static func rankRisks(from page: PredictionsPageData) -> [RankedRisk] {
        let candidates: [(PredictionCardModel, String)] = [
            (page.storageForecast, "Storage growth"),
            (page.batteryForecast, "Battery health"),
            (page.healthScoreForecast, "Health score decline"),
            (page.memoryRiskForecast, "Memory pressure"),
            (page.thermalRiskForecast, "Thermal conditions")
        ]

        return candidates
            .compactMap { card, name -> RankedRisk? in
                guard card.isReady, let level = card.riskLevel else { return nil }
                var weight = riskWeight(level)
                if card.id == "storage" { weight += 1 }
                return RankedRisk(id: card.id, displayName: name, level: level, weight: weight)
            }
            .sorted { $0.weight > $1.weight }
    }

    private static func riskWeight(_ level: PredictionRiskLevel) -> Int {
        switch level {
        case .low: 1
        case .moderate: 2
        case .high: 3
        }
    }

    // MARK: - Horizon Parsing

    private static func limitingHealthyMonths(from page: PredictionsPageData) -> Int? {
        var horizons: [Int] = []

        if let days = metricIntValue(in: page.storageForecast, metricId: "days-warning") {
            horizons.append(max(1, Int(ceil(Double(days) / 30.0))))
        }

        if let months = metricIntValue(in: page.batteryForecast, metricId: "months-85") {
            horizons.append(months)
        }

        if horizons.isEmpty {
            if let days = metricIntValue(in: page.storageForecast, metricId: "days-critical") {
                horizons.append(max(1, Int(ceil(Double(days) / 30.0))))
            }
        }

        return horizons.min()
    }

    private static func metricIntValue(in card: PredictionCardModel, metricId: String) -> Int? {
        guard let metric = card.metrics.first(where: { $0.id == metricId }) else { return nil }
        return parseLeadingInteger(from: metric.value)
    }

    private static func parseLeadingInteger(from value: String) -> Int? {
        let pattern = /(\d+)/
        guard let match = value.firstMatch(of: pattern) else { return nil }
        return Int(match.1)
    }
}
