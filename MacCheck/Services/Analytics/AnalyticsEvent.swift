import Foundation

enum PaywallSource: String {
    case settings
    case history
    case charts
    case predictions
    case reports
    case unknown
}

enum AnalyticsEvent {
    case appOpened
    case tabOpened(tabName: String)
    case dashboardRefresh
    case paywallViewed(source: PaywallSource)
    case purchaseStarted
    case purchaseCompleted(productID: String)
    case purchaseFailed(errorType: String)
    case restorePurchases
    case productLoadFailed(reason: String)

    var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .tabOpened: "tab_opened"
        case .dashboardRefresh: "dashboard_refresh"
        case .paywallViewed: "paywall_viewed"
        case .purchaseStarted: "purchase_started"
        case .purchaseCompleted: "purchase_completed"
        case .purchaseFailed: "purchase_failed"
        case .restorePurchases: "restore_purchases"
        case .productLoadFailed: "product_load_failed"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .appOpened:
            [:]
        case .tabOpened(let tabName):
            ["tab_name": tabName]
        case .dashboardRefresh:
            ["source": "manual"]
        case .paywallViewed(let source):
            ["source": source.rawValue]
        case .purchaseStarted:
            [:]
        case .purchaseCompleted(let productID):
            ["product_id": productID]
        case .purchaseFailed(let errorType):
            ["error_type": errorType]
        case .restorePurchases:
            [:]
        case .productLoadFailed(let reason):
            ["reason": reason]
        }
    }
}
