import SwiftUI

enum HealthScoreColor {

    static func color(for score: Int) -> Color {
        switch score {
        case 80...: .green
        case 60..<80: .yellow
        case 40..<60: .orange
        default: .red
        }
    }

    static func label(for score: Int) -> String {
        switch score {
        case 90...: "Excellent"
        case 80..<90: "Good"
        case 70..<80: "Fair"
        case 60..<70: "Moderate"
        case 40..<60: "Needs Attention"
        default: "Critical"
        }
    }
}
