import Foundation

/// A single time-series point for history charts.
struct ChartDataPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double

    init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

/// X-axis label density for history charts.
enum ChartAxisGranularity: Equatable {
    case daily
    case weekly
    case monthly

    static func forSnapshotCount(_ count: Int) -> ChartAxisGranularity {
        if count <= 14 { return .daily }
        if count <= 45 { return .weekly }
        return .monthly
    }
}
