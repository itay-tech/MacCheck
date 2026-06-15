import Combine
import Foundation

struct ChartsPageData: Equatable {
    let healthScore: HistoryLineChartViewModel
    let batteryHealth: HistoryLineChartViewModel
    let storageUsage: HistoryLineChartViewModel
    let swapUsage: HistoryLineChartViewModel
    let thermalHistory: HistoryLineChartViewModel

    static let initial = ChartsPageData(
        healthScore: .needsMoreData(
            title: "Health Score Over Time",
            subtitle: "Daily overall health score",
            systemImage: "heart.text.square",
            pointStyle: .healthScore,
            yAxisFormat: .integer
        ),
        batteryHealth: .needsMoreData(
            title: "Battery Health Over Time",
            subtitle: "Battery health percentage history",
            systemImage: "battery.100",
            pointStyle: .battery,
            yAxisFormat: .percentage
        ),
        storageUsage: .needsMoreData(
            title: "Storage Usage Over Time",
            subtitle: "Used storage in gigabytes",
            systemImage: "internaldrive",
            pointStyle: .storage,
            yAxisFormat: .gigabytes,
            yAxisDomain: 0...1
        ),
        swapUsage: .needsMoreData(
            title: "Swap Usage Over Time",
            subtitle: "Swap memory usage in gigabytes",
            systemImage: "memorychip",
            pointStyle: .memory,
            yAxisFormat: .gigabytes,
            yAxisDomain: 0...1
        ),
        thermalHistory: .needsMoreData(
            title: "Thermal History Over Time",
            subtitle: "Thermal severity over time",
            systemImage: "thermometer.medium",
            pointStyle: .thermal,
            yAxisFormat: .thermalSeverity,
            yAxisDomain: 0...3
        )
    )
}

@MainActor
final class ChartsViewModel: ObservableObject {

    @Published private(set) var charts: ChartsPageData = .initial

    private let historyService: HistoryService
    private var lastRefreshToken: HistoryRefreshToken?
    private var cancellables = Set<AnyCancellable>()

    init(historyService: HistoryService) {
        self.historyService = historyService
        observeSnapshotChanges()
    }

    /// Loads history once and rebuilds chart data only when snapshots change.
    func refreshIfNeeded() {
        historyService.reloadFromDisk()
        let snapshots = historyService.allSnapshots
        let token = HistoryRefreshToken(snapshots: snapshots)
        guard token != lastRefreshToken else { return }
        lastRefreshToken = token
        charts = buildCharts(from: snapshots)
    }

    /// Forces a rebuild after new snapshots are recorded elsewhere.
    func invalidateCache() {
        lastRefreshToken = nil
        refreshIfNeeded()
    }

    private func buildCharts(from snapshots: [HealthSnapshot]) -> ChartsPageData {
        ChartsPageData(
            healthScore: HistoryChartBuilder.healthScore(from: snapshots),
            batteryHealth: HistoryChartBuilder.batteryHealth(from: snapshots),
            storageUsage: HistoryChartBuilder.storageUsage(from: snapshots),
            swapUsage: HistoryChartBuilder.swapUsage(from: snapshots),
            thermalHistory: HistoryChartBuilder.thermalHistory(from: snapshots)
        )
    }

    private func observeSnapshotChanges() {
        historyService.snapshotsDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.invalidateCache()
            }
            .store(in: &cancellables)
    }
}

private struct HistoryRefreshToken: Equatable {
    let count: Int
    let latestID: UUID?
    let latestTimestamp: Date?

    init(snapshots: [HealthSnapshot]) {
        count = snapshots.count
        latestID = snapshots.first?.id
        latestTimestamp = snapshots.first?.timestamp
    }
}
