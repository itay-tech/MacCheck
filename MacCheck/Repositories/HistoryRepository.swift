import Foundation

/// Selects where history snapshots are loaded from during development.
enum HistoryDataSource {
    case real
    case mock2Days
    case mock7Days
    case mock30Days
    case mock90Days

    fileprivate var mockFilename: String? {
        switch self {
        case .real: nil
        case .mock2Days: "history_2_days.json"
        case .mock7Days: "history_7_days.json"
        case .mock30Days: "history_30_days.json"
        case .mock90Days: "history_90_days.json"
        }
    }
}

enum HistoryRepositoryError: Error, LocalizedError {
    case directoryCreationFailed
    case encodingFailed
    case decodingFailed
    case mockFileNotFound

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            "MacCheck could not create the history folder."
        case .encodingFailed:
            "MacCheck could not save history data."
        case .decodingFailed:
            "MacCheck could not read saved history."
        case .mockFileNotFound:
            "MacCheck could not find the selected mock history file."
        }
    }
}

/// Persists health snapshots as JSON in Application Support.
final class HistoryRepository {

    /// Change this value to switch between real and mock history during development.
    static var dataSource: HistoryDataSource = .real

    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = (appSupport ?? fileManager.temporaryDirectory)
            .appendingPathComponent("MacCheck", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("health_snapshots.json", isDirectory: false)
    }

    func loadSnapshots() throws -> [HealthSnapshot] {
        switch Self.dataSource {
        case .real:
            return try loadProductionSnapshots()
        case .mock2Days, .mock7Days, .mock30Days, .mock90Days:
            return try loadMockSnapshots(for: Self.dataSource)
        }
    }

    func saveSnapshots(_ snapshots: [HealthSnapshot]) throws {
        guard Self.dataSource == .real else { return }

        try ensureDirectoryExists()

        let data: Data
        do {
            data = try encoder.encode(snapshots)
        } catch {
            throw HistoryRepositoryError.encodingFailed
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw error
        }
    }

    // MARK: - Private

    private func loadProductionSnapshots() throws -> [HealthSnapshot] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }

        return try decodeSnapshotData(data)
    }

    private func loadMockSnapshots(for source: HistoryDataSource) throws -> [HealthSnapshot] {
        guard let filename = source.mockFilename else {
            return []
        }

        guard let mockURL = mockFileURL(named: filename) else {
            throw HistoryRepositoryError.mockFileNotFound
        }

        let data = try Data(contentsOf: mockURL)
        guard !data.isEmpty else { return [] }

        return try decodeSnapshotData(data)
    }

    private func mockFileURL(named filename: String) -> URL? {
        let resourceName = (filename as NSString).deletingPathExtension
        let resourceExtension = (filename as NSString).pathExtension.isEmpty ? "json" : (filename as NSString).pathExtension

        if let bundledURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExtension,
            subdirectory: "MockData"
        ) {
            return bundledURL
        }

        if let bundledURL = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) {
            return bundledURL
        }

        let projectMockURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("MockData/\(filename)")

        if fileManager.fileExists(atPath: projectMockURL.path) {
            return projectMockURL
        }

        return nil
    }

    private func decodeSnapshotData(_ data: Data) throws -> [HealthSnapshot] {
        if let snapshots = try? decoder.decode([HealthSnapshot].self, from: data) {
            return snapshots
        }

        let recovered = decodeSnapshotsIndividually(from: data)
        if recovered.isEmpty {
            throw HistoryRepositoryError.decodingFailed
        }
        return recovered
    }

    private func decodeSnapshotsIndividually(from data: Data) -> [HealthSnapshot] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        let snapshotObjects: [Any]
        if let array = json as? [Any] {
            snapshotObjects = array
        } else if let dictionary = json as? [String: Any] {
            snapshotObjects = [dictionary]
        } else {
            return []
        }

        var snapshots: [HealthSnapshot] = []
        snapshots.reserveCapacity(snapshotObjects.count)

        for object in snapshotObjects {
            guard JSONSerialization.isValidJSONObject(object),
                  let objectData = try? JSONSerialization.data(withJSONObject: object),
                  let snapshot = try? decoder.decode(HealthSnapshot.self, from: objectData)
            else {
                continue
            }
            snapshots.append(snapshot)
        }

        return snapshots
    }

    private func ensureDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: directory.path) {
            return
        }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw HistoryRepositoryError.directoryCreationFailed
        }
    }
}
