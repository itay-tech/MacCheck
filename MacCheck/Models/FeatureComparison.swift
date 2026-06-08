import Foundation

enum FeatureAvailability: Equatable {
    case included
    case excluded
    case limit(String)
    case comingSoon
}

struct FeatureComparisonRow: Identifiable, Equatable {
    let id: String
    let name: String
    let free: FeatureAvailability
    let pro: FeatureAvailability
}

/// Limits referenced by the paywall and aligned with app behavior where applicable.
enum ProPlanLimits {
    static let freeRecentSnapshots = HistoryViewModel.freeSnapshotLimit
    static let proRecentSnapshots = 100
}

struct PaywallBenefit: Identifiable, Equatable {
    let id: String
    let iconName: String
    let title: String
    let description: String
}

enum FeatureComparisonCatalog {

    static let rows: [FeatureComparisonRow] = [
        FeatureComparisonRow(id: "dashboard", name: "Dashboard", free: .included, pro: .included),
        FeatureComparisonRow(id: "health-score", name: "Current Health Score", free: .included, pro: .included),
        FeatureComparisonRow(id: "basic-history", name: "Basic History", free: .included, pro: .included),
        FeatureComparisonRow(id: "trend-analysis", name: "Trend Analysis", free: .included, pro: .included),
        FeatureComparisonRow(
            id: "recent-snapshots",
            name: "Recent Snapshots",
            free: .limit("\(ProPlanLimits.freeRecentSnapshots)"),
            pro: .limit("\(ProPlanLimits.proRecentSnapshots)")
        ),
        FeatureComparisonRow(id: "history-statistics", name: "History Statistics", free: .excluded, pro: .included),
        FeatureComparisonRow(id: "advanced-charts", name: "Advanced Charts", free: .excluded, pro: .included),
        FeatureComparisonRow(id: "predictions", name: "Predictions", free: .excluded, pro: .included),
        FeatureComparisonRow(id: "reports", name: "Reports", free: .comingSoon, pro: .comingSoon),
        FeatureComparisonRow(id: "future-features", name: "Future Features", free: .excluded, pro: .included)
    ]

    static let benefits: [PaywallBenefit] = [
        PaywallBenefit(
            id: "predictions",
            iconName: "sparkles",
            title: "Predictions",
            description: "Forecast storage usage, battery degradation and future Mac health trends."
        ),
        PaywallBenefit(
            id: "advanced-charts",
            iconName: "chart.xyaxis.line",
            title: "Advanced Charts",
            description: "Visualize long-term performance and health changes over time."
        ),
        PaywallBenefit(
            id: "history-statistics",
            iconName: "chart.bar.doc.horizontal",
            title: "History Statistics",
            description: "Track records, trends and historical milestones."
        ),
        PaywallBenefit(
            id: "extended-history",
            iconName: "clock.arrow.circlepath",
            title: "Extended History",
            description: "Access more snapshots and long-term monitoring."
        )
    ]
}
