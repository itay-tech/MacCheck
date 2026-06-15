import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {

    @Published private(set) var latestSnapshot: HealthSnapshot?
    @Published private(set) var previousSnapshot: HealthSnapshot?
    @Published private(set) var scoreChange: Int?
    @Published private(set) var hasComparableHistory = false
    @Published private(set) var trendItems: [TrendItem] = []
    @Published private(set) var statistics: HistoryStatistics?
    @Published private(set) var recentSnapshots: [HealthSnapshot] = []
    @Published private(set) var historyError: String?

    private let historyService: HistoryService
    private let proSnapshotLimit = 100
    private var cancellables = Set<AnyCancellable>()

    static let freeSnapshotLimit = 2

    init(historyService: HistoryService) {
        self.historyService = historyService
        refresh()
        observeSnapshotChanges()
    }

    func refresh() {
        historyService.reloadFromDisk()

        latestSnapshot = historyService.latestSnapshot
        previousSnapshot = historyService.previousSnapshot
        scoreChange = historyService.scoreChange
        hasComparableHistory = historyService.hasComparableHistory
        recentSnapshots = Array(historyService.allSnapshots.prefix(proSnapshotLimit))
        statistics = HistoryStatisticsBuilder.build(from: historyService.allSnapshots)

        if let latestSnapshot, let previousSnapshot {
            trendItems = TrendAnalysisBuilder.build(
                current: latestSnapshot,
                previous: previousSnapshot
            )
        } else {
            trendItems = []
        }

        historyError = historyService.lastSaveErrorMessage
    }

    var currentScore: Int? {
        latestSnapshot?.overallHealthScore
    }

    var previousScore: Int? {
        previousSnapshot?.overallHealthScore
    }

    var lastScanDate: Date? {
        latestSnapshot?.timestamp
    }

    var hasAnySnapshots: Bool {
        latestSnapshot != nil
    }

    private func observeSnapshotChanges() {
        historyService.snapshotsDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
}
