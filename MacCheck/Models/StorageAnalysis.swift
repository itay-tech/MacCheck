import Foundation

struct StorageAnalysis: Equatable {
    let weeklyGrowthBytes: Int64
    let monthlyGrowthBytes: Int64
    let daysUntilFull: Int?
    let topGrowingCategory: StorageCategory
    let healthScore: Int
    let status: StorageStatus
}
