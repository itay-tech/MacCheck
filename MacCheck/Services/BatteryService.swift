import Foundation
import IOKit
import IOKit.ps

/// Reads real battery telemetry from macOS via IOKit and the IOPS power-source API.
final class BatteryService {

    #if DEBUG
    /// Set to `true` locally to trace raw registry values and resolved metrics.
    private static let isDebugLoggingEnabled = false
    #endif

    func fetchBatteryInfo() -> BatteryInfo {
        let smartBattery = readSmartBatteryProperties()
        let powerSource = readInternalPowerSourceInfo()
        let hasBattery = resolveHasBattery(smartBattery: smartBattery, powerSource: powerSource)

        guard hasBattery else {
            return makeNoBatteryInfo()
        }

        let designCapacityMah = smartBattery?.designCapacity ?? 0
        let maxCapacityMah = resolveMaxCapacityMah(from: smartBattery)
        let currentCapacityMah = resolveCurrentCapacityMah(from: smartBattery)

        let healthPercentage = calculateHealthPercentage(
            maxCapacityMah: maxCapacityMah,
            designCapacityMah: designCapacityMah
        )

        let currentChargePercentage = calculateCurrentChargePercentage(
            normalizedChargePercentage: smartBattery?.normalizedChargePercentage,
            currentCapacityMah: currentCapacityMah,
            maxCapacityMah: maxCapacityMah
        )

        let isCharging = resolveIsCharging(
            powerSource: powerSource,
            smartBattery: smartBattery
        )

        let condition = resolveBatteryCondition(
            healthPercentage: healthPercentage,
            permanentFailure: smartBattery?.permanentFailure ?? false
        )

        let cycleCount = smartBattery?.cycleCount ?? 0

        #if DEBUG
        logDebug(
            smartBattery: smartBattery,
            hasBattery: hasBattery,
            designCapacityMah: designCapacityMah,
            maxCapacityMah: maxCapacityMah,
            currentCapacityMah: currentCapacityMah,
            healthPercentage: healthPercentage,
            currentChargePercentage: currentChargePercentage,
            cycleCount: cycleCount,
            isCharging: isCharging,
            condition: condition
        )
        #endif

        return BatteryInfo(
            hasBattery: true,
            currentChargePercentage: currentChargePercentage,
            healthPercentage: healthPercentage,
            designCapacityMah: designCapacityMah,
            maxCapacityMah: maxCapacityMah,
            currentCapacityMah: currentCapacityMah,
            cycleCount: cycleCount,
            isCharging: isCharging,
            condition: condition,
            ageEstimateMonths: estimateAgeMonths(cycleCount: cycleCount),
            replacementPredictionMonths: nil
        )
    }

    // MARK: - Battery Presence

    private func resolveHasBattery(
        smartBattery: SmartBatteryProperties?,
        powerSource: [String: Any]?
    ) -> Bool {
        smartBattery != nil || powerSource != nil
    }

    private func makeNoBatteryInfo() -> BatteryInfo {
        BatteryInfo(
            hasBattery: false,
            currentChargePercentage: nil,
            healthPercentage: nil,
            designCapacityMah: 0,
            maxCapacityMah: nil,
            currentCapacityMah: nil,
            cycleCount: 0,
            isCharging: false,
            condition: .notAvailable,
            ageEstimateMonths: 0,
            replacementPredictionMonths: nil
        )
    }

    // MARK: - IOKit

    private struct SmartBatteryProperties {
        let designCapacity: Int
        let maxCapacity: Int
        let currentCapacity: Int
        let appleRawMaxCapacity: Int?
        let appleRawCurrentCapacity: Int?
        let cycleCount: Int
        let isCharging: Bool
        let permanentFailure: Bool

        /// `CurrentCapacity` when macOS reports it as a 0–100 charge percentage.
        var normalizedChargePercentage: Double? {
            guard (0...100).contains(currentCapacity) else { return nil }
            return Double(currentCapacity)
        }
    }

    private func readSmartBatteryProperties() -> SmartBatteryProperties? {
        let matching = IOServiceMatching("AppleSmartBattery")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard let designCapacity = copyRegistryInt(service: service, key: "DesignCapacity") else {
            return nil
        }

        return SmartBatteryProperties(
            designCapacity: designCapacity,
            maxCapacity: copyRegistryInt(service: service, key: "MaxCapacity") ?? 0,
            currentCapacity: copyRegistryInt(service: service, key: "CurrentCapacity") ?? 0,
            appleRawMaxCapacity: copyRegistryInt(service: service, key: "AppleRawMaxCapacity"),
            appleRawCurrentCapacity: copyRegistryInt(service: service, key: "AppleRawCurrentCapacity"),
            cycleCount: copyRegistryInt(service: service, key: "CycleCount") ?? 0,
            isCharging: copyRegistryBool(service: service, key: "IsCharging") ?? false,
            permanentFailure: copyRegistryBool(service: service, key: "PermanentFailureStatus") ?? false
        )
    }

    private func copyRegistryInt(service: io_registry_entry_t, key: String) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }
        return (value as? NSNumber)?.intValue
    }

    private func copyRegistryBool(service: io_registry_entry_t, key: String) -> Bool? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let boolean = value as? Bool {
            return boolean
        }
        return nil
    }

    // MARK: - IOPS

    private func readInternalPowerSourceInfo() -> [String: Any]? {
        guard
            let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(snapshot, source)?
                    .takeUnretainedValue() as? [String: Any]
            else {
                continue
            }

            let isPresent = description[kIOPSIsPresentKey as String] as? Bool ?? false
            let transportType = description[kIOPSTransportTypeKey as String] as? String

            guard isPresent, transportType == kIOPSInternalBatteryType as String else {
                continue
            }

            return description
        }

        return nil
    }

    // MARK: - Capacity Resolution

    private func resolveMaxCapacityMah(from smartBattery: SmartBatteryProperties?) -> Int? {
        guard let smartBattery else { return nil }

        if let raw = smartBattery.appleRawMaxCapacity, raw > 0 {
            return raw
        }

        if smartBattery.maxCapacity > 100 {
            return smartBattery.maxCapacity
        }

        return nil
    }

    private func resolveCurrentCapacityMah(from smartBattery: SmartBatteryProperties?) -> Int? {
        guard let smartBattery else { return nil }

        if let raw = smartBattery.appleRawCurrentCapacity, raw > 0 {
            return raw
        }

        if smartBattery.currentCapacity > 100 {
            return smartBattery.currentCapacity
        }

        return nil
    }

    // MARK: - Metrics

    private func calculateHealthPercentage(
        maxCapacityMah: Int?,
        designCapacityMah: Int
    ) -> Double? {
        guard
            designCapacityMah > 100,
            let maxCapacityMah,
            maxCapacityMah > 100
        else {
            return nil
        }

        return min(100, max(0, Double(maxCapacityMah) / Double(designCapacityMah) * 100))
    }

    private func calculateCurrentChargePercentage(
        normalizedChargePercentage: Double?,
        currentCapacityMah: Int?,
        maxCapacityMah: Int?
    ) -> Double? {
        if let normalizedChargePercentage {
            return min(100, max(0, normalizedChargePercentage))
        }

        guard
            let currentCapacityMah,
            let maxCapacityMah,
            maxCapacityMah > 0
        else {
            return nil
        }

        return min(100, max(0, Double(currentCapacityMah) / Double(maxCapacityMah) * 100))
    }

    private func resolveIsCharging(
        powerSource: [String: Any]?,
        smartBattery: SmartBatteryProperties?
    ) -> Bool {
        powerSource?[kIOPSIsChargingKey as String] as? Bool
            ?? smartBattery?.isCharging
            ?? false
    }

    private func resolveBatteryCondition(
        healthPercentage: Double?,
        permanentFailure: Bool
    ) -> BatteryCondition {
        if permanentFailure {
            return .replaceNow
        }

        guard let healthPercentage else {
            return .unknown
        }

        switch healthPercentage {
        case 80...: return .normal
        case 60..<80: return .serviceRecommended
        case 40..<60: return .replaceSoon
        case 0..<40: return .replaceNow
        default: return .unknown
        }
    }

    private func estimateAgeMonths(cycleCount: Int) -> Int {
        guard cycleCount > 0 else { return 0 }
        return max(1, cycleCount / 12)
    }

    // MARK: - Debug

    #if DEBUG
    private func logDebug(
        smartBattery: SmartBatteryProperties?,
        hasBattery: Bool,
        designCapacityMah: Int,
        maxCapacityMah: Int?,
        currentCapacityMah: Int?,
        healthPercentage: Double?,
        currentChargePercentage: Double?,
        cycleCount: Int,
        isCharging: Bool,
        condition: BatteryCondition
    ) {
        guard Self.isDebugLoggingEnabled else { return }

        print("========== BATTERY DEBUG ==========")
        print("Has Battery: \(hasBattery)")
        if let smartBattery {
            print("DesignCapacity: \(smartBattery.designCapacity)")
            print("MaxCapacity: \(smartBattery.maxCapacity)")
            print("CurrentCapacity: \(smartBattery.currentCapacity)")
            print("AppleRawMaxCapacity: \(String(describing: smartBattery.appleRawMaxCapacity))")
            print("AppleRawCurrentCapacity: \(String(describing: smartBattery.appleRawCurrentCapacity))")
        }
        print("Resolved maxCapacityMah: \(String(describing: maxCapacityMah))")
        print("Resolved currentCapacityMah: \(String(describing: currentCapacityMah))")
        print("Health Percentage: \(String(describing: healthPercentage))")
        print("Current Charge Percentage: \(String(describing: currentChargePercentage))")
        print("Cycle Count: \(cycleCount)")
        print("Is Charging: \(isCharging)")
        print("Condition: \(condition)")
        print("Design Capacity (mAh): \(designCapacityMah)")
        print("===================================")
    }
    #endif
}
