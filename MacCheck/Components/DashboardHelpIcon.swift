import SwiftUI

struct DashboardHelpIcon: View {
    let help: DashboardHelpText

    @EnvironmentObject private var tooltipState: DashboardTooltipState
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "info.circle")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .background {
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .named(DashboardCoordinateSpace.root))
                    Color.clear
                        .onAppear {
                            reportAnchor(frame)
                        }
                        .onChange(of: frame) { _, updatedFrame in
                            reportAnchor(updatedFrame)
                        }
                        .onChange(of: isHovering) { _, hovering in
                            if hovering {
                                reportAnchor(frame)
                            }
                        }
                }
            }
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    tooltipState.activate(help)
                } else {
                    tooltipState.deactivate(help)
                }
            }
            .accessibilityLabel("About \(help.title)")
            .accessibilityHint(help.text)
    }

    private func reportAnchor(_ frame: CGRect) {
        guard isHovering else { return }
        tooltipState.updateAnchor(frame, for: help)
    }
}
