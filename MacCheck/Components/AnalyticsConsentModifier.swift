import SwiftUI

struct AnalyticsConsentModifier: ViewModifier {
    @ObservedObject var consentManager: AnalyticsConsentManager
    var isPro: Bool

    @State private var showConsentAlert = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                PostHogService.shared.bind(consentManager: consentManager)

                if consentManager.hasMadeDecision {
                    if consentManager.isEnabled {
                        PostHogService.shared.activate(isPro: isPro)
                    }
                } else {
                    showConsentAlert = true
                }
            }
            .onChange(of: consentManager.isEnabled) { _, isEnabled in
                if isEnabled {
                    PostHogService.shared.activate(isPro: isPro, sendAppOpened: false)
                } else {
                    PostHogService.shared.deactivate()
                }
            }
            .onChange(of: isPro) { _, newValue in
                PostHogService.shared.updateGlobalProperties(isPro: newValue)
            }
            .alert("Help Improve MacCheck", isPresented: $showConsentAlert) {
                Button("Allow Analytics") {
                    consentManager.allowAnalytics()
                    PostHogService.shared.activate(isPro: isPro)
                }
                Button("Not Now") {
                    consentManager.declineAnalytics()
                }
            } message: {
                Text(
                    "Help improve MacCheck by sharing anonymous usage analytics.\n\nNo personal files, documents, serial numbers, health history, or personal information are collected.\n\nYou can change this at any time in Settings."
                )
            }
    }
}

extension View {
    func analyticsConsent(
        consentManager: AnalyticsConsentManager,
        isPro: Bool
    ) -> some View {
        modifier(AnalyticsConsentModifier(consentManager: consentManager, isPro: isPro))
    }
}
