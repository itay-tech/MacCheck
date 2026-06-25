import Combine
import Foundation

/// Manages local health snapshot history for trends and comparisons.
final class HistoryService {

    /// One daily snapshot per calendar day, retained for up to five years.
    static let maxSnapshots = 1825

    let snapshotsDidChange = PassthroughSubject<Void, Never>()

    private(set) var lastSaveErrorMessage: String?

    private let repository: HistoryRepository
    private let calendar: Calendar
    private var snapshots: [HealthSnapshot]

    init(
        repository: HistoryRepository = HistoryRepository(),
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
        self.snapshots = Self.loadAndNormalize(from: repository, calendar: calendar)
    }

    var snapshotsFilePath: String {
        repository.snapshotsFileURL.path
    }

    // MARK: - Recording

    /// Records a snapshot after a successful report load. Replaces any snapshot from the same calendar day.
    func recordSnapshot(from report: HealthReport) throws {
        let snapshot = HealthSnapshot.from(
            report: report,
            scoreVersion: HealthSnapshot.currentScoreVersion,
            appVersion: Self.appVersion
        )

        let snapshotsBeforeSave = snapshots
        let existingSnapshotForDay = snapshots.first {
            calendar.isDate($0.timestamp, inSameDayAs: snapshot.timestamp)
        }
        let isReplacing = existingSnapshotForDay != nil

        print("[History] Snapshot save requested")
        print("[History] Snapshot date: \(snapshot.timestamp.formatted(date: .abbreviated, time: .standard))")
        print("[History] Existing snapshot for day found: \(isReplacing)")
        print("[History] Replacing snapshot: \(isReplacing)")

        snapshots.removeAll { calendar.isDate($0.timestamp, inSameDayAs: snapshot.timestamp) }
        snapshots.append(snapshot)
        snapshots.sort { $0.timestamp > $1.timestamp }

        if snapshots.count > Self.maxSnapshots {
            snapshots = Array(snapshots.prefix(Self.maxSnapshots))
        }

        do {
            try repository.saveSnapshots(snapshots)
            lastSaveErrorMessage = nil
            print("[History] Total stored snapshots: \(snapshots.count)")
            print("[History] File path: \(snapshotsFilePath)")
            snapshotsDidChange.send()
        } catch {
            snapshots = snapshotsBeforeSave
            lastSaveErrorMessage = Self.userMessage(for: error)
            throw error
        }
    }

    // MARK: - Access

    var latestSnapshot: HealthSnapshot? {
        snapshots.first
    }

    var previousSnapshot: HealthSnapshot? {
        guard snapshots.count >= 2 else { return nil }
        return snapshots[1]
    }

    var allSnapshots: [HealthSnapshot] {
        snapshots
    }

    var scoreChange: Int? {
        guard let latestSnapshot, let previousSnapshot else { return nil }
        return latestSnapshot.overallHealthScore - previousSnapshot.overallHealthScore
    }

    var scoreTrendDirection: ScoreTrendDirection {
        guard let scoreChange else { return .unavailable }
        if scoreChange > 0 { return .up }
        if scoreChange < 0 { return .down }
        return .unchanged
    }

    var hasComparableHistory: Bool {
        previousSnapshot != nil
    }

    func comparison() -> SnapshotComparison? {
        guard let latestSnapshot, let previousSnapshot else { return nil }
        return SnapshotComparison(current: latestSnapshot, previous: previousSnapshot)
    }

    /// Reloads snapshots from local storage. Use when presenting the History page.
    func reloadFromDisk() {
        snapshots = Self.loadAndNormalize(from: repository, calendar: calendar)
    }

    /// Permanently removes all stored snapshots from memory and disk.
    func clearAllSnapshots() throws {
        let snapshotsBeforeClear = snapshots
        snapshots = []

        do {
            try repository.saveSnapshots([])
            lastSaveErrorMessage = nil
            snapshotsDidChange.send()
        } catch {
            snapshots = snapshotsBeforeClear
            lastSaveErrorMessage = Self.userMessage(for: error)
            throw error
        }
    }

    // MARK: - Private

    private static func loadAndNormalize(
        from repository: HistoryRepository,
        calendar: Calendar
    ) -> [HealthSnapshot] {
        do {
            let loaded = try repository.loadSnapshots()
            return deduplicateByCalendarDay(loaded, calendar: calendar)
        } catch {
#if DEBUG
            print("[History] Failed to load snapshots: \(error.localizedDescription)")
#endif
            return []
        }
    }

    private static func deduplicateByCalendarDay(
        _ snapshots: [HealthSnapshot],
        calendar: Calendar
    ) -> [HealthSnapshot] {
        var newestByDay: [Date: HealthSnapshot] = [:]

        for snapshot in snapshots {
            let day = calendar.startOfDay(for: snapshot.timestamp)
            if let existing = newestByDay[day] {
                if snapshot.timestamp > existing.timestamp {
                    newestByDay[day] = snapshot
                }
            } else {
                newestByDay[day] = snapshot
            }
        }

        return newestByDay.values.sorted { $0.timestamp > $1.timestamp }
    }

    private static func userMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "MacCheck could not save your latest history snapshot."
    }

    private static var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
