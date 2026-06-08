import SwiftUI

struct RecommendationsCard: View {
    let recommendations: [Recommendation]

    private var sortedRecommendations: [Recommendation] {
        recommendations.sorted { $0.priority < $1.priority }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
            if recommendations.isEmpty {
                Text("No recommendations at this time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .macCheckPanel()
            } else {
                ForEach(sortedRecommendations) { recommendation in
                    recommendationRow(recommendation)
                }
            }
        }
    }

    // MARK: - Private

    private func recommendationRow(_ recommendation: Recommendation) -> some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(recommendation.priority.color)
                .frame(width: 4)

            Image(systemName: recommendation.category.iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(recommendation.priority.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: MacCheckTheme.Spacing.xs) {
                    Text(recommendation.title)
                        .font(.body.weight(.semibold))

                    Spacer(minLength: MacCheckTheme.Spacing.sm)

                    priorityBadge(recommendation.priority)
                    categoryBadge(recommendation.category)
                }

                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(MacCheckTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .fill(recommendation.priority.color.opacity(recommendation.priority == .high ? 0.06 : 0.03))
        }
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(
                    recommendation.priority == .high
                        ? recommendation.priority.color.opacity(0.2)
                        : Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }

    private func priorityBadge(_ priority: RecommendationPriority) -> some View {
        Text(priority.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.12))
            .foregroundStyle(priority.color)
            .clipShape(Capsule())
    }

    private func categoryBadge(_ category: RecommendationCategory) -> some View {
        Text(category.displayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.06))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }
}

// MARK: - Display Helpers

private extension RecommendationPriority {
    var displayName: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }
}

private extension RecommendationCategory {
    var displayName: String {
        switch self {
        case .battery: "Battery"
        case .storage: "Storage"
        case .memory: "Memory"
        case .startup: "Startup"
        case .thermal: "Thermal"
        case .general: "General"
        }
    }

    var iconName: String {
        switch self {
        case .battery: "battery.100"
        case .storage: "internaldrive"
        case .memory: "memorychip"
        case .startup: "power.circle"
        case .thermal: "thermometer.medium"
        case .general: "heart.text.square"
        }
    }
}

#Preview {
    let battery = BatteryService().fetchBatteryInfo()
    let storage = StorageService().fetchStorageInfo()
    let memory = MemoryService().fetchMemoryInfo()
    let thermal = ThermalService().fetchThermalInfo()
    let startup = StartupAppsService().fetchStartupApps()
    let scores = HealthScoreService().calculateScore(
        battery: battery,
        storage: storage,
        memory: memory,
        startupApps: startup.apps,
        thermal: thermal
    )
    let systemInfo = SystemInfoService().fetchSystemInfo()
    var report = HealthReport(
        generatedAt: Date(),
        scoreBreakdown: scores,
        systemInfo: systemInfo,
        battery: battery,
        storage: storage,
        memory: memory,
        thermal: thermal,
        startupApps: startup.apps,
        isStartupDataLimited: startup.isLimitedData,
        insights: [],
        recommendations: []
    )
    report = HealthReport(
        generatedAt: report.generatedAt,
        scoreBreakdown: scores,
        systemInfo: systemInfo,
        battery: battery,
        storage: storage,
        memory: memory,
        thermal: thermal,
        startupApps: startup.apps,
        isStartupDataLimited: startup.isLimitedData,
        insights: InsightsService().generateInsights(from: report),
        recommendations: []
    )
    let recommendations = RecommendationsService().generateRecommendations(from: report)

    return RecommendationsCard(recommendations: recommendations)
        .padding()
        .frame(width: 720)
}
