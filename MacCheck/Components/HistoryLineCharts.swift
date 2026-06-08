import SwiftUI

struct HealthScoreLineChart: View, Equatable {
    let viewModel: HistoryLineChartViewModel

    var body: some View {
        ChartCard(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            systemImage: viewModel.systemImage
        ) {
            HistoryLineChart(viewModel: viewModel)
        }
    }

    static func == (lhs: HealthScoreLineChart, rhs: HealthScoreLineChart) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
}

struct BatteryHealthLineChart: View, Equatable {
    let viewModel: HistoryLineChartViewModel

    var body: some View {
        ChartCard(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            systemImage: viewModel.systemImage
        ) {
            HistoryLineChart(viewModel: viewModel)
        }
    }

    static func == (lhs: BatteryHealthLineChart, rhs: BatteryHealthLineChart) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
}

struct StorageUsageLineChart: View, Equatable {
    let viewModel: HistoryLineChartViewModel

    var body: some View {
        ChartCard(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            systemImage: viewModel.systemImage
        ) {
            HistoryLineChart(viewModel: viewModel)
        }
    }

    static func == (lhs: StorageUsageLineChart, rhs: StorageUsageLineChart) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
}

struct SwapUsageLineChart: View, Equatable {
    let viewModel: HistoryLineChartViewModel

    var body: some View {
        ChartCard(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            systemImage: viewModel.systemImage
        ) {
            HistoryLineChart(viewModel: viewModel)
        }
    }

    static func == (lhs: SwapUsageLineChart, rhs: SwapUsageLineChart) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
}

struct ThermalHistoryChart: View, Equatable {
    let viewModel: HistoryLineChartViewModel

    var body: some View {
        ChartCard(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            systemImage: viewModel.systemImage
        ) {
            HistoryLineChart(viewModel: viewModel)
        }
    }

    static func == (lhs: ThermalHistoryChart, rhs: ThermalHistoryChart) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
}
