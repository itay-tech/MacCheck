import Combine
import Foundation

@MainActor
final class PredictionsViewModel: ObservableObject {

    @Published private(set) var predictions: PredictionsPageData = .insufficientHistory(snapshotCount: 0)

    var summary: PredictionSummaryModel? {
        guard predictions.hasEnoughHistory else { return nil }
        return PredictionSummaryBuilder.build(from: predictions)
    }

    private let historyService: HistoryService
    private var lastRefreshToken: PredictionsRefreshToken?

    init(historyService: HistoryService) {
        self.historyService = historyService
    }

    func refreshIfNeeded() {
        historyService.reloadFromDisk()
        let snapshots = historyService.allSnapshots
        let token = PredictionsRefreshToken(snapshots: snapshots)
        guard token != lastRefreshToken else { return }
        lastRefreshToken = token
        predictions = PredictionEngine.build(from: snapshots)
    }

    func invalidateCache() {
        lastRefreshToken = nil
        refreshIfNeeded()
    }
}

private struct PredictionsRefreshToken: Equatable {
    let count: Int
    let latestID: UUID?
    let latestTimestamp: Date?

    init(snapshots: [HealthSnapshot]) {
        count = snapshots.count
        latestID = snapshots.first?.id
        latestTimestamp = snapshots.first?.timestamp
    }
}
