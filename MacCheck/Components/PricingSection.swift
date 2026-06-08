import SwiftUI

struct PricingSection: View {
    let plan: PricingPlan

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            lifetimeCard
        }
    }

    private var lifetimeCard: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Text(plan.title)
                        .font(.headline)

                    ProBadge(compact: true)
                }

                Text(plan.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(plan.price)
                    .font(.title.weight(.semibold))
                    .padding(.top, MacCheckTheme.Spacing.xs)
            }

            Divider()
                .opacity(0.35)

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                Text("Unlock forever:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(plan.includedFeatures, id: \.self) { feature in
                    HStack(spacing: MacCheckTheme.Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 16)

                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(MacCheckTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

#Preview {
    PricingSection(plan: PricingPlanCatalog.lifetime)
        .padding()
        .frame(width: 420)
}
