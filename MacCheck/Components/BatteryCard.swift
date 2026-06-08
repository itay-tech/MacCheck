import SwiftUI

struct BatteryCard: View {
    let battery: BatteryInfo

    var body: some View {
        if battery.hasBattery {
            batteryMetricsCard
        } else {
            noBatteryCard
        }
    }

    // MARK: - Private

    private var batteryMetricsCard: some View {
        MetricKPICard(
            icon: "battery.100percent",
            title: "Battery",
            tint: batteryTint,
            badge: battery.isCharging ? "Charging" : "On Battery",
            primaryValue: chargePrimaryValue,
            primarySuffix: chargePrimarySuffix,
            caption: batteryCaption,
            progress: chargeProgress,
            footerMetrics: [
                (label: "Health", value: battery.healthDisplayValue),
                (label: "Condition", value: battery.condition.displayName),
                (label: "Capacity", value: battery.chargeCapacityDisplayValue),
                (label: "Design", value: battery.designCapacityDisplayValue)
            ]
        )
    }

    private var noBatteryCard: some View {
        MetricKPICard(
            icon: "battery.100percent",
            title: "Battery",
            tint: .secondary,
            badge: "Desktop Mac",
            primaryValue: "—",
            primarySuffix: nil,
            caption: "No internal battery",
            progress: 0,
            footerMetrics: [
                (label: "Health", value: "N/A"),
                (label: "Condition", value: battery.condition.displayName),
                (label: "Capacity", value: "N/A"),
                (label: "Design", value: "N/A")
            ]
        )
    }

    private var chargePrimaryValue: String {
        guard let currentChargePercentage = battery.currentChargePercentage else { return "—" }
        return "\(Int(currentChargePercentage))"
    }

    private var chargePrimarySuffix: String? {
        battery.currentChargePercentage == nil ? nil : "%"
    }

    private var batteryCaption: String {
        "Health \(battery.healthDisplayValue) · \(battery.cycleCount) cycles"
    }

    private var chargeProgress: Double {
        (battery.currentChargePercentage ?? 0) / 100
    }

    private var batteryTint: Color {
        guard let currentChargePercentage = battery.currentChargePercentage else { return .secondary }
        switch currentChargePercentage {
        case 20...: return .green
        case 10..<20: return .orange
        default: return .red
        }
    }
}

private extension BatteryInfo {
    var healthDisplayValue: String {
        guard let healthPercentage else { return "Unknown" }
        return "\(Int(healthPercentage.rounded()))%"
    }

    var chargeCapacityDisplayValue: String {
        guard let currentCapacityMah, let maxCapacityMah else { return "Unknown" }
        return "\(currentCapacityMah)/\(maxCapacityMah) mAh"
    }

    var designCapacityDisplayValue: String {
        guard designCapacityMah > 0 else { return "Unknown" }
        return "\(designCapacityMah) mAh"
    }
}

private extension BatteryCondition {
    var displayName: String {
        switch self {
        case .normal: "Normal"
        case .replaceSoon: "Replace Soon"
        case .replaceNow: "Replace Now"
        case .serviceRecommended: "Service"
        case .unknown: "Unknown"
        case .notAvailable: "Not Available"
        }
    }
}

#Preview {
    BatteryCard(battery: BatteryService().fetchBatteryInfo())
        .padding()
        .frame(width: 320)
}
