import Foundation

/// Named coordinate space for dashboard tooltip anchoring.
enum DashboardCoordinateSpace {
    static let root = "DashboardRoot"
}

/// Help copy for dashboard section and card tooltips.
enum DashboardHelpText: String, Equatable, Identifiable {
    case healthScore
    case battery
    case storage
    case memory
    case thermal
    case startupItems
    case insights
    case recommendations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthScore: "Health Score"
        case .battery: "Battery"
        case .storage: "Storage"
        case .memory: "Memory"
        case .thermal: "Thermal"
        case .startupItems: "Startup & Background Items"
        case .insights: "Insights"
        case .recommendations: "Recommendations"
        }
    }

    var text: String {
        switch self {
        case .healthScore:
            return """
            Overall Mac health score based on battery, storage, memory, thermal state, and startup impact.

            Weights:
            Battery 30%, Storage 25%, Memory 25%, Thermal 15%, Startup 5%.
            """
        case .battery:
            return "Battery health, cycle count, and condition compared to expected Apple battery lifespan."
        case .storage:
            return "Available disk space and storage pressure. Low free space can affect performance and updates."
        case .memory:
            return "RAM usage, memory pressure, compression, and swap activity."
        case .thermal:
            return "Current thermal condition reported by macOS. High thermal pressure may reduce performance."
        case .startupItems:
            return "Enabled login and background items that may affect startup time and system responsiveness."
        case .insights:
            return "Automatically generated observations based on current Mac health metrics."
        case .recommendations:
            return "Suggested actions that may improve performance, battery health, or overall system condition."
        }
    }
}
