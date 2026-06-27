import Darwin
import Foundation

/// Reads real memory telemetry from macOS via `host_statistics64` and `sysctl`.
final class MemoryService {

    #if DEBUG
    /// Set to `true` locally to trace swap parsing.
    private static let isDebugLoggingEnabled = false
    #endif

    func fetchMemoryInfo(preferFastSwapRead: Bool = false) -> MemoryInfo {
        let totalMemoryBytes = Int64(ProcessInfo.processInfo.physicalMemory)
        let vmStats = readVMStatistics()
        let swapUsedBytes = preferFastSwapRead ? readSwapUsageFromStruct() : readSwapUsage()
        let systemMemoryPressure = readSystemMemoryPressure()

        let pageSize = Int64(vm_page_size)

        let usedMemoryBytes = vmStats.map { Int64($0.usedPages) * pageSize } ?? 0
        let freeMemoryBytes = vmStats.map { Int64($0.freePages) * pageSize } ?? 0
        let cachedFilesBytes = vmStats.map { Int64($0.cachedPages) * pageSize } ?? 0

        let clampedUsedMemoryBytes = min(max(0, usedMemoryBytes), totalMemoryBytes)
        let clampedFreeMemoryBytes = min(max(0, freeMemoryBytes), totalMemoryBytes)
        let clampedCachedFilesBytes = max(0, cachedFilesBytes)

        let usedPercentage = totalMemoryBytes > 0
            ? Double(clampedUsedMemoryBytes) / Double(totalMemoryBytes)
            : 0

        let status = MemoryStatus.resolve(
            systemMemoryPressure: systemMemoryPressure,
            usedPercentage: usedPercentage,
            swapUsedBytes: swapUsedBytes,
            totalMemoryBytes: totalMemoryBytes
        )

        return MemoryInfo(
            totalMemoryBytes: totalMemoryBytes,
            usedMemoryBytes: clampedUsedMemoryBytes,
            freeMemoryBytes: clampedFreeMemoryBytes,
            cachedFilesBytes: clampedCachedFilesBytes,
            swapUsedBytes: swapUsedBytes,
            systemMemoryPressure: systemMemoryPressure,
            status: status
        )
    }

    // MARK: - VM Statistics

    private struct VMStatistics {
        let usedPages: UInt64
        let freePages: UInt64
        let cachedPages: UInt64
    }

    private func readVMStatistics() -> VMStatistics? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let usedPages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)

        let freePages = UInt64(stats.free_count)
        let cachedPages = UInt64(stats.external_page_count)

        return VMStatistics(
            usedPages: usedPages,
            freePages: freePages,
            cachedPages: cachedPages
        )
    }

    // MARK: - System Pressure

    private func readSystemMemoryPressure() -> MemoryPressureLevel? {
        var level = Int32(0)
        var size = MemoryLayout<Int32>.size

        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else {
            return nil
        }

        switch level {
        case 2: return .critical
        case 1: return .warning
        case 0: return .normal
        default: return nil
        }
    }

    // MARK: - Swap

    private func readSwapUsage() -> Int64 {
        if let parsed = parseSwapUsageFromSysctlOutput() {
            logSwapDebug(parsed)
            return parsed.bytes
        }

        let fallbackBytes = readSwapUsageFromStruct()
        #if DEBUG
        if Self.isDebugLoggingEnabled {
            print("rawSwapUsageLine: (struct fallback)")
            print("parsedUsedSwapValue: n/a")
            print("parsedSwapUnit: n/a")
            print("finalSwapUsedBytes: \(fallbackBytes)")
        }
        #endif
        return fallbackBytes
    }

    private func parseSwapUsageFromSysctlOutput() -> SwapUsageParser.ParsedSwapUsage? {
        guard let rawLine = runSysctlSwapUsageCommand() else {
            return nil
        }
        return SwapUsageParser.parse(from: rawLine)
    }

    private func runSysctlSwapUsageCommand() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/sysctl")
        process.arguments = ["vm.swapusage"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fallback when textual sysctl output is unavailable. `xsu_used` is already in bytes.
    private func readSwapUsageFromStruct() -> Int64 {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size

        guard sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0) == 0 else {
            return 0
        }

        return Int64(swapUsage.xsu_used)
    }

    // MARK: - Debug

    private func logSwapDebug(_ parsed: SwapUsageParser.ParsedSwapUsage) {
        #if DEBUG
        guard Self.isDebugLoggingEnabled else { return }
        print("rawSwapUsageLine: \(parsed.rawLine)")
        print("parsedUsedSwapValue: \(parsed.usedValue)")
        print("parsedSwapUnit: \(parsed.unit)")
        print("finalSwapUsedBytes: \(parsed.bytes)")
        #endif
    }
}
