import Foundation

enum ThermalStatus: String, Codable, Equatable {
    case nominal
    case fair
    case serious
    case critical
    case unknown

    var displayName: String {
        switch self {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        case .unknown: "Unknown"
        }
    }
}

struct ThermalInfo: Equatable {
    let status: ThermalStatus
    let explanation: String
}
