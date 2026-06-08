import SwiftUI

struct ProBenefitsSection: View {
    let benefits: [PaywallBenefit]

    private let columns = [
        GridItem(.flexible(), spacing: MacCheckTheme.Spacing.md),
        GridItem(.flexible(), spacing: MacCheckTheme.Spacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                Text("Pro Benefits")
                    .font(.headline)

                Text("Premium tools for long-term Mac monitoring.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: MacCheckTheme.Spacing.md) {
                ForEach(benefits) { benefit in
                    benefitCard(benefit)
                }
            }
        }
    }

    private func benefitCard(_ benefit: PaywallBenefit) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: benefit.iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(MacCheckTheme.proGradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)

            Text(benefit.title)
                .font(.subheadline.weight(.semibold))

            Text(benefit.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(MacCheckTheme.Spacing.md)
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

#Preview {
    ProBenefitsSection(benefits: FeatureComparisonCatalog.benefits)
        .padding()
        .frame(width: 640)
}
