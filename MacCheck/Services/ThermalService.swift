import Foundation

/// Reads thermal state from the public ProcessInfo API.
final class ThermalService {

    func fetchThermalInfo() -> ThermalInfo {
        let status = readThermalStatus()
        return ThermalInfo(
            status: status,
            explanation: explanation(for: status)
        )
    }

    // MARK: - Private

    private func readThermalStatus() -> ThermalStatus {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .unknown
        }
    }

    private func explanation(for status: ThermalStatus) -> String {
        switch status {
        case .nominal:
            "Your Mac's thermal state is normal. Performance should not be limited by heat."
        case .fair:
            "Thermal load is elevated. macOS may reduce performance slightly to manage temperature."
        case .serious:
            "Your Mac is running hot. Performance may be noticeably reduced until temperatures improve."
        case .critical:
            "Thermal state is critical. Close demanding apps and improve airflow to prevent throttling."
        case .unknown:
            "Thermal state could not be determined on this Mac."
        }
    }
}
