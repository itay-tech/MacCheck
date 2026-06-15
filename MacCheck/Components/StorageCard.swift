import SwiftUI

struct StorageCard: View {
    let storage: StorageInfo
    var storageScore: Int

    var body: some View {
        MetricKPICard(
            icon: "internaldrive.fill",
            title: "Storage",
            tint: storage.analysis.status.semanticColor,
            badge: storage.analysis.status.displayName,
            primaryValue: "\(Int(storage.usedPercentage * 100))",
            primarySuffix: "%",
            caption: "\(ByteFormatter.string(from: storage.usedBytes)) of \(ByteFormatter.string(from: storage.totalBytes))",
            help: .storage,
            subsystemScore: storageScore,
            progress: storage.usedPercentage,
            footerMetrics: [
                (label: "Free", value: ByteFormatter.string(from: storage.availableBytes)),
                (label: "Health", value: "\(storage.analysis.healthScore)/100"),
                (label: "Used", value: ByteFormatter.string(from: storage.usedBytes)),
                (label: "Total", value: ByteFormatter.string(from: storage.totalBytes))
            ]
        )
    }
}

#Preview {
    StorageCard(storage: StorageService().fetchStorageInfo(), storageScore: 88)
        .padding()
        .frame(width: 320)
}
