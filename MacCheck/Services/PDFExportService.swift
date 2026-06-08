import AppKit
import Foundation
import UniformTypeIdentifiers

enum PDFExportError: Error, LocalizedError {
    case missingData
    case generationFailed
    case userCancelled
    case savePanelUnavailable
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingData:
            "Run a scan first."
        case .generationFailed:
            "MacCheck could not generate the PDF report."
        case .userCancelled:
            nil
        case .savePanelUnavailable:
            "Unable to open save dialog. Please try again."
        case .writeFailed(let detail):
            "Could not write the PDF file: \(detail)"
        }
    }
}

enum PDFExportService {

    static func generatePDF(for type: ReportType, from report: HealthReport) throws -> Data {
        let data: Data?
        switch type {
        case .health:
            data = HealthReportPDFBuilder.build(from: report)
        case .usedMacInspection:
            data = InspectionReportPDFBuilder.build(from: report)
        }

        guard let data, !data.isEmpty else {
            throw PDFExportError.generationFailed
        }

        return data
    }

    static func suggestedFilename(for type: ReportType) -> String {
        let date = filenameDateFormatter.string(from: Date())
        switch type {
        case .health:
            return "MacCheck_Health_Report_\(date).pdf"
        case .usedMacInspection:
            return "MacCheck_Inspection_Report_\(date).pdf"
        }
    }

    @MainActor
    static func presentSavePanel(data: Data, suggestedFilename: String) async throws -> URL {
        NSApp.activate(ignoringOtherApps: true)

        guard let window = hostWindow() else {
            throw PDFExportError.savePanelUnavailable
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = suggestedFilename
        panel.title = "Save Report"
        panel.message = "Choose where to save your MacCheck report."
        panel.prompt = "Save"
        panel.isReleasedWhenClosed = false

        let response = await withCheckedContinuation { continuation in
            panel.beginSheetModal(for: window) { response in
                continuation.resume(returning: response)
            }
        }

        guard response == .OK, let destination = panel.url else {
            throw PDFExportError.userCancelled
        }

        try writePDF(data, to: destination)
        return destination
    }

    // MARK: - Private

    @MainActor
    private static func hostWindow() -> NSWindow? {
        if let keyWindow = NSApp.keyWindow, keyWindow.isVisible {
            return keyWindow
        }

        if let mainWindow = NSApp.mainWindow, mainWindow.isVisible {
            return mainWindow
        }

        return NSApp.windows.first { window in
            window.isVisible && window.canBecomeKey
        }
    }

    private static func writePDF(_ data: Data, to destination: URL) throws {
        let didAccessSecurityScope = destination.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                destination.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            throw PDFExportError.writeFailed(error.localizedDescription)
        }
    }

    private static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
