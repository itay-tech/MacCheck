import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published private(set) var snapshotCount = 0
    @Published private(set) var oldestSnapshotDate: Date?
    @Published private(set) var newestSnapshotDate: Date?
    @Published private(set) var snapshotsFilePath = ""
    @Published var showClearConfirmation = false
    @Published var showClearSuccess = false
    @Published var clearHistoryError: String?

    private let historyService: HistoryService
    private var cancellables = Set<AnyCancellable>()

    init(historyService: HistoryService) {
        self.historyService = historyService
        observeSnapshotChanges()
    }

    func refreshDataStats() {
        historyService.reloadFromDisk()
        let snapshots = historyService.allSnapshots
        snapshotCount = snapshots.count
        newestSnapshotDate = snapshots.first?.timestamp
        oldestSnapshotDate = snapshots.last?.timestamp
        snapshotsFilePath = historyService.snapshotsFilePath
    }

    func clearHistory() {
        do {
            try historyService.clearAllSnapshots()
            showClearSuccess = true
            clearHistoryError = nil
        } catch {
            clearHistoryError = error.localizedDescription
        }
    }

    private func observeSnapshotChanges() {
        historyService.snapshotsDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refreshDataStats()
            }
            .store(in: &cancellables)
    }
}
