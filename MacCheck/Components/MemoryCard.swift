import SwiftUI

struct MemoryCard: View {
    let memory: MemoryInfo
    var memoryScore: Int

    @State private var isLiveEnabled = MemoryLivePreferences.isLiveEnabled
    @StateObject private var liveMonitor = MemoryLiveMonitor()

    private var displayedMemory: MemoryInfo {
        if isLiveEnabled, let liveMemory = liveMonitor.memory {
            return liveMemory
        }
        return memory
    }

    var body: some View {
        MetricKPICard(
            icon: "memorychip.fill",
            title: "Memory",
            tint: HealthScoreColor.color(for: memoryScore),
            badge: displayedMemory.status.displayName,
            primaryValue: "\(Int((displayedMemory.usedPercentage * 100).rounded()))",
            primarySuffix: "%",
            caption: "\(ByteFormatter.string(from: displayedMemory.usedMemoryBytes)) of \(ByteFormatter.string(from: displayedMemory.totalMemoryBytes))",
            help: .memory,
            subsystemScore: memoryScore,
            animatesValueChanges: isLiveEnabled,
            headerAccessory: AnyView(liveToggle),
            progress: displayedMemory.usedPercentage,
            footerMetrics: [
                (label: "Swap", value: ByteFormatter.swapString(from: displayedMemory.swapUsedBytes)),
                (label: "Cached", value: ByteFormatter.string(from: displayedMemory.cachedFilesBytes)),
                (label: "Free", value: ByteFormatter.string(from: displayedMemory.freeMemoryBytes)),
                (label: "Total", value: ByteFormatter.string(from: displayedMemory.totalMemoryBytes))
            ]
        )
        .onAppear {
            if isLiveEnabled {
                liveMonitor.start(initial: memory)
            }
        }
        .onDisappear {
            liveMonitor.stop()
        }
        .onChange(of: isLiveEnabled) { _, enabled in
            MemoryLivePreferences.isLiveEnabled = enabled

            if enabled {
                PostHogService.shared.track(.memoryLiveEnabled)
                liveMonitor.start(initial: memory)
            } else {
                PostHogService.shared.track(.memoryLiveDisabled)
                liveMonitor.stop()
            }
        }
    }

    private var liveToggle: some View {
        Toggle(isOn: $isLiveEnabled) {
            Text("Live")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .fixedSize()
    }
}

#Preview {
    MemoryCard(memory: MemoryService().fetchMemoryInfo(), memoryScore: 76)
        .padding()
        .frame(width: 320)
}
