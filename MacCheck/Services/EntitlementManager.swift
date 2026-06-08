import Combine
import Foundation

/// Feature access derived exclusively from verified StoreKit ownership.
@MainActor
final class EntitlementManager: ObservableObject {

    @Published private(set) var isPro = false

    func hasAccess(to feature: ProFeature) -> Bool {
        isPro
    }

    func applyOwnership(isPro: Bool) {
        self.isPro = isPro
    }
}
