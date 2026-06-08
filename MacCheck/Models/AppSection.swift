import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case history
    case charts
    case predictions
    case reports
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .history: "History"
        case .charts: "Charts"
        case .predictions: "Predictions"
        case .reports: "Reports"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .history: "clock.arrow.circlepath"
        case .charts: "chart.xyaxis.line"
        case .predictions: "sparkles"
        case .reports: "doc.richtext"
        case .settings: "gearshape"
        }
    }
}
