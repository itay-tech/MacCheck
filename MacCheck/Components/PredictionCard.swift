import SwiftUI

struct PredictionCard: View {
    let model: PredictionCardModel
    var isEmphasized: Bool = false

    private let cardHeight: CGFloat = 188

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isEmphasized {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 4)
                    .padding(.vertical, MacCheckTheme.Spacing.md)
            }

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
                header

                switch model.displayMode {
                case .ready:
                    readyContent
                case .unavailable(let message):
                    unavailableContent(message)
                }
            }
            .padding(.leading, isEmphasized ? MacCheckTheme.Spacing.md : 0)
        }
        .padding(MacCheckTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .fill(accentColor.opacity(isEmphasized ? 0.05 : 0))
        }
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(
                    isEmphasized ? accentColor.opacity(0.22) : Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: model.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 20, height: 20)
                .padding(6)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))

            Text(model.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            Spacer(minLength: 0)

            confidenceBadge
        }
    }

    private var confidenceBadge: some View {
        Text(model.confidence.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(confidenceColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Content

    @ViewBuilder
    private var readyContent: some View {
        Text(forecastSentence)
            .font(.subheadline)
            .foregroundStyle(isEmphasized ? .primary : .secondary)
            .fontWeight(isEmphasized ? .medium : .regular)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

        if !supportingMetrics.isEmpty {
            HStack(spacing: MacCheckTheme.Spacing.md) {
                ForEach(supportingMetrics) { metric in
                    supportingMetricColumn(metric)
                }
            }
        }

        Spacer(minLength: 0)
    }

    private func supportingMetricColumn(_ metric: PredictionMetricRow) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(metric.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .lineLimit(2)

            Text(metric.value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color(for: metric.tone))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func unavailableContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Presentation

    private var forecastSentence: String {
        guard let summary = model.summary else { return model.subtitle }
        return summary
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var supportingMetrics: [PredictionMetricRow] {
        Array(model.metrics.prefix(3))
    }

    // MARK: - Colors

    private var accentColor: Color {
        if let risk = model.riskLevel {
            return color(for: riskTone(risk))
        }
        return .accentColor
    }

    private var confidenceColor: Color {
        switch model.confidence {
        case .low: .orange
        case .medium: .yellow
        case .high: .green
        }
    }

    private func riskTone(_ risk: PredictionRiskLevel) -> PredictionSemanticTone {
        switch risk {
        case .low: .positive
        case .moderate: .warning
        case .high: .negative
        }
    }

    private func color(for tone: PredictionSemanticTone) -> Color {
        switch tone {
        case .primary: .primary
        case .positive: .green
        case .warning: .orange
        case .negative: .red
        case .secondary: .secondary
        case .accent: .accentColor
        }
    }
}

#Preview {
    VStack(spacing: MacCheckTheme.Spacing.lg) {
        PredictionCard(
            model: PredictionCardModel(
                id: "storage",
                title: "Storage Forecast",
                subtitle: "Projected storage usage and fill-up timeline",
                systemImage: "internaldrive",
                displayMode: .ready,
                summary: "Growing by 2.1 GB/day\nWarning in 94 days • Critical in 126 days",
                metrics: [
                    PredictionMetricRow(id: "1", label: "Current Usage", value: "412 GB", tone: .primary),
                    PredictionMetricRow(id: "2", label: "Growth Rate", value: "2.1 GB/day", tone: .warning),
                    PredictionMetricRow(id: "3", label: "Until Warning", value: "94 days", tone: .warning)
                ],
                confidence: .medium,
                riskLevel: .moderate
            ),
            isEmphasized: true
        )

        PredictionCard(
            model: PredictionCardModel(
                id: "battery",
                title: "Battery Forecast",
                subtitle: "Projected battery health decline",
                systemImage: "battery.100",
                displayMode: .ready,
                summary: "Battery health has remained stable over tracked history.",
                metrics: [
                    PredictionMetricRow(id: "1", label: "Current Health", value: "92%", tone: .positive),
                    PredictionMetricRow(id: "2", label: "Until 85%", value: "Not projected", tone: .secondary)
                ],
                confidence: .medium,
                riskLevel: .low
            )
        )
    }
    .padding()
    .frame(width: 760)
}
