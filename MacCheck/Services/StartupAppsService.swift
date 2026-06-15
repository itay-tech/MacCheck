import CoreServices
import Foundation

/// Reads login and launch-at-startup items using public macOS APIs.
final class StartupAppsService {

    private enum SourceAccess {
        case success
        case unavailable
    }

    func fetchStartupApps() -> StartupAppsFetchResult {
        var items: [String: StartupAppInfo] = [:]
        var hadUnavailableSource = false

        let loginItemsResult = readSessionLoginItems()
        if loginItemsResult.access == .unavailable {
            hadUnavailableSource = true
        }
        merge(loginItemsResult.items, into: &items)

        let userAgentsResult = readLaunchAgents(
            at: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        )
        if userAgentsResult.access == .unavailable {
            hadUnavailableSource = true
        }
        merge(userAgentsResult.items, into: &items)

        let systemAgentsResult = readLaunchAgents(
            at: URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true)
        )
        if systemAgentsResult.access == .unavailable {
            hadUnavailableSource = true
        }
        merge(systemAgentsResult.items, into: &items)

        let apps = items.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        let isLimitedData = hadUnavailableSource
        let visibleCount = apps.visibleForScoring.count
        print("[StartupApps] Visible entries: \(visibleCount)")
        print("[StartupApps] Scored entries: \(visibleCount)")

        return StartupAppsFetchResult(
            apps: apps,
            isLimitedData: isLimitedData
        )
    }

    // MARK: - Login Items

    private func readSessionLoginItems() -> (items: [StartupAppInfo], access: SourceAccess) {
        guard
            let list = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeUnretainedValue(),
                nil
            )?.takeRetainedValue()
        else {
            return ([], .unavailable)
        }

        guard
            let snapshot = LSSharedFileListCopySnapshot(list, nil)?
                .takeRetainedValue() as? [LSSharedFileListItem]
        else {
            return ([], .unavailable)
        }

        var items: [StartupAppInfo] = []

        for item in snapshot {
            guard
                let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?
                    .takeRetainedValue() as URL?
            else {
                continue
            }

            let bundleIdentifier = resolveBundleIdentifier(for: url)
            let name = resolveDisplayName(for: url, fallback: bundleIdentifier)

            items.append(
                StartupAppInfo(
                    id: UUID(),
                    name: name,
                    bundleIdentifier: bundleIdentifier,
                    isEnabled: true
                )
            )
        }

        return (items, .success)
    }

    // MARK: - Launch Agents

    private func readLaunchAgents(at directoryURL: URL) -> (items: [StartupAppInfo], access: SourceAccess) {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return ([], .success)
        }

        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            return ([], .unavailable)
        }

        var items: [StartupAppInfo] = []

        for url in urls where url.pathExtension == "plist" {
            guard let item = parseLaunchAgentPlist(at: url) else { continue }
            items.append(item)
        }

        return (items, .success)
    }

    private func parseLaunchAgentPlist(at url: URL) -> StartupAppInfo? {
        guard
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let label = plist["Label"] as? String
        else {
            return nil
        }

        let disabled = plist["Disabled"] as? Bool ?? false
        let runAtLoad = plist["RunAtLoad"] as? Bool ?? true
        let isEnabled = !disabled && runAtLoad

        let executablePath = resolveExecutablePath(from: plist)
        let appURL = executablePath.flatMap { findAppBundleURL(for: $0) }
        let name = appURL.map { resolveDisplayName(for: $0, fallback: label) }
            ?? humanizedLabel(label)

        let bundleIdentifier = appURL.flatMap { resolveBundleIdentifier(for: $0) } ?? label

        return StartupAppInfo(
            id: UUID(),
            name: name,
            bundleIdentifier: bundleIdentifier,
            isEnabled: isEnabled
        )
    }

    // MARK: - Merge & Resolve

    private func merge(_ newItems: [StartupAppInfo], into items: inout [String: StartupAppInfo]) {
        for item in newItems {
            let key = item.bundleIdentifier.lowercased()
            if let existing = items[key] {
                items[key] = StartupAppInfo(
                    id: existing.id,
                    name: preferredName(existing.name, item.name),
                    bundleIdentifier: existing.bundleIdentifier,
                    isEnabled: coalesceEnabled(existing.isEnabled, item.isEnabled)
                )
            } else {
                items[key] = item
            }
        }
    }

    private func preferredName(_ lhs: String, _ rhs: String) -> String {
        lhs.count >= rhs.count ? lhs : rhs
    }

    private func coalesceEnabled(_ lhs: Bool?, _ rhs: Bool?) -> Bool? {
        switch (lhs, rhs) {
        case (true, _), (_, true): return true
        case (false, false): return false
        case (false, nil), (nil, false): return false
        case (nil, nil): return nil
        }
    }

    private func resolveExecutablePath(from plist: [String: Any]) -> String? {
        if let program = plist["Program"] as? String {
            return program
        }

        if
            let arguments = plist["ProgramArguments"] as? [String],
            let executable = arguments.first
        {
            return executable
        }

        return nil
    }

    private func findAppBundleURL(for path: String) -> URL? {
        var url = URL(fileURLWithPath: path)

        if url.pathExtension == "app" {
            return url
        }

        while url.path != "/" {
            if url.pathExtension == "app" {
                return url
            }
            url.deleteLastPathComponent()
        }

        return nil
    }

    private func resolveDisplayName(for url: URL, fallback: String) -> String {
        if
            let bundle = Bundle(url: url),
            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
            !displayName.isEmpty
        {
            return displayName
        }

        if
            let bundle = Bundle(url: url),
            let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
            !bundleName.isEmpty
        {
            return bundleName
        }

        let appName = url.deletingPathExtension().lastPathComponent
        return appName.isEmpty ? humanizedLabel(fallback) : appName
    }

    private func resolveBundleIdentifier(for url: URL) -> String {
        if
            let bundle = Bundle(url: url),
            let identifier = bundle.bundleIdentifier,
            !identifier.isEmpty
        {
            return identifier
        }

        return url.deletingPathExtension().lastPathComponent
    }

    private func humanizedLabel(_ label: String) -> String {
        let lastComponent = label.split(separator: ".").last.map(String.init) ?? label
        return lastComponent.replacingOccurrences(of: "-", with: " ")
    }
}
