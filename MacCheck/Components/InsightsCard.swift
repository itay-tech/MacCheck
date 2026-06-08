import SwiftUI

struct InsightsCard: View {
    let insights: [HealthInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
            if insights.isEmpty {
                Text("No insights available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .macCheckPanel()
            } else {
                ForEach(insights) { insight in
                    insightRow(insight)
                }
            }
        }
    }

    // MARK: - Private

    private func insightRow(_ insight: HealthInsight) -> some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(insight.severity.color)
                .frame(width: 4)

            Image(systemName: insight.severity.iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(insight.severity.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(insight.title)
                        .font(.body.weight(.semibold))
                    Spacer(minLength: MacCheckTheme.Spacing.sm)
                    severityBadge(insight.severity)
                }

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MacCheckTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .fill(insight.severity.color.opacity(0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }

    private func severityBadge(_ severity: InsightSeverity) -> some View {
        Text(severity.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.color.opacity(0.12))
            .foregroundStyle(severity.color)
            .clipShape(Capsule())
    }
}

private extension InsightSeverity {
    var displayName: String {
        switch self {
        case .info: "Info"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }

    var iconName: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: .blue
        case .warning: .orange
        case .critical: .red
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
    let report = HealthReport(
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

    return InsightsCard(insights: InsightsService().generateInsights(from: report))
        .padding()
        .frame(width: 720)
}
