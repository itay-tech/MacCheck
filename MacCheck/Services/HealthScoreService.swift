import Foundation

/// Calculates an overall Mac health score from real system telemetry.
struct HealthScoreService {

    /// Subsystem weights for the overall score. Battery and storage/memory carry the most
    /// user-visible impact; startup load is a minor contributor.
    private enum Weight {
        static let battery = 0.30
        static let storage = 0.25
        static let memory = 0.25
        static let thermal = 0.15
        static let startup = 0.05
    }

    /// Prevents a single failing subsystem from being masked by a high overall average.
    private enum CriticalGate {
        static let subsystemThreshold = 30
        static let cappedOverallScore = 69
    }

    /// Neutral fallback when a battery exists but health metrics cannot be measured reliably.
    private enum BatteryFallback {
        static let unavailableHealthScore = 75
    }

    func calculateScore(
        battery: BatteryInfo,
        storage: StorageInfo,
        memory: MemoryInfo,
        startupApps: [StartupAppInfo],
        thermal: ThermalInfo
    ) -> HealthScoreBreakdown {
        let batteryScore = scoreBatteryIfAvailable(battery)
        let storageScore = scoreStorage(storage)
        let memoryScore = scoreMemory(memory)
        let startupScore = scoreStartupApps(startupApps)
        let thermalScore = scoreThermalIfAvailable(thermal)

        let weighted = weightedOverallScore(
            batteryScore: batteryScore,
            storageScore: storageScore,
            memoryScore: memoryScore,
            startupScore: startupScore,
            thermalScore: thermalScore
        )

        var overallScore = clamp(Int(weighted.rounded()))
        overallScore = applyCriticalGate(
            overallScore: overallScore,
            batteryScore: batteryScore,
            storageScore: storageScore,
            memoryScore: memoryScore,
            startupScore: startupScore,
            thermalScore: thermalScore
        )

        return HealthScoreBreakdown(
            overallScore: overallScore,
            batteryScore: batteryScore,
            storageScore: storageScore,
            memoryScore: memoryScore,
            startupScore: startupScore,
            thermalScore: thermalScore
        )
    }

    // MARK: - Overall Composition

    private func weightedOverallScore(
        batteryScore: Int?,
        storageScore: Int,
        memoryScore: Int,
        startupScore: Int,
        thermalScore: Int?
    ) -> Double {
        var components: [(weight: Double, score: Double)] = [
            (Weight.storage, Double(storageScore)),
            (Weight.memory, Double(memoryScore)),
            (Weight.startup, Double(startupScore))
        ]

        if let batteryScore {
            components.append((Weight.battery, Double(batteryScore)))
        }

        if let thermalScore {
            components.append((Weight.thermal, Double(thermalScore)))
        }

        let totalWeight = components.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }

        // Excluded subsystems have their weight redistributed proportionally across
        // the remaining measured categories (e.g. no battery on desktop Macs).
        return components.reduce(0) { partial, component in
            partial + (component.score * component.weight / totalWeight)
        }
    }

    private func applyCriticalGate(
        overallScore: Int,
        batteryScore: Int?,
        storageScore: Int,
        memoryScore: Int,
        startupScore: Int,
        thermalScore: Int?
    ) -> Int {
        var measuredScores = [storageScore, memoryScore, startupScore]

        if let batteryScore {
            measuredScores.append(batteryScore)
        }

        if let thermalScore {
            measuredScores.append(thermalScore)
        }

        guard measuredScores.contains(where: { $0 <= CriticalGate.subsystemThreshold }) else {
            return overallScore
        }

        return min(overallScore, CriticalGate.cappedOverallScore)
    }

    // MARK: - Battery

    private func scoreBatteryIfAvailable(_ battery: BatteryInfo) -> Int? {
        guard battery.hasBattery else { return nil }

        guard let health = battery.healthPercentage else {
            return BatteryFallback.unavailableHealthScore
        }

        if health >= 60 {
            return clamp(Int(health.rounded()))
        }

        let normalized = health / 60.0
        return clamp(Int((normalized * normalized * 60).rounded()))
    }

    // MARK: - Storage

    private func scoreStorage(_ storage: StorageInfo) -> Int {
        let freePercentage = storage.freePercentage

        switch StorageStatus.from(freePercentage: freePercentage) {
        case .healthy:
            let headroom = min(1, max(0, (freePercentage - 0.20) / 0.80))
            return clamp(Int((85 + headroom * 15).rounded()))

        case .warning:
            let position = (freePercentage - 0.10) / 0.10
            return clamp(Int((50 + position * 34).rounded()))

        case .critical:
            let position = min(1, max(0, freePercentage / 0.10))
            return clamp(Int((position * 45).rounded()))
        }
    }

    // MARK: - Memory

    private func scoreMemory(_ memory: MemoryInfo) -> Int {
        var score = 100

        switch memory.status {
        case .healthy: break
        case .warning: score -= 18
        case .critical: score -= 40
        }

        let swapRatio = memory.totalMemoryBytes > 0
            ? Double(memory.swapUsedBytes) / Double(memory.totalMemoryBytes)
            : 0

        if swapRatio >= 0.50 {
            score -= 35
        } else if swapRatio >= 0.25 {
            score -= 20
        } else if swapRatio >= 0.10 {
            score -= 10
        } else if swapRatio > 0 {
            score -= Int((swapRatio * 40).rounded())
        }

        return clamp(score)
    }

    // MARK: - Startup

    private func scoreStartupApps(_ apps: [StartupAppInfo]) -> Int {
        let enabledCount = apps.filter { $0.isEnabled != false }.count

        switch enabledCount {
        case 0...2: return 100
        case 3...5: return 88
        case 6...8: return 76
        case 9...12: return 64
        case 13...16: return 52
        default: return clamp(100 - enabledCount * 3)
        }
    }

    // MARK: - Thermal

    private func scoreThermalIfAvailable(_ thermal: ThermalInfo) -> Int? {
        switch thermal.status {
        case .nominal: return 100
        case .fair: return 75
        case .serious: return 45
        case .critical: return 20
        case .unknown: return nil
        }
    }

    // MARK: - Helpers

    private func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
