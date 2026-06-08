import Foundation

enum ByteFormatter {

    static func string(from bytes: Int64) -> String {
        formatted(bytes, countStyle: .file, allowedUnits: [.useTB, .useGB, .useMB])
    }

    /// Binary memory units (GiB/MiB) for RAM and swap display.
    static func memoryString(from bytes: Int64) -> String {
        formatted(bytes, countStyle: .memory, allowedUnits: [.useGB, .useMB])
    }

    static func swapString(from bytes: Int64) -> String {
        memoryString(from: bytes)
    }

    static func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    // MARK: - Private

    private static func formatted(
        _ bytes: Int64,
        countStyle: ByteCountFormatter.CountStyle,
        allowedUnits: ByteCountFormatter.Units
    ) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = countStyle
        formatter.allowedUnits = allowedUnits
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}
