import Foundation

// MARK: - Confidence & Risk

enum PredictionConfidence: String, Equatable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum PredictionRiskLevel: String, Equatable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

enum PredictionSemanticTone: Equatable {
    case primary
    case positive
    case warning
    case negative
    case secondary
    case accent
}

// MARK: - Summary Model

struct PredictionSummaryModel: Equatable {
    let title: String
    let outlookSentence: String
    let primaryRiskSentence: String
    let confidence: PredictionConfidence
    let tone: PredictionSemanticTone

    static let defaultTitle = "Mac Outlook"
}

// MARK: - Card Model

enum PredictionCardDisplayMode: Equatable {
    case ready
    case unavailable(String)
}

struct PredictionMetricRow: Identifiable, Equatable {
    let id: String
    let label: String
    let value: String
    let tone: PredictionSemanticTone
}

struct PredictionCardModel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let displayMode: PredictionCardDisplayMode
    let summary: String?
    let metrics: [PredictionMetricRow]
    let confidence: PredictionConfidence
    let riskLevel: PredictionRiskLevel?

    var isReady: Bool {
        if case .ready = displayMode { return true }
        return false
    }
}

// MARK: - Page Model

struct PredictionsPageData: Equatable {
    let snapshotCount: Int
    let hasEnoughHistory: Bool
    let storageForecast: PredictionCardModel
    let batteryForecast: PredictionCardModel
    let healthScoreForecast: PredictionCardModel
    let memoryRiskForecast: PredictionCardModel
    let thermalRiskForecast: PredictionCardModel

    static let insufficientHistoryMessage =
        "Predictions become available after more history is collected."

    var cards: [PredictionCardModel] {
        [
            storageForecast,
            batteryForecast,
            healthScoreForecast,
            memoryRiskForecast,
            thermalRiskForecast
        ]
    }

    static func insufficientHistory(snapshotCount: Int) -> PredictionsPageData {
        PredictionsPageData(
            snapshotCount: snapshotCount,
            hasEnoughHistory: false,
            storageForecast: .placeholder(id: "storage"),
            batteryForecast: .placeholder(id: "battery"),
            healthScoreForecast: .placeholder(id: "health-score"),
            memoryRiskForecast: .placeholder(id: "memory"),
            thermalRiskForecast: .placeholder(id: "thermal")
        )
    }
}

private extension PredictionCardModel {
    static func placeholder(id: String) -> PredictionCardModel {
        PredictionCardModel(
            id: id,
            title: "",
            subtitle: "",
            systemImage: "questionmark",
            displayMode: .unavailable(""),
            summary: nil,
            metrics: [],
            confidence: .low,
            riskLevel: nil
        )
    }
}
