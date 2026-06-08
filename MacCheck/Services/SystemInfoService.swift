import Darwin
import Foundation
import IOKit

/// Reads Mac device identity using IOKit, sysctl, and system_profiler.
final class SystemInfoService {

    func fetchSystemInfo() -> SystemInfo {
        let hardwareProfile = readHardwareProfile()
        let modelIdentifier = readSysctlString(name: "hw.model") ?? "Unknown"
        let macOSVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let serialNumber = readPlatformSerialNumber()
            ?? hardwareProfile["Serial Number (system)"]
            ?? hardwareProfile["Serial Number"]

        let modelName = hardwareProfile["Model Name"]
            ?? hardwareProfile["Model Name:"]
            ?? formattedModelName(from: modelIdentifier)

        let chipName = hardwareProfile["Chip"]
            ?? readSysctlString(name: "machdep.cpu.brand_string")

        return SystemInfo(
            serialNumber: serialNumber,
            modelName: modelName,
            modelIdentifier: hardwareProfile["Model Identifier"] ?? modelIdentifier,
            macOSVersion: macOSVersion,
            chipName: chipName?.isEmpty == false ? chipName : nil
        )
    }

    // MARK: - IOKit

    private func readPlatformSerialNumber() -> String? {
        let matching = IOServiceMatching("IOPlatformExpertDevice")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard
            let value = IORegistryEntryCreateCFProperty(
                service,
                kIOPlatformSerialNumberKey as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? String,
            !value.isEmpty
        else {
            return nil
        }

        return value
    }

    // MARK: - system_profiler

    private func readHardwareProfile() -> [String: String] {
        guard let output = runSystemProfiler() else { return [:] }
        return parseKeyValueLines(from: output)
    }

    private func runSystemProfiler() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType"]

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
        return String(data: data, encoding: .utf8)
    }

    private func parseKeyValueLines(from text: String) -> [String: String] {
        var result: [String: String] = [:]

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let separatorIndex = trimmed.firstIndex(of: ":") else { continue }

            let key = String(trimmed[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: separatorIndex)...])
                .trimmingCharacters(in: .whitespaces)

            guard !key.isEmpty, !value.isEmpty else { continue }
            result[key] = value
        }

        return result
    }

    // MARK: - sysctl

    private func readSysctlString(name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else {
            return nil
        }

        return String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedModelName(from identifier: String) -> String {
        identifier.replacingOccurrences(of: ",", with: " ")
    }
}
