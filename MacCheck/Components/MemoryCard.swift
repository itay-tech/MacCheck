import SwiftUI

struct MemoryCard: View {
    let memory: MemoryInfo
    var memoryScore: Int

    var body: some View {
        MetricKPICard(
            icon: "memorychip.fill",
            title: "Memory",
            tint: HealthScoreColor.color(for: memoryScore),
            badge: memory.status.displayName,
            primaryValue: "\(Int((memory.usedPercentage * 100).rounded()))",
            primarySuffix: "%",
            caption: "\(ByteFormatter.string(from: memory.usedMemoryBytes)) of \(ByteFormatter.string(from: memory.totalMemoryBytes))",
            help: .memory,
            subsystemScore: memoryScore,
            progress: memory.usedPercentage,
            footerMetrics: [
                (label: "Swap", value: ByteFormatter.swapString(from: memory.swapUsedBytes)),
                (label: "Cached", value: ByteFormatter.string(from: memory.cachedFilesBytes)),
                (label: "Free", value: ByteFormatter.string(from: memory.freeMemoryBytes)),
                (label: "Total", value: ByteFormatter.string(from: memory.totalMemoryBytes))
            ]
        )
    }
}

#Preview {
    MemoryCard(memory: MemoryService().fetchMemoryInfo(), memoryScore: 76)
        .padding()
        .frame(width: 320)
}
