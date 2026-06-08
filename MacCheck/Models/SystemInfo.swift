import Foundation

struct SystemInfo: Equatable {
    let serialNumber: String?
    let modelName: String
    let modelIdentifier: String
    let macOSVersion: String
    let chipName: String?

    var serialNumberDisplay: String {
        guard let serialNumber, !serialNumber.isEmpty else {
            return "Serial unavailable"
        }
        return serialNumber
    }
}
