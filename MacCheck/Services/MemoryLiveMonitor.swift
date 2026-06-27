import Combine
import Foundation

/// Session-only preference for the Memory card live toggle.
@MainActor
enum MemoryLivePreferences {
    static var isLiveEnabled = false
}

/// Polls memory metrics once per second without touching dashboard report generation.
@MainActor
final class MemoryLiveMonitor: ObservableObject {

    @Published private(set) var memory: MemoryInfo?

    private let memoryService: MemoryService
    private var timer: Timer?
    private var isRunning = false

    init(memoryService: MemoryService = MemoryService()) {
        self.memoryService = memoryService
    }

    func start(initial: MemoryInfo) {
        guard !isRunning else { return }

        isRunning = true
        memory = initial
        refresh()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        #if DEBUG
        print("[MemoryLive] Started")
        #endif
    }

    func stop() {
        guard isRunning else { return }

        timer?.invalidate()
        timer = nil
        isRunning = false

        #if DEBUG
        print("[MemoryLive] Stopped")
        #endif
    }

    private func refresh() {
        memory = memoryService.fetchMemoryInfo(preferFastSwapRead: true)
    }
}
