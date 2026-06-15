import Foundation
import PostHog

/// Configures PostHog once, attaches global properties, and sends analytics events when consent allows.
@MainActor
final class PostHogService {

    static let shared = PostHogService()

    private static let projectToken = "phc_zwpa846GVk7xXi7pkHeM2EoF7WyacMcPSxtyGtBYRoYW"
    private static let host = "https://us.i.posthog.com"

    private var isConfigured = false
    private weak var consentManager: AnalyticsConsentManager?

    private init() {}

    func bind(consentManager: AnalyticsConsentManager) {
        self.consentManager = consentManager
    }

    var isAnalyticsAllowed: Bool {
        consentManager?.isEnabled == true
    }

    /// Sets up PostHog when analytics is enabled. Sends `app_opened` on cold start when requested.
    func activate(isPro: Bool, sendAppOpened: Bool = true) {
        guard isAnalyticsAllowed else { return }

        configureIfNeeded()
        updateGlobalProperties(isPro: isPro)

        if PostHogSDK.shared.isOptOut() {
            PostHogSDK.shared.optIn()
        }

        if sendAppOpened {
            track(.appOpened)
        }
    }

    /// Stops sending future events without tearing down the SDK instance.
    func deactivate() {
        guard isConfigured else { return }
        PostHogSDK.shared.optOut()
    }

    func updateGlobalProperties(isPro: Bool) {
        guard isConfigured, isAnalyticsAllowed else { return }

        let properties = AnalyticsDeviceProperties.globalProperties(isPro: isPro)
        PostHogSDK.shared.register(properties)
        logGlobalProperties(properties)
    }

    private func logGlobalProperties(_ properties: [String: Any]) {
        #if DEBUG
        print("[PostHog] Global properties:")
        print("app_version=\(properties["app_version"] ?? "—")")
        print("build_number=\(properties["build_number"] ?? "—")")
        print("macos_version=\(properties["macos_version"] ?? "—")")
        print("mac_model=\(properties["mac_model"] ?? "—")")
        print("is_pro=\(properties["is_pro"] ?? "—")")
        #endif
    }

    func track(_ event: AnalyticsEvent) {
        guard isAnalyticsAllowed else {
            analyticsDebugLog("skipped: \(event.name) because analytics disabled")
            return
        }

        configureIfNeeded()
        guard isConfigured else { return }

        if PostHogSDK.shared.isOptOut() {
            analyticsDebugLog("skipped: \(event.name) because analytics disabled")
            return
        }

        analyticsDebugLog("event: \(event.name)")
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        #if DEBUG
        print("[PostHog] setup started")
        print("[PostHog] host: \(Self.host)")
        #endif

        let config = PostHogConfig(
            projectToken: Self.projectToken,
            host: Self.host
        )
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        #if DEBUG
        config.debug = true
        #endif

        PostHogSDK.shared.setup(config)
        isConfigured = true

        #if DEBUG
        print("[PostHog] setup complete")
        #endif
    }
}
