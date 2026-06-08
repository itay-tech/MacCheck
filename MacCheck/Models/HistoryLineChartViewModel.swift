import Foundation

enum HistoryChartDisplayMode: Equatable {
    case ready
    case needsMoreData
    case unavailable(String)
}

enum ChartYAxisFormat: Equatable {
    case integer
    case gigabytes
    case thermalSeverity
    case percentage
}

enum ChartPointStyle: Equatable {
    case healthScore
    case accent
    case battery
    case storage
    case memory
    case thermal
}

/// Presentation model for a reusable history line chart.
struct HistoryLineChartViewModel: Equatable {
    let title: String
    let subtitle: String
    let systemImage: String
    let displayMode: HistoryChartDisplayMode
    let dataPoints: [ChartDataPoint]
    let renderPoints: [ChartRenderPoint]
    let showsPointMarkers: Bool
    let usesLinearInterpolation: Bool
    let axisGranularity: ChartAxisGranularity
    let yAxisDomain: ClosedRange<Double>
    let yAxisTickValues: [Double]?
    let yAxisFormat: ChartYAxisFormat
    let pointStyle: ChartPointStyle
    let summaryTitle: String?
    let summaryText: String?
    let summaryTrend: ComparisonTrend?

    var isChartReady: Bool {
        displayMode == .ready && renderPoints.count >= 2
    }

    static let emptyMessage = "History will appear after more scans are collected."

    static func ready(
        title: String,
        subtitle: String,
        systemImage: String,
        dataPoints: [ChartDataPoint],
        axisGranularity: ChartAxisGranularity,
        yAxisDomain: ClosedRange<Double>,
        yAxisTickValues: [Double]?,
        yAxisFormat: ChartYAxisFormat,
        pointStyle: ChartPointStyle,
        summaryTitle: String?,
        summaryText: String?,
        summaryTrend: ComparisonTrend?
    ) -> HistoryLineChartViewModel {
        HistoryLineChartViewModel(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            displayMode: .ready,
            dataPoints: dataPoints,
            renderPoints: ChartRenderFactory.makeRenderPoints(
                from: dataPoints,
                yAxisFormat: yAxisFormat,
                pointStyle: pointStyle
            ),
            showsPointMarkers: ChartRenderFactory.showsPointMarkers(for: dataPoints.count),
            usesLinearInterpolation: ChartRenderFactory.usesLinearInterpolation(for: dataPoints.count),
            axisGranularity: axisGranularity,
            yAxisDomain: yAxisDomain,
            yAxisTickValues: yAxisTickValues,
            yAxisFormat: yAxisFormat,
            pointStyle: pointStyle,
            summaryTitle: summaryTitle,
            summaryText: summaryText,
            summaryTrend: summaryTrend
        )
    }

    static func needsMoreData(
        title: String,
        subtitle: String,
        systemImage: String,
        pointStyle: ChartPointStyle,
        yAxisFormat: ChartYAxisFormat,
        yAxisDomain: ClosedRange<Double> = 0...100
    ) -> HistoryLineChartViewModel {
        HistoryLineChartViewModel(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            displayMode: .needsMoreData,
            dataPoints: [],
            renderPoints: [],
            showsPointMarkers: false,
            usesLinearInterpolation: false,
            axisGranularity: .daily,
            yAxisDomain: yAxisDomain,
            yAxisTickValues: nil,
            yAxisFormat: yAxisFormat,
            pointStyle: pointStyle,
            summaryTitle: nil,
            summaryText: nil,
            summaryTrend: nil
        )
    }

    static func unavailable(
        title: String,
        subtitle: String,
        systemImage: String,
        message: String,
        pointStyle: ChartPointStyle,
        yAxisFormat: ChartYAxisFormat,
        yAxisDomain: ClosedRange<Double> = 0...100
    ) -> HistoryLineChartViewModel {
        HistoryLineChartViewModel(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            displayMode: .unavailable(message),
            dataPoints: [],
            renderPoints: [],
            showsPointMarkers: false,
            usesLinearInterpolation: false,
            axisGranularity: .daily,
            yAxisDomain: yAxisDomain,
            yAxisTickValues: nil,
            yAxisFormat: yAxisFormat,
            pointStyle: pointStyle,
            summaryTitle: nil,
            summaryText: nil,
            summaryTrend: nil
        )
    }
}
