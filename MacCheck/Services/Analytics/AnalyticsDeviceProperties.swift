import Darwin
import Foundation

enum AnalyticsDeviceProperties {

    static var appVersion: String {
        AppMetadata.version
    }

    static var buildNumber: String {
        AppMetadata.buildNumber
    }

    static var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    static var macModel: String {
        readSysctlString(name: "hw.model") ?? "unknown"
    }

    static func globalProperties(isPro: Bool) -> [String: Any] {
        [
            "app_version": appVersion,
            "build_number": buildNumber,
            "macos_version": macOSVersion,
            "mac_model": macModel,
            "is_pro": isPro
        ]
    }

    private static func readSysctlString(name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else {
            return nil
        }

        let value = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
