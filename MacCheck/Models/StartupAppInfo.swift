import Foundation

struct StartupAppInfo: Identifiable, Equatable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    /// Whether the item is enabled at login/launch. Nil when the source does not expose status.
    let isEnabled: Bool?

    var statusDisplayName: String {
        switch isEnabled {
        case true: "Enabled"
        case false: "Disabled"
        case nil: "Unknown"
        }
    }
}

struct StartupAppsFetchResult: Equatable {
    let apps: [StartupAppInfo]
    let isLimitedData: Bool

    static let limitedEmpty = StartupAppsFetchResult(apps: [], isLimitedData: true)
}
