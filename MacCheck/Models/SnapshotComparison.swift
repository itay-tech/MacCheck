import Foundation

/// Point-in-time deltas between two health snapshots.
struct SnapshotComparison: Equatable {
    let current: HealthSnapshot
    let previous: HealthSnapshot

    var scoreDifference: Int {
        current.overallHealthScore - previous.overallHealthScore
    }

    var batteryDifference: Int? {
        optionalDifference(current: current.batteryScore, previous: previous.batteryScore)
    }

    var storageDifference: Int {
        current.storageScore - previous.storageScore
    }

    var memoryDifference: Int {
        current.memoryScore - previous.memoryScore
    }

    var startupDifference: Int {
        current.startupScore - previous.startupScore
    }

    var thermalDifference: Int? {
        optionalDifference(current: current.thermalScore, previous: previous.thermalScore)
    }

    // MARK: - Private

    private func optionalDifference(current: Int?, previous: Int?) -> Int? {
        guard let current, let previous else { return nil }
        return current - previous
    }
}
