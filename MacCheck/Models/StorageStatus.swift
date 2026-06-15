import Foundation
import SwiftUI

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

    var displayName: String {
        switch self {
        case .healthy: "Healthy"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }

    /// Semantic tint for status badges and progress bars — aligned with Memory KPI cards.
    var semanticColor: Color {
        switch self {
        case .healthy: .green
        case .warning: .orange
        case .critical: .red
        }
    }
}
