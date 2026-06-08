import SwiftUI

struct PredictionSummaryHero: View {
    let model: PredictionSummaryModel

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(outlookColor)
                    .frame(width: 28, height: 28)
                    .padding(10)
                    .background(outlookColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    Text(model.title)
                        .font(.title3.weight(.bold))

                    Text("Synthesized from your local scan history")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                confidenceBadge
            }

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                Text(model.outlookSentence)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(outlookColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.primaryRiskSentence)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .macCheckHeroCard()
    }

    private var confidenceBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Confidence")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(model.confidence.rawValue)
                .font(.caption.weight(.bold))
                .foregroundStyle(confidenceColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(confidenceColor.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var outlookColor: Color {
        switch model.tone {
        case .positive: .green
        case .warning: .orange
        case .negative: .red
        case .accent: .accentColor
        case .primary, .secondary: .primary
        }
    }

    private var confidenceColor: Color {
        switch model.confidence {
        case .low: .orange
        case .medium: .yellow
        case .high: .green
        }
    }
}

#Preview {
    PredictionSummaryHero(
        model: PredictionSummaryModel(
            title: "Mac Outlook",
            outlookSentence: "Your Mac is expected to remain healthy for the next 4 months.",
            primaryRiskSentence: "Storage growth is currently the biggest risk.",
            confidence: .high,
            tone: .warning
        )
    )
    .padding()
    .frame(width: 760)
}
