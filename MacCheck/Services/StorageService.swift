import Foundation

/// Reads real storage capacity for the main system volume via Foundation APIs.
final class StorageService {

    func fetchStorageInfo() -> StorageInfo {
        let capacity = readSystemVolumeCapacity()
        let analysis = makeCurrentAnalysis(freePercentage: capacity.freePercentage)
        let snapshot = makeCurrentSnapshot(capacity: capacity)

        return StorageInfo(
            totalBytes: capacity.totalBytes,
            usedBytes: capacity.usedBytes,
            availableBytes: capacity.freeBytes,
            snapshots: [snapshot],
            analysis: analysis
        )
    }

    // MARK: - Volume Reading

    private struct VolumeCapacity {
        let totalBytes: Int64
        let freeBytes: Int64

        var usedBytes: Int64 {
            max(0, totalBytes - freeBytes)
        }

        var usedPercentage: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(usedBytes) / Double(totalBytes)
        }

        var freePercentage: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(freeBytes) / Double(totalBytes)
        }
    }

    private func readSystemVolumeCapacity() -> VolumeCapacity {
        if let capacity = readVolumeCapacity(at: URL(fileURLWithPath: "/")) {
            return capacity
        }

        if let capacity = readVolumeCapacity(at: URL(fileURLWithPath: NSHomeDirectory())) {
            return capacity
        }

        return VolumeCapacity(totalBytes: 0, freeBytes: 0)
    }

    private func readVolumeCapacity(at url: URL) -> VolumeCapacity? {
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])

            guard
                let total = values.volumeTotalCapacity,
                let available = values.volumeAvailableCapacityForImportantUsage,
                total > 0
            else {
                return nil
            }

            let totalBytes = Int64(total)
            let freeBytes = min(Int64(available), totalBytes)

            return VolumeCapacity(totalBytes: totalBytes, freeBytes: freeBytes)
        } catch {
            return readVolumeCapacityLegacy(at: url.path)
        }
    }

    private func readVolumeCapacityLegacy(at path: String) -> VolumeCapacity? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            guard
                let total = attributes[.systemSize] as? NSNumber,
                let free = attributes[.systemFreeSize] as? NSNumber,
                total.int64Value > 0
            else {
                return nil
            }

            let totalBytes = total.int64Value
            let freeBytes = min(free.int64Value, totalBytes)
            return VolumeCapacity(totalBytes: totalBytes, freeBytes: freeBytes)
        } catch {
            return nil
        }
    }

    // MARK: - Placeholders for Future History

    private func makeCurrentAnalysis(freePercentage: Double) -> StorageAnalysis {
        let status = StorageStatus.from(freePercentage: freePercentage)

        return StorageAnalysis(
            weeklyGrowthBytes: 0,
            monthlyGrowthBytes: 0,
            daysUntilFull: nil,
            topGrowingCategory: .other,
            healthScore: status.healthScore,
            status: status
        )
    }

    private func makeCurrentSnapshot(capacity: VolumeCapacity) -> StorageSnapshot {
        StorageSnapshot(
            id: UUID(),
            date: Date(),
            usedBytes: capacity.usedBytes,
            totalBytes: capacity.totalBytes,
            categoryBreakdown: [:]
        )
    }
}
