import Foundation

/// Frozen point-in-time health metrics for history, trends, and comparisons.
struct HealthSnapshot: Identifiable, Codable, Equatable {
    static let currentScoreVersion = 1

    // MARK: - Identity

    let id: UUID
    let timestamp: Date
    let scoreVersion: Int
    let appVersion: String?

    // MARK: - Overall

    let overallHealthScore: Int

    // MARK: - Subsystem Scores

    let batteryScore: Int?
    let storageScore: Int
    let memoryScore: Int
    let startupScore: Int
    let thermalScore: Int?

    // MARK: - Battery

    let hasBattery: Bool
    let batteryHealthPercentage: Double?
    let batteryCycleCount: Int
    let batteryCurrentChargePercentage: Double?

    // MARK: - Storage

    let storageTotalBytes: Int64
    let storageUsedBytes: Int64
    let storageFreeBytes: Int64
    let storageFreePercentage: Double

    // MARK: - Memory

    let memoryTotalBytes: Int64
    let memoryUsedBytes: Int64
    let cachedFilesBytes: Int64
    let swapUsedBytes: Int64
    let memoryPressureStatus: MemoryStatus

    // MARK: - Startup

    let startupAppsCount: Int

    // MARK: - Thermal

    let thermalStatus: ThermalStatus

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case scoreVersion
        case appVersion
        case overallHealthScore
        case batteryScore
        case storageScore
        case memoryScore
        case startupScore
        case thermalScore
        case hasBattery
        case batteryHealthPercentage
        case batteryCycleCount
        case batteryCurrentChargePercentage
        case storageTotalBytes
        case storageUsedBytes
        case storageFreeBytes
        case storageFreePercentage
        case memoryTotalBytes
        case memoryUsedBytes
        case cachedFilesBytes
        case swapUsedBytes
        case memoryPressureStatus
        case startupAppsCount
        case thermalStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        scoreVersion = try container.decodeIfPresent(Int.self, forKey: .scoreVersion) ?? Self.currentScoreVersion
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        overallHealthScore = try container.decodeIfPresent(Int.self, forKey: .overallHealthScore) ?? 0
        batteryScore = try container.decodeIfPresent(Int.self, forKey: .batteryScore)
        storageScore = try container.decodeIfPresent(Int.self, forKey: .storageScore) ?? 0
        memoryScore = try container.decodeIfPresent(Int.self, forKey: .memoryScore) ?? 0
        startupScore = try container.decodeIfPresent(Int.self, forKey: .startupScore) ?? 0
        thermalScore = try container.decodeIfPresent(Int.self, forKey: .thermalScore)
        hasBattery = try container.decodeIfPresent(Bool.self, forKey: .hasBattery) ?? false
        batteryHealthPercentage = try container.decodeIfPresent(Double.self, forKey: .batteryHealthPercentage)
        batteryCycleCount = try container.decodeIfPresent(Int.self, forKey: .batteryCycleCount) ?? 0
        batteryCurrentChargePercentage = try container.decodeIfPresent(Double.self, forKey: .batteryCurrentChargePercentage)
        storageTotalBytes = try container.decodeIfPresent(Int64.self, forKey: .storageTotalBytes) ?? 0
        storageUsedBytes = try container.decodeIfPresent(Int64.self, forKey: .storageUsedBytes) ?? 0
        storageFreeBytes = try container.decodeIfPresent(Int64.self, forKey: .storageFreeBytes) ?? 0
        storageFreePercentage = try container.decodeIfPresent(Double.self, forKey: .storageFreePercentage) ?? 0
        memoryTotalBytes = try container.decodeIfPresent(Int64.self, forKey: .memoryTotalBytes) ?? 0
        memoryUsedBytes = try container.decodeIfPresent(Int64.self, forKey: .memoryUsedBytes) ?? 0
        cachedFilesBytes = try container.decodeIfPresent(Int64.self, forKey: .cachedFilesBytes) ?? 0
        swapUsedBytes = try container.decodeIfPresent(Int64.self, forKey: .swapUsedBytes) ?? 0
        memoryPressureStatus = try container.decodeIfPresent(MemoryStatus.self, forKey: .memoryPressureStatus) ?? .healthy
        startupAppsCount = try container.decodeIfPresent(Int.self, forKey: .startupAppsCount) ?? 0
        thermalStatus = try container.decodeIfPresent(ThermalStatus.self, forKey: .thermalStatus) ?? .unknown
    }

    // MARK: - Factory

    static func from(
        report: HealthReport,
        scoreVersion: Int = HealthSnapshot.currentScoreVersion,
        appVersion: String? = nil
    ) -> HealthSnapshot {
        let startupAppsCount = report.startupApps.filter { $0.isEnabled != false }.count

        return HealthSnapshot(
            id: UUID(),
            timestamp: report.generatedAt,
            scoreVersion: scoreVersion,
            appVersion: appVersion,
            overallHealthScore: report.overallScore,
            batteryScore: report.batteryScore,
            storageScore: report.storageScore,
            memoryScore: report.memoryScore,
            startupScore: report.startupScore,
            thermalScore: report.thermalScore,
            hasBattery: report.battery.hasBattery,
            batteryHealthPercentage: report.battery.healthPercentage,
            batteryCycleCount: report.battery.cycleCount,
            batteryCurrentChargePercentage: report.battery.currentChargePercentage,
            storageTotalBytes: report.storage.totalBytes,
            storageUsedBytes: report.storage.usedBytes,
            storageFreeBytes: report.storage.availableBytes,
            storageFreePercentage: report.storage.freePercentage,
            memoryTotalBytes: report.memory.totalMemoryBytes,
            memoryUsedBytes: report.memory.usedMemoryBytes,
            cachedFilesBytes: report.memory.cachedFilesBytes,
            swapUsedBytes: report.memory.swapUsedBytes,
            memoryPressureStatus: report.memory.status,
            startupAppsCount: startupAppsCount,
            thermalStatus: report.thermal.status
        )
    }

    init(
        id: UUID,
        timestamp: Date,
        scoreVersion: Int,
        appVersion: String?,
        overallHealthScore: Int,
        batteryScore: Int?,
        storageScore: Int,
        memoryScore: Int,
        startupScore: Int,
        thermalScore: Int?,
        hasBattery: Bool,
        batteryHealthPercentage: Double?,
        batteryCycleCount: Int,
        batteryCurrentChargePercentage: Double?,
        storageTotalBytes: Int64,
        storageUsedBytes: Int64,
        storageFreeBytes: Int64,
        storageFreePercentage: Double,
        memoryTotalBytes: Int64,
        memoryUsedBytes: Int64,
        cachedFilesBytes: Int64,
        swapUsedBytes: Int64,
        memoryPressureStatus: MemoryStatus,
        startupAppsCount: Int,
        thermalStatus: ThermalStatus
    ) {
        self.id = id
        self.timestamp = timestamp
        self.scoreVersion = scoreVersion
        self.appVersion = appVersion
        self.overallHealthScore = overallHealthScore
        self.batteryScore = batteryScore
        self.storageScore = storageScore
        self.memoryScore = memoryScore
        self.startupScore = startupScore
        self.thermalScore = thermalScore
        self.hasBattery = hasBattery
        self.batteryHealthPercentage = batteryHealthPercentage
        self.batteryCycleCount = batteryCycleCount
        self.batteryCurrentChargePercentage = batteryCurrentChargePercentage
        self.storageTotalBytes = storageTotalBytes
        self.storageUsedBytes = storageUsedBytes
        self.storageFreeBytes = storageFreeBytes
        self.storageFreePercentage = storageFreePercentage
        self.memoryTotalBytes = memoryTotalBytes
        self.memoryUsedBytes = memoryUsedBytes
        self.cachedFilesBytes = cachedFilesBytes
        self.swapUsedBytes = swapUsedBytes
        self.memoryPressureStatus = memoryPressureStatus
        self.startupAppsCount = startupAppsCount
        self.thermalStatus = thermalStatus
    }
}
