import Foundation

enum StorageStatus: String, Equatable, Codable {
    case healthy
    case warning
    case critical

    static func from(freePercentage: Double) -> StorageStatus {
        switch freePercentage {
        case 0.20...: return .healthy
        case 0.10..<0.20: return .warning
        default: return .critical
        }
    }

    var healthScore: Int {
        switch self {
        case .healthy: 92
        case .warning: 62
        case .critical: 28
        }
    }
}
