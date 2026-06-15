import SwiftUI

struct DashboardTooltipHost: View {
    @EnvironmentObject private var tooltipState: DashboardTooltipState
    @State private var bubbleSize: CGSize = .zero

    private let maxBubbleWidth: CGFloat = 260
    private let edgePadding: CGFloat = 8
    private let iconGap: CGFloat = 8

    var body: some View {
        GeometryReader { container in
            if let help = tooltipState.activeHelp, tooltipState.anchorFrame != .zero {
                bubble(for: help)
                    .frame(maxWidth: maxBubbleWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    bubbleSize = geometry.size
                                }
                                .onChange(of: geometry.size) { _, newSize in
                                    bubbleSize = newSize
                                }
                        }
                    }
                    .offset(
                        x: origin(in: container.size).x,
                        y: origin(in: container.size).y
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Private

    private func bubble(for help: DashboardHelpText) -> some View {
        Text(help.text)
            .font(.caption)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
    }

    private func origin(in containerSize: CGSize) -> CGPoint {
        let anchor = tooltipState.anchorFrame
        let width = min(maxBubbleWidth, max(bubbleSize.width, 1))
        let height = max(bubbleSize.height, 1)

        let minX = edgePadding
        let maxX = max(minX, containerSize.width - width - edgePadding)
        let centeredX = anchor.midX - (width / 2)
        let x = min(max(centeredX, minX), maxX)

        let preferredY = anchor.minY - height - iconGap
        let maxY = max(edgePadding, containerSize.height - height - edgePadding)
        let y = min(max(preferredY, edgePadding), maxY)

        return CGPoint(x: x, y: y)
    }
}
