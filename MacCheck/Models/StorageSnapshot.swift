import Foundation

enum StorageCategory: String, Codable, CaseIterable, Identifiable {
    case applications
    case documents
    case photos
    case system
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .applications: "Applications"
        case .documents: "Documents"
        case .photos: "Photos"
        case .system: "System"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .applications: "app.fill"
        case .documents: "doc.fill"
        case .photos: "photo.fill"
        case .system: "gearshape.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

struct StorageSnapshot: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let usedBytes: Int64
    let totalBytes: Int64
    let categoryBreakdown: [StorageCategory: Int64]

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}
