import SwiftUI

enum RecentSnapshotsLayout {
    static let rowHeight: CGFloat = 68
    static let freeVisibleRows: Int = 2
    static let proVisibleRows: Int = 8

    static var freeListHeight: CGFloat {
        rowHeight * CGFloat(freeVisibleRows)
    }

    static var proScrollMaxHeight: CGFloat {
        rowHeight * CGFloat(proVisibleRows)
    }
}

struct RecentSnapshotsCard: View {
    let snapshots: [HealthSnapshot]
    let showsUpgradePrompt: Bool
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showsUpgradePrompt {
                snapshotList
                    .frame(maxHeight: RecentSnapshotsLayout.freeListHeight, alignment: .top)

                Divider()
                    .padding(.horizontal, MacCheckTheme.Spacing.md)

                upgradePrompt
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    snapshotList
                }
                .frame(maxHeight: RecentSnapshotsLayout.proScrollMaxHeight)
            }
        }
        .background(MacCheckTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - List

    private var snapshotList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                SnapshotRow(snapshot: snapshot)

                if index < snapshots.count - 1 {
                    Divider()
                        .padding(.leading, MacCheckTheme.Spacing.md)
                }
            }
        }
        .padding(.vertical, MacCheckTheme.Spacing.xs)
    }

    // MARK: - Upgrade

    private var upgradePrompt: some View {
        HStack(alignment: .center, spacing: MacCheckTheme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Text("Full History")
                        .font(.subheadline.weight(.semibold))
                    ProBadge(compact: true)
                }

                Text("Unlock up to 100 snapshots with MacCheck Pro.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: MacCheckTheme.Spacing.md)

            Button("Upgrade") {
                onUnlock()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(MacCheckTheme.Spacing.lg)
        .background(MacCheckTheme.tertiaryFill)
    }
}

#Preview("Free") {
    RecentSnapshotsCard(
        snapshots: [],
        showsUpgradePrompt: true,
        onUnlock: {}
    )
    .padding()
    .frame(width: 760)
}
