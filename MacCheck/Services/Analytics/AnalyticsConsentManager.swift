import Combine
import Foundation

/// Persists analytics consent in UserDefaults.
@MainActor
final class AnalyticsConsentManager: ObservableObject {

    static let consentDecisionMadeKey = "analytics.consent_decision_made"
    static let enabledKey = "analytics.enabled"

    @Published private(set) var hasMadeDecision: Bool
    @Published private(set) var isEnabled: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasMadeDecision = defaults.bool(forKey: Self.consentDecisionMadeKey)
        isEnabled = defaults.bool(forKey: Self.enabledKey)
    }

    func allowAnalytics() {
        persist(decisionMade: true, enabled: true)
    }

    func declineAnalytics() {
        persist(decisionMade: true, enabled: false)
    }

    func setEnabled(_ enabled: Bool) {
        guard hasMadeDecision else { return }
        persist(decisionMade: true, enabled: enabled)
    }

    /// Clears consent state so the first-launch prompt appears again. DEBUG / testing only.
    func resetForTesting() {
        defaults.removeObject(forKey: Self.consentDecisionMadeKey)
        defaults.removeObject(forKey: Self.enabledKey)
        hasMadeDecision = false
        isEnabled = false
        analyticsDebugLog("consent reset for testing")
    }

    private func persist(decisionMade: Bool, enabled: Bool) {
        defaults.set(decisionMade, forKey: Self.consentDecisionMadeKey)
        defaults.set(enabled, forKey: Self.enabledKey)
        hasMadeDecision = decisionMade
        isEnabled = enabled
        analyticsDebugLog("consent decision made: \(decisionMade)")
        analyticsDebugLog("enabled: \(enabled)")
    }
}

#if DEBUG
func analyticsDebugLog(_ message: String) {
    print("[Analytics] \(message)")
}
#else
func analyticsDebugLog(_ message: String) {}
#endif
