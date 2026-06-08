import Foundation

enum ProFeature: String, CaseIterable, Identifiable {
    case pdfExport
    case history
    case predictions
    case usedMacInspection
    case advancedInsights
    case advancedCharts

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pdfExport: "PDF Export"
        case .history: "Health History"
        case .predictions: "Predictions"
        case .usedMacInspection: "Used Mac Inspection"
        case .advancedInsights: "Advanced Insights"
        case .advancedCharts: "Advanced Charts"
        }
    }

    var description: String {
        switch self {
        case .pdfExport:
            "Export a detailed health report as a shareable PDF."
        case .history:
            "Track your Mac's health score and metrics over time."
        case .predictions:
            "See when storage may fill up and when battery replacement is likely."
        case .usedMacInspection:
            "Run a comprehensive checklist before buying or selling a used Mac."
        case .advancedInsights:
            "Deep analysis with actionable recommendations tailored to your Mac."
        case .advancedCharts:
            "Unlock Pro to view advanced health charts."
        }
    }

    var iconName: String {
        switch self {
        case .pdfExport: "doc.richtext"
        case .history: "chart.line.uptrend.xyaxis"
        case .predictions: "sparkles"
        case .usedMacInspection: "magnifyingglass.circle"
        case .advancedInsights: "lightbulb.max"
        case .advancedCharts: "chart.xyaxis.line"
        }
    }

    /// Whether the feature requires an active Pro entitlement.
    var requiresPro: Bool {
        switch self {
        case .pdfExport, .history, .predictions, .usedMacInspection, .advancedInsights, .advancedCharts:
            true
        }
    }

    /// Features surfaced in upgrade prompts and paywall marketing.
    static let paywallHighlights: [ProFeature] = [
        .predictions,
        .advancedCharts,
        .history,
        .pdfExport
    ]
}
