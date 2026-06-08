import Foundation

enum InsightSeverity: String, Codable, Comparable {
    case info
    case warning
    case critical

    var sortOrder: Int {
        switch self {
        case .critical: 0
        case .warning: 1
        case .info: 2
        }
    }

    static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

struct HealthInsight: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let severity: InsightSeverity
}
