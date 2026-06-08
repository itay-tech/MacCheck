import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published private(set) var snapshotCount = 0
    @Published private(set) var oldestSnapshotDate: Date?
    @Published private(set) var newestSnapshotDate: Date?
    @Published var showClearConfirmation = false
    @Published var showClearSuccess = false
    @Published var clearHistoryError: String?

    private let historyService: HistoryService
    private let historyViewModel: HistoryViewModel
    private let chartsViewModel: ChartsViewModel
    private let predictionsViewModel: PredictionsViewModel

    init(
        historyService: HistoryService,
        historyViewModel: HistoryViewModel,
        chartsViewModel: ChartsViewModel,
        predictionsViewModel: PredictionsViewModel
    ) {
        self.historyService = historyService
        self.historyViewModel = historyViewModel
        self.chartsViewModel = chartsViewModel
        self.predictionsViewModel = predictionsViewModel
    }

    func refreshDataStats() {
        historyService.reloadFromDisk()
        let snapshots = historyService.allSnapshots
        snapshotCount = snapshots.count
        newestSnapshotDate = snapshots.first?.timestamp
        oldestSnapshotDate = snapshots.last?.timestamp
    }

    func clearHistory() {
        do {
            try historyService.clearAllSnapshots()
            refreshDataStats()
            refreshDependentPages()
            showClearSuccess = true
            clearHistoryError = nil
        } catch {
            clearHistoryError = error.localizedDescription
        }
    }

    private func refreshDependentPages() {
        historyViewModel.refresh()
        chartsViewModel.invalidateCache()
        predictionsViewModel.invalidateCache()
    }
}
