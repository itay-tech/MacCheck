import SwiftUI

struct HealthScoreCard: View {
    let breakdown: HealthScoreBreakdown
    let generatedAt: Date

    @State private var ringProgress: CGFloat = 0

    private var score: Int { breakdown.overallScore }

    private var scoreColor: Color {
        HealthScoreColor.color(for: score)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    Text("Health Score")
                        .font(.largeTitle.weight(.bold))
                    Text("Overall Mac health assessment")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge
            }

            HStack(alignment: .center, spacing: MacCheckTheme.Spacing.xxl) {
                scoreRing

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    Text("Component Scores")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading)
                        ],
                        alignment: .leading,
                        spacing: MacCheckTheme.Spacing.md
                    ) {
                        scoreBreakdownTile(label: "Battery", value: breakdown.batteryScore, icon: "battery.100")
                        scoreBreakdownTile(label: "Storage", value: breakdown.storageScore, icon: "internaldrive")
                        scoreBreakdownTile(label: "Memory", value: breakdown.memoryScore, icon: "memorychip")
                        scoreBreakdownTile(label: "Startup", value: breakdown.startupScore, icon: "power.circle")
                        scoreBreakdownTile(label: "Thermal", value: breakdown.thermalScore, icon: "thermometer.medium")
                    }

                    Text("Updated \(generatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .macCheckHeroCard()
    }

    // MARK: - Subviews

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 18)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    scoreColor.gradient,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: MacCheckTheme.Spacing.xs) {
                Text("\(score)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text(HealthScoreColor.label(for: score))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 188, height: 188)
        .task(id: score) {
            withAnimation(.easeOut(duration: 0.8)) {
                ringProgress = CGFloat(score) / 100
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: MacCheckTheme.Spacing.xs) {
            Circle()
                .fill(scoreColor)
                .frame(width: 8, height: 8)
            Text(HealthScoreColor.label(for: score))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, MacCheckTheme.Spacing.md)
        .padding(.vertical, MacCheckTheme.Spacing.sm)
        .background(scoreColor.opacity(0.12))
        .foregroundStyle(scoreColor)
        .clipShape(Capsule())
    }

    // MARK: - Private

    private func scoreBreakdownTile(label: String, value: Int?, icon: String) -> some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if let value {
                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(HealthScoreColor.color(for: value))
            } else {
                Text("—")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, MacCheckTheme.Spacing.sm)
        .padding(.vertical, MacCheckTheme.Spacing.sm)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }
}

#Preview {
    HealthScoreCard(
        breakdown: HealthScoreBreakdown(
            overallScore: 78,
            batteryScore: 88,
            storageScore: 72,
            memoryScore: 65,
            startupScore: 84,
            thermalScore: 92
        ),
        generatedAt: Date()
    )
    .padding()
    .frame(width: 760)
}
