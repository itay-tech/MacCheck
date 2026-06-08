import Foundation

enum ReportType: String, Equatable {
    case health
    case usedMacInspection
}

enum InspectionGrade: String, Equatable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"

    var summaryLabel: String {
        switch self {
        case .a: "Excellent"
        case .b: "Good"
        case .c: "Fair"
        case .d: "Poor"
        }
    }

    static func from(healthScore: Int) -> InspectionGrade {
        switch healthScore {
        case 90...: .a
        case 80..<90: .b
        case 70..<80: .c
        default: .d
        }
    }
}

struct ReportMetricRow: Identifiable, Equatable {
    let id: String
    let label: String
    let value: String
}

struct ReportCardModel: Identifiable, Equatable {
    var id: String { type.rawValue }

    let type: ReportType
    let title: String
    let subtitle: String
    let systemImage: String
    let summary: String?
    let metrics: [ReportMetricRow]
    let generateButtonTitle: String
    let isReady: Bool
    let unavailableMessage: String?
}

struct ReportsOverviewModel: Equatable {
    let currentHealthScore: Int?
}

struct ReportsPageData: Equatable {
    let overview: ReportsOverviewModel
    let healthReport: ReportCardModel
    let inspectionReport: ReportCardModel

    static let empty = ReportsPageData(
        overview: ReportsOverviewModel(currentHealthScore: nil),
        healthReport: .placeholder(type: .health),
        inspectionReport: .placeholder(type: .usedMacInspection)
    )
}

private extension ReportCardModel {
    static func placeholder(type: ReportType) -> ReportCardModel {
        ReportCardModel(
            type: type,
            title: "",
            subtitle: "",
            systemImage: "questionmark",
            summary: nil,
            metrics: [],
            generateButtonTitle: "",
            isReady: false,
            unavailableMessage: nil
        )
    }
}
