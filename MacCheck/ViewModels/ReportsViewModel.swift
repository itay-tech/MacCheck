import Combine
import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published private(set) var pageData: ReportsPageData = .empty
    @Published private(set) var generatingReportType: ReportType?
    @Published var statusMessage: String?
    @Published var exportError: String?
    @Published var exportedFileURL: URL?

    private let dashboardViewModel: DashboardViewModel
    private var cancellables = Set<AnyCancellable>()

    init(dashboardViewModel: DashboardViewModel) {
        self.dashboardViewModel = dashboardViewModel

        dashboardViewModel.$report
            .combineLatest(dashboardViewModel.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, isLoading in
                guard let self, !isLoading else { return }
                self.refresh()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        if dashboardViewModel.report == nil, !dashboardViewModel.isLoading {
            dashboardViewModel.loadReport()
        }
        pageData = ReportGeneratorService.buildPageData(report: dashboardViewModel.report)
    }

    func generateReport(for type: ReportType) {
        guard generatingReportType == nil else { return }

        generatingReportType = type
        statusMessage = "Preparing report…"
        exportError = nil
        exportedFileURL = nil

        guard let report = dashboardViewModel.report else {
            generatingReportType = nil
            statusMessage = nil
            exportError = "Run a scan first."
            return
        }

        Task { @MainActor in
            defer {
                generatingReportType = nil
                statusMessage = nil
            }

            do {
                statusMessage = "Generating PDF…"
                let pdfData = try PDFExportService.generatePDF(for: type, from: report)
                statusMessage = "Choose where to save…"
                let filename = PDFExportService.suggestedFilename(for: type)
                let destination = try await PDFExportService.presentSavePanel(
                    data: pdfData,
                    suggestedFilename: filename
                )
                exportedFileURL = destination
            } catch PDFExportError.userCancelled {
                return
            } catch {
                exportError = error.localizedDescription
            }
        }
    }

    func clearExportSuccess() {
        exportedFileURL = nil
    }

    var isExportInProgress: Bool {
        generatingReportType != nil
    }

    func isGenerating(_ type: ReportType) -> Bool {
        generatingReportType == type
    }
}
