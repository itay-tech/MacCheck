import SwiftUI

/// Shared shell for dashboard KPI metric cards — fixed height, consistent typography.
struct MetricKPICard: View {
    let icon: String
    let title: String
    let tint: Color
    let badge: String
    let primaryValue: String
    let primarySuffix: String?
    let caption: String
    var help: DashboardHelpText? = nil
    var subsystemScore: Int? = nil
    var animatesValueChanges = false
    var headerAccessory: AnyView? = nil
    let progress: Double
    let footerMetrics: [(label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            header

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(primaryValue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .modifier(AnimatedMetricValueModifier(
                            value: primaryValue,
                            enabled: animatesValueChanges
                        ))

                    if let primarySuffix {
                        Text(primarySuffix)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .modifier(AnimatedMetricValueModifier(
                        value: caption,
                        enabled: animatesValueChanges
                    ))

                if let subsystemScore {
                    Text("Score: \(subsystemScore)/100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HealthScoreColor.color(for: subsystemScore))
                }
            }

            ProgressView(value: min(max(progress, 0), 1))
                .tint(tint)
                .frame(height: 6)
                .animation(animatesValueChanges ? .easeInOut(duration: 0.25) : nil, value: progress)

            Spacer(minLength: 0)

            footerGrid
        }
        .frame(maxWidth: .infinity, minHeight: MacCheckTheme.KPI.height, maxHeight: MacCheckTheme.KPI.height, alignment: .topLeading)
        .macCheckCard()
    }

    // MARK: - Private

    private var header: some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20)

            Text(title)
                .font(.headline)

            if let help {
                DashboardHelpIcon(help: help)
            }

            Spacer(minLength: 0)

            if let headerAccessory {
                headerAccessory
            }

            Text(badge)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.12))
                .foregroundStyle(tint)
                .clipShape(Capsule())
                .lineLimit(1)
                .modifier(AnimatedMetricValueModifier(
                    value: badge,
                    enabled: animatesValueChanges
                ))
        }
    }

    private var footerGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: MacCheckTheme.Spacing.sm
        ) {
            ForEach(Array(paddedMetrics.enumerated()), id: \.offset) { _, metric in
                footerCell(label: metric.label, value: metric.value)
            }
        }
    }

    private var paddedMetrics: [(label: String, value: String)] {
        var metrics = footerMetrics
        while metrics.count < 4 {
            metrics.append((label: " ", value: " "))
        }
        return Array(metrics.prefix(4))
    }

    private func footerCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(label.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : .primary)
                .lineLimit(1)
                .modifier(AnimatedMetricValueModifier(
                    value: value,
                    enabled: animatesValueChanges
                ))
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
        .padding(.horizontal, MacCheckTheme.Spacing.sm)
        .padding(.vertical, MacCheckTheme.Spacing.xs)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }
}

private struct AnimatedMetricValueModifier: ViewModifier {
    let value: String
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: value)
        } else {
            content
        }
    }
}
