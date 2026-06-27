import Foundation

/// Tracks sidebar navigation and triggers the in-app App Store review prompt once.
@MainActor
final class AppStoreReviewManager {

    static let shared = AppStoreReviewManager()

    private enum Keys {
        static let navigationCount = "review.navigation_count"
        static let hasRequestedReview = "review.has_requested"
    }

    private let navigationThreshold = 10
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Records a sidebar tab change. Returns `true` when the review prompt should be shown.
    @discardableResult
    func recordNavigation() -> Bool {
        guard !defaults.bool(forKey: Keys.hasRequestedReview) else { return false }

        let count = defaults.integer(forKey: Keys.navigationCount) + 1
        defaults.set(count, forKey: Keys.navigationCount)

        guard count >= navigationThreshold else { return false }

        defaults.set(true, forKey: Keys.hasRequestedReview)
        return true
    }
}
