import Foundation

struct StorageInfo: Equatable {
    let totalBytes: Int64
    let usedBytes: Int64
    let availableBytes: Int64
    let snapshots: [StorageSnapshot]
    let analysis: StorageAnalysis

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    var freePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(availableBytes) / Double(totalBytes)
    }

    var latestSnapshot: StorageSnapshot? {
        snapshots.sorted { $0.date > $1.date }.first
    }
}
