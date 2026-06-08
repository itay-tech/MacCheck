import Foundation

enum RecommendationPriority: String, Codable, Comparable {
    case low
    case medium
    case high

    var sortOrder: Int {
        switch self {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }

    static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case battery
    case storage
    case memory
    case startup
    case thermal
    case general
}

struct Recommendation: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: RecommendationCategory
}
