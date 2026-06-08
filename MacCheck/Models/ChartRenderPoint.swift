import Foundation

/// Precomputed values for Swift Charts rendering — avoids work in view bodies.
struct ChartRenderPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let yValue: Double
    let displayValue: String
    let tone: ChartSemanticTone
}

enum ChartSemanticTone: Equatable {
    case positive
    case warning
    case negative
    case neutral
}

enum ChartRenderFactory {

    static let pointMarkerThreshold = 14
    static let linearInterpolationThreshold = 30

    static func makeRenderPoints(
        from dataPoints: [ChartDataPoint],
        yAxisFormat: ChartYAxisFormat,
        pointStyle: ChartPointStyle
    ) -> [ChartRenderPoint] {
        dataPoints.map { point in
            ChartRenderPoint(
                id: point.id,
                date: point.date,
                yValue: yValue(for: point, format: yAxisFormat),
                displayValue: displayValue(for: point, format: yAxisFormat),
                tone: tone(for: point, style: pointStyle)
            )
        }
    }

    static func showsPointMarkers(for count: Int) -> Bool {
        count <= pointMarkerThreshold
    }

    static func usesLinearInterpolation(for count: Int) -> Bool {
        count > linearInterpolationThreshold
    }

    // MARK: - Private

    private static func yValue(for point: ChartDataPoint, format: ChartYAxisFormat) -> Double {
        switch format {
        case .gigabytes:
            return point.value / 1_073_741_824.0
        default:
            return point.value
        }
    }

    private static func displayValue(for point: ChartDataPoint, format: ChartYAxisFormat) -> String {
        switch format {
        case .integer:
            return "\(Int(point.value.rounded()))"
        case .percentage:
            return "\(Int(point.value.rounded()))%"
        case .gigabytes:
            let gb = point.value / 1_073_741_824.0
            if gb >= 10 { return String(format: "%.0f GB", gb) }
            return String(format: "%.1f GB", gb)
        case .thermalSeverity:
            return thermalLabel(for: Int(point.value.rounded()))
        }
    }

    private static func tone(
        for point: ChartDataPoint,
        style: ChartPointStyle
    ) -> ChartSemanticTone {
        switch style {
        case .healthScore:
            return healthScoreTone(for: Int(point.value.rounded()))
        case .battery:
            if point.value >= 80 { return .positive }
            if point.value >= 60 { return .warning }
            if point.value >= 40 { return .warning }
            return .negative
        case .storage:
            let gigabytes = point.value / 1_073_741_824.0
            if gigabytes >= 400 { return .negative }
            if gigabytes >= 250 { return .warning }
            return .positive
        case .memory:
            let gigabytes = point.value / 1_073_741_824.0
            if gigabytes >= 6.5 { return .negative }
            if gigabytes >= 3.2 { return .warning }
            return .positive
        case .thermal:
            switch Int(point.value.rounded()) {
            case 0: return .positive
            case 1: return .warning
            case 2, 3: return .negative
            default: return .neutral
            }
        case .accent:
            return .neutral
        }
    }

    private static func healthScoreTone(for score: Int) -> ChartSemanticTone {
        switch score {
        case 80...: return .positive
        case 60..<80: return .warning
        case 40..<60: return .warning
        default: return .negative
        }
    }

    private static func thermalLabel(for severity: Int) -> String {
        switch severity {
        case 0: "Nominal"
        case 1: "Fair"
        case 2: "Serious"
        case 3: "Critical"
        default: "—"
        }
    }
}
