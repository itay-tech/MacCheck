import Foundation

enum BatteryCondition: String, Codable {
    case normal
    case replaceSoon
    case replaceNow
    case serviceRecommended
    case unknown
    /// This Mac has no internal battery (desktop Mac).
    case notAvailable
}

struct BatteryInfo: Equatable {
    /// Whether this Mac has an internal battery.
    let hasBattery: Bool
    /// Current charge level (0–100). Nil when unavailable or not applicable.
    let currentChargePercentage: Double?
    /// Battery health (0–100). Nil when full-charge mAh capacity is unavailable or no battery exists.
    let healthPercentage: Double?
    let designCapacityMah: Int
    /// Current full-charge capacity in mAh. Nil when only a normalized percentage is available.
    let maxCapacityMah: Int?
    /// Current charge in mAh. Nil when only a normalized percentage is available.
    let currentCapacityMah: Int?
    let cycleCount: Int
    let isCharging: Bool
    let condition: BatteryCondition
    let ageEstimateMonths: Int
    /// Reserved for Pro predictions — populated when real telemetry is available.
    let replacementPredictionMonths: Int?

    /// Ratio of current full-charge capacity to original design capacity.
    var capacityRetentionRatio: Double? {
        guard let maxCapacityMah, designCapacityMah > 0 else { return nil }
        return Double(maxCapacityMah) / Double(designCapacityMah)
    }
}
