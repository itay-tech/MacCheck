import SwiftUI

struct StorageCard: View {
    let storage: StorageInfo

    var body: some View {
        MetricKPICard(
            icon: "internaldrive.fill",
            title: "Storage",
            tint: storageTint,
            badge: storage.analysis.status.displayName,
            primaryValue: "\(Int(storage.usedPercentage * 100))",
            primarySuffix: "%",
            caption: "\(ByteFormatter.string(from: storage.usedBytes)) of \(ByteFormatter.string(from: storage.totalBytes))",
            progress: storage.usedPercentage,
            footerMetrics: [
                (label: "Free", value: ByteFormatter.string(from: storage.availableBytes)),
                (label: "Health", value: "\(storage.analysis.healthScore)/100"),
                (label: "Used", value: ByteFormatter.string(from: storage.usedBytes)),
                (label: "Total", value: ByteFormatter.string(from: storage.totalBytes))
            ]
        )
    }

    private var storageTint: Color {
        switch storage.usedPercentage {
        case ..<0.7: .green
        case 0.7..<0.85: .orange
        default: .red
        }
    }
}

private extension StorageStatus {
    var displayName: String {
        switch self {
        case .healthy: "Healthy"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }
}

#Preview {
    StorageCard(storage: StorageService().fetchStorageInfo())
        .padding()
        .frame(width: 320)
}
