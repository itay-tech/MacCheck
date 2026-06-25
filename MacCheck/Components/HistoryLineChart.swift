import Charts
import SwiftUI

struct HistoryLineChart: View {
    let viewModel: HistoryLineChartViewModel

    @State private var selectedDate: Date?

    private let chartHeight: CGFloat = 240

    private var selectedPoint: ChartRenderPoint? {
        guard let selectedDate else { return nil }
        return viewModel.renderPoints.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    var body: some View {
        Group {
            switch viewModel.displayMode {
            case .ready where viewModel.isChartReady:
                chartContent
            case .unavailable(let message):
                unavailableState(message)
            default:
                emptyState
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    // MARK: - Content

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            if let summaryTitle = viewModel.summaryTitle,
               let summaryText = viewModel.summaryText {
                summaryHeader(title: summaryTitle, text: summaryText)
            }

            chartView
        }
        .macCheckPanel()
    }

    private func summaryHeader(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(summaryColor)
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(viewModel.renderPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.yValue)
                )
                .interpolationMethod(viewModel.usesLinearInterpolation ? .linear : .catmullRom)
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }

            if viewModel.showsPointMarkers {
                ForEach(viewModel.renderPoints) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.yValue)
                    )
                    .symbolSize(selectedPoint?.id == point.id ? 90 : 56)
                    .foregroundStyle(pointColor(for: point))
                }
            } else if let selectedPoint {
                PointMark(
                    x: .value("Date", selectedPoint.date),
                    y: .value("Value", selectedPoint.yValue)
                )
                .symbolSize(90)
                .foregroundStyle(pointColor(for: selectedPoint))

                RuleMark(x: .value("Date", selectedPoint.date))
                    .foregroundStyle(Color.primary.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: viewModel.yAxisDomain)
        .chartYAxis {
            if let ticks = viewModel.yAxisTickValues {
                AxisMarks(position: .leading, values: ticks) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel {
                        if let label = yAxisLabel(for: value) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel {
                        if let label = yAxisLabel(for: value) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.primary.opacity(0.06))
                AxisValueLabel(format: xAxisLabelFormat, centered: true)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedPoint,
                   let plotFrameAnchor = proxy.plotFrame,
                   let plotX = proxy.position(forX: selectedPoint.date) {
                    let plotFrame = geometry[plotFrameAnchor]
                    let tooltipX = min(
                        max(plotFrame.origin.x + plotX, plotFrame.minX + 80),
                        plotFrame.maxX - 80
                    )

                    ChartHoverTooltip(
                        date: selectedPoint.date,
                        value: selectedPoint.displayValue,
                        accentColor: pointColor(for: selectedPoint)
                    )
                    .position(x: tooltipX, y: plotFrame.minY + 24)
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(height: chartHeight)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty / Unavailable

    private var emptyState: some View {
        Text(HistoryLineChartViewModel.emptyMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .macCheckHeroCard()
    }

    private func unavailableState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .macCheckHeroCard()
    }

    // MARK: - Formatting

    private var lineColor: Color {
        .accentColor
    }

    private var summaryColor: Color {
        guard let trend = viewModel.summaryTrend else { return .secondary }
        switch trend {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .secondary
        }
    }

    private func pointColor(for point: ChartRenderPoint) -> Color {
        switch viewModel.pointStyle {
        case .healthScore:
            return HealthScoreColor.color(for: Int(point.yValue.rounded()))
        case .battery:
            if point.yValue >= 80 { return .green }
            if point.yValue >= 60 { return .yellow }
            if point.yValue >= 40 { return .orange }
            return .red
        case .storage:
            if point.yValue >= 400 { return .red }
            if point.yValue >= 250 { return .orange }
            return .green
        case .memory:
            if point.yValue >= 6.5 { return .red }
            if point.yValue >= 3.2 { return .orange }
            return .green
        case .thermal:
            switch Int(point.yValue.rounded()) {
            case 0: return .green
            case 1: return .orange
            case 2, 3: return .red
            default: return .secondary
            }
        case .accent:
            return .accentColor
        }
    }

    private func yAxisLabel(for value: AxisValue) -> String? {
        guard let numeric = value.as(Double.self) else { return nil }

        switch viewModel.yAxisFormat {
        case .integer:
            return "\(Int(numeric.rounded()))"
        case .percentage:
            return "\(Int(numeric.rounded()))%"
        case .gigabytes:
            if numeric >= 10 { return String(format: "%.0f GB", numeric) }
            return String(format: "%.1f GB", numeric)
        case .thermalSeverity:
            return thermalLabel(for: Int(numeric.rounded()))
        }
    }

    private func thermalLabel(for severity: Int) -> String {
        switch severity {
        case 0: "Nominal"
        case 1: "Fair"
        case 2: "Serious"
        case 3: "Critical"
        default: "—"
        }
    }

    private var xAxisValues: AxisMarkValues {
        switch viewModel.axisGranularity {
        case .daily: return .stride(by: .day)
        case .weekly: return .stride(by: .weekOfYear)
        case .monthly: return .stride(by: .month)
        }
    }

    private var xAxisLabelFormat: Date.FormatStyle {
        switch viewModel.axisGranularity {
        case .daily, .weekly:
            return .dateTime.month(.abbreviated).day()
        case .monthly:
            return .dateTime.month(.abbreviated).year()
        }
    }
}

// MARK: - Tooltip

private struct ChartHoverTooltip: View {
    let date: Date
    let value: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, MacCheckTheme.Spacing.sm)
                .padding(.vertical, MacCheckTheme.Spacing.xs)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, MacCheckTheme.Spacing.md)
        .padding(.vertical, MacCheckTheme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous)
                .fill(MacCheckTheme.cardBackground)
                .shadow(color: MacCheckTheme.cardShadow, radius: 6, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}
