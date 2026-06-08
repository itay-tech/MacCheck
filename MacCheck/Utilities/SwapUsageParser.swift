import Foundation

enum SwapUsageParser {

    struct ParsedSwapUsage {
        let rawLine: String
        let usedValue: Double
        let unit: String
        let bytes: Int64
    }

    /// Parses `sysctl vm.swapusage` output such as:
    /// `vm.swapusage: total = 29696.00M  used = 28645.75M  free = 1050.25M  (encrypted)`
    static func parse(from rawLine: String) -> ParsedSwapUsage? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"used\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*([MGK])?"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
            ),
            match.numberOfRanges >= 2,
            let valueRange = Range(match.range(at: 1), in: trimmed),
            let usedValue = Double(trimmed[valueRange])
        else {
            return nil
        }

        var unit = ""
        if match.numberOfRanges >= 3, let unitRange = Range(match.range(at: 2), in: trimmed) {
            unit = String(trimmed[unitRange]).uppercased()
        }

        guard let bytes = convertToBytes(value: usedValue, unit: unit) else {
            return nil
        }

        return ParsedSwapUsage(
            rawLine: trimmed,
            usedValue: usedValue,
            unit: unit.isEmpty ? "B" : unit,
            bytes: bytes
        )
    }

    // MARK: - Private

    private static func convertToBytes(value: Double, unit: String) -> Int64? {
        guard value >= 0 else { return nil }

        let multiplier: Double
        switch unit {
        case "G": multiplier = 1024 * 1024 * 1024
        case "M": multiplier = 1024 * 1024
        case "K": multiplier = 1024
        case "": multiplier = 1
        default: return nil
        }

        return Int64((value * multiplier).rounded())
    }
}
