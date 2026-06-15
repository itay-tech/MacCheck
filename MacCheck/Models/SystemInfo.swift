import Foundation

struct SystemInfo: Equatable {
    let serialNumber: String?
    let modelName: String
    let modelIdentifier: String
    let macOSVersion: String
    let chipName: String?
    /// Diagonal size of the built-in display in inches, when detectable.
    let screenSizeInches: Double?

    var serialNumberDisplay: String {
        guard let serialNumber, !serialNumber.isEmpty else {
            return "Serial unavailable"
        }
        return serialNumber
    }

    var displaySizeLabel: String {
        guard let screenSizeInches, screenSizeInches > 0 else {
            return "Unknown"
        }
        return String(format: "%.1f\"", screenSizeInches)
    }
}
