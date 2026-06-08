import SwiftUI

struct ReportsComingSoonPage: View {
    private let plannedReports: [(icon: String, title: String)] = [
        ("heart.text.square", "Health Reports"),
        ("magnifyingglass.circle", "Used Mac Inspection Certificates"),
        ("clock.arrow.circlepath", "Historical Analysis Reports")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
            DashboardSectionHeader(
                title: "Reports",
                subtitle: "Professional PDF reports are coming soon.",
                systemImage: "doc.richtext"
            )

            comingSoonCard

            plannedReportsSection

            developmentNote
        }
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Coming Soon Card

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: MacCheckTheme.Radius.md, style: .continuous)
                        .fill(MacCheckTheme.proGradient.opacity(0.14))
                        .frame(width: 52, height: 52)

                    Image(systemName: "doc.richtext.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MacCheckTheme.proGradient)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    HStack(spacing: MacCheckTheme.Spacing.sm) {
                        Text("Pro Reports")
                            .font(.headline)
                        ProBadge(compact: true)
                        comingSoonBadge
                    }

                    Text("Export polished PDF reports directly from your Mac health data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .opacity(0.5)

            HStack(spacing: MacCheckTheme.Spacing.sm) {
                Image(systemName: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Report generation will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .macCheckPanel()
    }

    private var comingSoonBadge: some View {
        Text("Coming Soon")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MacCheckTheme.tertiaryFill)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }

    // MARK: - Planned Reports

    private var plannedReportsSection: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            Text("Future versions of MacCheck will include:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                ForEach(plannedReports, id: \.title) { report in
                    plannedReportRow(icon: report.icon, title: report.title)
                }
            }
            .padding(MacCheckTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
    }

    private func plannedReportRow(icon: String, title: String) -> some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(.tertiary)
                .frame(width: 16, alignment: .center)

            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
        }
    }

    // MARK: - Development Note

    private var developmentNote: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.sm) {
            Image(systemName: "hammer.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text("This feature is under active development.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(MacCheckTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }
}

#Preview {
    ScrollView {
        ReportsComingSoonPage()
            .padding(MacCheckTheme.Spacing.xl)
    }
    .background(MacCheckTheme.secondaryBackground)
    .frame(width: 800, height: 700)
}
