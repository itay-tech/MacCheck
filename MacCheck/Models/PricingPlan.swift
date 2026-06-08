import Foundation

/// Display and StoreKit-ready pricing for the lifetime Pro purchase.
struct PricingPlan: Equatable {
    let title: String
    let price: String
    let subtitle: String
    let productID: String
    let includedFeatures: [String]
}

enum PricingPlanCatalog {
    static let lifetime = PricingPlan(
        title: "MacCheck Pro Lifetime",
        price: "$19.99",
        subtitle: "One-time purchase",
        productID: StoreKitManager.lifetimeProductID,
        includedFeatures: [
            "Predictions",
            "Advanced Charts",
            "Extended History",
            "History Statistics",
            "Future Pro Features"
        ]
    )
}
