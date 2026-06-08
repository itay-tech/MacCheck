import SwiftUI

struct FeatureComparisonSection: View {
    let rows: [FeatureComparisonRow]

    private let freeColumnWidth: CGFloat = 72
    private let proColumnWidth: CGFloat = 88

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            sectionHeader

            VStack(spacing: 0) {
                tableHeader

                Divider()
                    .opacity(0.35)

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    comparisonRow(row)

                    if index < rows.count - 1 {
                        Divider()
                            .opacity(0.2)
                            .padding(.leading, MacCheckTheme.Spacing.md)
                    }
                }
            }
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
            Text("Free vs Pro")
                .font(.headline)

            Text("Compare what you get with each plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Feature")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Free")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: freeColumnWidth, alignment: .center)

            Text("Pro")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: proColumnWidth, alignment: .center)
        }
        .padding(.horizontal, MacCheckTheme.Spacing.md)
        .padding(.vertical, MacCheckTheme.Spacing.sm)
        .background(MacCheckTheme.tertiaryFill)
    }

    private func comparisonRow(_ row: FeatureComparisonRow) -> some View {
        HStack(spacing: 0) {
            Text(row.name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            availabilityCell(row.free, emphasized: false)
                .frame(width: freeColumnWidth, alignment: .center)

            availabilityCell(row.pro, emphasized: true)
                .frame(width: proColumnWidth, alignment: .center)
        }
        .padding(.horizontal, MacCheckTheme.Spacing.md)
        .padding(.vertical, MacCheckTheme.Spacing.sm)
    }

    @ViewBuilder
    private func availabilityCell(_ availability: FeatureAvailability, emphasized: Bool) -> some View {
        switch availability {
        case .included:
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(emphasized ? Color.accentColor : .secondary)

        case .excluded:
            Image(systemName: "minus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)

        case .limit(let value):
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(emphasized ? .primary : .secondary)

        case .comingSoon:
            Text("Coming Soon")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }
}

#Preview {
    FeatureComparisonSection(rows: FeatureComparisonCatalog.rows)
        .padding()
        .frame(width: 640)
}
