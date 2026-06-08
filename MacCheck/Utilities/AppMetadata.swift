import Foundation

enum AppMetadata {
    static let appName = "MacCheck"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static var healthScoreEngineVersion: Int {
        HealthSnapshot.currentScoreVersion
    }
}
