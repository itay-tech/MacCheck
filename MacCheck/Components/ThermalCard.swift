import SwiftUI

struct ThermalCard: View {
    let thermal: ThermalInfo
    let thermalScore: Int?

    var body: some View {
        MetricKPICard(
            icon: "thermometer.medium",
            title: "Thermal",
            tint: statusColor,
            badge: thermal.status.displayName,
            primaryValue: primaryValue,
            primarySuffix: primarySuffix,
            caption: thermal.explanation,
            progress: progressValue,
            footerMetrics: footerMetrics
        )
    }

    // MARK: - Private

    private var primaryValue: String {
        guard let thermalScore else { return "—" }
        return "\(thermalScore)"
    }

    private var primarySuffix: String? {
        thermalScore == nil ? nil : "/100"
    }

    private var footerMetrics: [(label: String, value: String)] {
        if let thermalScore {
            return [
                (label: "State", value: thermal.status.displayName),
                (label: "Impact", value: HealthScoreColor.label(for: thermalScore)),
                (label: "Level", value: statusSummary),
                (label: "Score", value: "\(thermalScore)/100")
            ]
        }

        return [
            (label: "State", value: thermal.status.displayName),
            (label: "Impact", value: "Unavailable"),
            (label: "Level", value: statusSummary),
            (label: "Score", value: "Not measured")
        ]
    }

    private var statusColor: Color {
        switch thermal.status {
        case .nominal: .green
        case .fair: .orange
        case .serious: .orange
        case .critical: .red
        case .unknown: .secondary
        }
    }

    private var progressValue: Double {
        switch thermal.status {
        case .nominal: 1.0
        case .fair: 0.65
        case .serious: 0.35
        case .critical: 0.15
        case .unknown: 0.5
        }
    }

    private var statusSummary: String {
        switch thermal.status {
        case .nominal: "Normal"
        case .fair: "Elevated"
        case .serious: "Hot"
        case .critical: "Critical"
        case .unknown: "Unknown"
        }
    }
}

#Preview {
    ThermalCard(
        thermal: ThermalService().fetchThermalInfo(),
        thermalScore: 100
    )
    .padding()
    .frame(width: 320)
}
