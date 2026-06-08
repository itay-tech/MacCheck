import Foundation

struct HistoryStatistics: Equatable {
    let items: [StatisticItem]
}

struct StatisticItem: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let subtitle: String?
    let occurrenceDate: Date?
    let systemImage: String
}
