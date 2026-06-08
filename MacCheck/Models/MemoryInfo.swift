import Foundation

/// OS-reported memory pressure when available via `kern.memorystatus_vm_pressure_level`.
enum MemoryPressureLevel: String, Codable {
    case normal
    case warning
    case critical
}

/// Derived app-facing memory health status.
enum MemoryStatus: String, Codable {
    case healthy
    case warning
    case critical

    var displayName: String {
        switch self {
        case .healthy: "Normal"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }

    static func resolve(
        systemMemoryPressure: MemoryPressureLevel?,
        usedPercentage: Double,
        swapUsedBytes: Int64,
        totalMemoryBytes: Int64
    ) -> MemoryStatus {
        if systemMemoryPressure == .critical {
            return .critical
        }

        let swapRatio = totalMemoryBytes > 0
            ? Double(swapUsedBytes) / Double(totalMemoryBytes)
            : 0

        var severity = 0

        if systemMemoryPressure == .warning {
            severity = max(severity, 1)
        }

        if usedPercentage >= 0.85 || swapRatio >= 0.40 {
            severity = max(severity, 2)
        } else if usedPercentage >= 0.70 || swapRatio >= 0.20 {
            severity = max(severity, 1)
        }

        switch severity {
        case 2: return .critical
        case 1: return .warning
        default: return .healthy
        }
    }
}

struct MemoryInfo: Equatable {
    let totalMemoryBytes: Int64
    let usedMemoryBytes: Int64
    let freeMemoryBytes: Int64
    let cachedFilesBytes: Int64
    let swapUsedBytes: Int64
    let systemMemoryPressure: MemoryPressureLevel?
    let status: MemoryStatus

    var usedPercentage: Double {
        guard totalMemoryBytes > 0 else { return 0 }
        return Double(usedMemoryBytes) / Double(totalMemoryBytes)
    }

    var freePercentage: Double {
        guard totalMemoryBytes > 0 else { return 0 }
        return Double(freeMemoryBytes) / Double(totalMemoryBytes)
    }
}
