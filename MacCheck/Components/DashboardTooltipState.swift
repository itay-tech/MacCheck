import Combine
import CoreGraphics
import SwiftUI

@MainActor
final class DashboardTooltipState: ObservableObject {
    @Published private(set) var activeHelp: DashboardHelpText?
    @Published private(set) var anchorFrame: CGRect = .zero

    func activate(_ help: DashboardHelpText) {
        activeHelp = help
    }

    func deactivate(_ help: DashboardHelpText) {
        guard activeHelp == help else { return }
        activeHelp = nil
        anchorFrame = .zero
    }

    func updateAnchor(_ frame: CGRect, for help: DashboardHelpText) {
        guard activeHelp == help else { return }
        anchorFrame = frame
    }
}
