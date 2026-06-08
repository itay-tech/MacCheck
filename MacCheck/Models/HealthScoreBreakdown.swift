import Foundation

struct HealthScoreBreakdown: Equatable {
    let overallScore: Int
    /// Nil when this Mac has no internal battery and battery is excluded from overall scoring.
    let batteryScore: Int?
    let storageScore: Int
    let memoryScore: Int
    let startupScore: Int
    /// Nil when thermal state is unknown and excluded from overall scoring.
    let thermalScore: Int?
}
