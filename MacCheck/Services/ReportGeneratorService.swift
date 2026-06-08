import Foundation

/// Builds report card presentation models from live app data.
enum ReportGeneratorService {

    static func buildPageData(report: HealthReport?) -> ReportsPageData {
        ReportsPageData(
            overview: ReportsOverviewModel(currentHealthScore: report?.overallScore),
            healthReport: healthReportCard(report: report),
            inspectionReport: inspectionReportCard(report: report)
        )
    }

    // MARK: - Cards

    private static func healthReportCard(report: HealthReport?) -> ReportCardModel {
        guard let report else {
            return unavailableCard(
                type: .health,
                title: "Health Report",
                subtitle: "Complete system health report",
                systemImage: "heart.text.square",
                buttonTitle: "Generate Health Report",
                message: "Run a scan first."
            )
        }

        return ReportCardModel(
            type: .health,
            title: "Health Report",
            subtitle: "Complete system health report",
            systemImage: "heart.text.square",
            summary: "Professional PDF with system info, health scores, insights, and recommendations.",
            metrics: [
                metric("score", "Health Score", "\(report.overallScore)"),
                metric("grade", "Health Grade", HealthScoreColor.label(for: report.overallScore)),
                metric("battery", "Battery Health", batteryHealthLabel(report.battery)),
                metric("storage", "Storage Status", storageStatusLabel(report.storage)),
                metric("memory", "Memory Status", report.memory.status.displayName),
                metric("thermal", "Thermal Status", report.thermal.status.displayName)
            ],
            generateButtonTitle: "Generate Health Report",
            isReady: true,
            unavailableMessage: nil
        )
    }

    private static func inspectionReportCard(report: HealthReport?) -> ReportCardModel {
        guard let report else {
            return unavailableCard(
                type: .usedMacInspection,
                title: "Used Mac Inspection",
                subtitle: "Certificate-style report for buying or selling",
                systemImage: "magnifyingglass.circle",
                buttonTitle: "Generate Inspection Report",
                message: "Run a scan first."
            )
        }

        let grade = InspectionGrade.from(healthScore: report.overallScore)

        return ReportCardModel(
            type: .usedMacInspection,
            title: "Used Mac Inspection",
            subtitle: "Certificate-style report for buying or selling",
            systemImage: "magnifyingglass.circle",
            summary: "Certification PDF with inspection grade, battery data, and final assessment.",
            metrics: [
                metric("score", "Current Score", "\(report.overallScore)"),
                metric("grade", "Inspection Grade", "\(grade.rawValue) — \(grade.summaryLabel)"),
                metric("battery", "Battery Health", batteryHealthLabel(report.battery)),
                metric("cycles", "Cycle Count", cycleCountLabel(report.battery)),
                metric("thermal", "Thermal Status", report.thermal.status.displayName)
            ],
            generateButtonTitle: "Generate Inspection Report",
            isReady: true,
            unavailableMessage: nil
        )
    }

    // MARK: - Helpers

    private static func unavailableCard(
        type: ReportType,
        title: String,
        subtitle: String,
        systemImage: String,
        buttonTitle: String,
        message: String
    ) -> ReportCardModel {
        ReportCardModel(
            type: type,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            summary: nil,
            metrics: [],
            generateButtonTitle: buttonTitle,
            isReady: false,
            unavailableMessage: message
        )
    }

    private static func metric(_ id: String, _ label: String, _ value: String) -> ReportMetricRow {
        ReportMetricRow(id: id, label: label, value: value)
    }

    private static func batteryHealthLabel(_ battery: BatteryInfo) -> String {
        guard battery.hasBattery, let health = battery.healthPercentage else {
            return "N/A"
        }
        return "\(Int(health.rounded()))%"
    }

    private static func cycleCountLabel(_ battery: BatteryInfo) -> String {
        guard battery.hasBattery else { return "N/A" }
        return "\(battery.cycleCount)"
    }

    private static func storageStatusLabel(_ storage: StorageInfo) -> String {
        StorageStatus.from(freePercentage: storage.freePercentage).rawValue.capitalized
    }
}
