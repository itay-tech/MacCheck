import SwiftUI

struct SnapshotRow: View {
    let snapshot: HealthSnapshot

    var body: some View {
        HStack(spacing: MacCheckTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Text(snapshot.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)

            scorePill(label: "Overall", score: snapshot.overallHealthScore)

            if snapshot.hasBattery, let batteryScore = snapshot.batteryScore {
                scorePill(label: "Battery", score: batteryScore)
            }

            scorePill(label: "Storage", score: snapshot.storageScore)
            scorePill(label: "Memory", score: snapshot.memoryScore)

            if let thermalScore = snapshot.thermalScore {
                scorePill(label: "Thermal", score: thermalScore)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, MacCheckTheme.Spacing.sm)
        .padding(.horizontal, MacCheckTheme.Spacing.md)
    }

    // MARK: - Private

    private func scorePill(label: String, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text("\(score)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HealthScoreColor.color(for: score))
                .frame(minWidth: 28)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(HealthScoreColor.color(for: score).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
        }
        .frame(minWidth: 64)
    }
}

#Preview {
    SnapshotRow(
        snapshot: HealthSnapshot(
            id: UUID(),
            timestamp: Date(),
            scoreVersion: 1,
            appVersion: "1.0",
            overallHealthScore: 88,
            batteryScore: 92,
            storageScore: 85,
            memoryScore: 90,
            startupScore: 100,
            thermalScore: 95,
            hasBattery: true,
            batteryHealthPercentage: 92,
            batteryCycleCount: 120,
            batteryCurrentChargePercentage: 0.8,
            storageTotalBytes: 500_000_000_000,
            storageUsedBytes: 300_000_000_000,
            storageFreeBytes: 200_000_000_000,
            storageFreePercentage: 0.4,
            memoryTotalBytes: 16_000_000_000,
            memoryUsedBytes: 10_000_000_000,
            cachedFilesBytes: 2_000_000_000,
            swapUsedBytes: 0,
            memoryPressureStatus: .healthy,
            startupAppsCount: 5,
            thermalStatus: .nominal
        )
    )
    .padding()
    .frame(width: 720)
}
