import AppKit
import SwiftUI

/// Flip `ReportsFeatureFlags.exportEnabled` to restore the full PDF export experience.
private enum ReportsFeatureFlags {
    static let exportEnabled = false
}

struct ReportsView: View {
    @ObservedObject var viewModel: ReportsViewModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var errorAlertMessage = ""
    @State private var successFileURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if ReportsFeatureFlags.exportEnabled {
                    exportContent
                } else {
                    comingSoonContent
                }
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("Reports")
            .toolbar { toolbarContent }
        }
        .proPaywallSheet(isPresented: $showPaywall)
        .modifier(ExportAlertsModifier(
            isEnabled: ReportsFeatureFlags.exportEnabled,
            showErrorAlert: $showErrorAlert,
            showSuccessAlert: $showSuccessAlert,
            errorAlertMessage: errorAlertMessage,
            successFileURL: successFileURL,
            onDismissError: { viewModel.exportError = nil },
            onDismissSuccess: dismissSuccessAlert
        ))
        .onAppear {
            guard ReportsFeatureFlags.exportEnabled else { return }
            if entitlementManager.hasAccess(to: .pdfExport) {
                viewModel.refresh()
            }
        }
        .onChange(of: viewModel.exportError) { _, newValue in
            guard ReportsFeatureFlags.exportEnabled, let newValue else { return }
            errorAlertMessage = newValue
            showErrorAlert = true
        }
        .onChange(of: viewModel.exportedFileURL) { _, newValue in
            guard ReportsFeatureFlags.exportEnabled, let newValue else { return }
            successFileURL = newValue
            showSuccessAlert = true
        }
    }

    // MARK: - Coming Soon

    private var comingSoonContent: some View {
        ReportsScrollContainer {
            ReportsComingSoonPage()
        }
    }

    // MARK: - Export (disabled — set `ReportsFeatureFlags.exportEnabled` to re-enable)

    @ViewBuilder
    private var exportContent: some View {
        if entitlementManager.hasAccess(to: .pdfExport) {
            proContent
        } else {
            lockedContent
        }
    }

    private var lockedContent: some View {
        ReportsScrollContainer(
            verticalCentering: true,
            maxWidth: MacCheckTheme.Layout.focusedMaxWidth
        ) {
            ReportsLockedPage {
                showPaywall = true
            }
        }
    }

    private var proContent: some View {
        ReportsScrollContainer {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                DashboardSectionHeader(
                    title: "Reports",
                    subtitle: "Export professional PDF reports for your Mac.",
                    systemImage: "doc.richtext"
                )

                if let statusMessage = viewModel.statusMessage {
                    exportStatusBanner(statusMessage)
                }

                ReportsOverviewHero(overview: viewModel.pageData.overview)

                reportCardsGrid
            }
        }
    }

    // MARK: - Report Grid

    private var reportCardsGrid: some View {
        ViewThatFits(in: .horizontal) {
            reportCardsRow
            reportCardsStack
        }
    }

    private var reportCardsRow: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.xl) {
            reportColumn(
                model: viewModel.pageData.healthReport,
                type: .health,
                buttonTitle: "Generate Health Report"
            )
            .frame(minWidth: MacCheckTheme.Layout.reportCardMinWidth)
            .frame(maxWidth: .infinity)

            reportColumn(
                model: viewModel.pageData.inspectionReport,
                type: .usedMacInspection,
                buttonTitle: "Generate Inspection Report"
            )
            .frame(minWidth: MacCheckTheme.Layout.reportCardMinWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var reportCardsStack: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xl) {
            reportColumn(
                model: viewModel.pageData.healthReport,
                type: .health,
                buttonTitle: "Generate Health Report"
            )

            reportColumn(
                model: viewModel.pageData.inspectionReport,
                type: .usedMacInspection,
                buttonTitle: "Generate Inspection Report"
            )
        }
    }

    private func exportStatusBanner(_ statusMessage: String) -> some View {
        HStack(spacing: MacCheckTheme.Spacing.sm) {
            ProgressView()
                .controlSize(.small)
            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(MacCheckTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacCheckTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.sm, style: .continuous))
    }

    private func reportColumn(model: ReportCardModel, type: ReportType, buttonTitle: String) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            ReportCard(model: model)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            generateButton(title: buttonTitle, type: type)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func generateButton(title: String, type: ReportType) -> some View {
        let isGenerating = viewModel.isGenerating(type)

        return Button {
            viewModel.generateReport(for: type)
        } label: {
            HStack(spacing: MacCheckTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isGenerating ? "Generating…" : title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonRepeatBehavior(.disabled)
        .controlSize(.large)
        .disabled(viewModel.isExportInProgress)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ProUpgradeToolbarContent(showPaywall: $showPaywall)
    }

    private func dismissSuccessAlert() {
        showSuccessAlert = false
        successFileURL = nil
        viewModel.clearExportSuccess()
    }
}

// MARK: - Scroll Container

private struct ReportsScrollContainer<Content: View>: View {
    var verticalCentering: Bool = false
    var maxWidth: CGFloat = MacCheckTheme.Layout.contentMaxWidth
    private let content: Content

    init(
        verticalCentering: Bool = false,
        maxWidth: CGFloat = MacCheckTheme.Layout.contentMaxWidth,
        @ViewBuilder content: () -> Content
    ) {
        self.verticalCentering = verticalCentering
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Group {
                    if verticalCentering {
                        VStack(spacing: 0) {
                            Spacer(minLength: MacCheckTheme.Spacing.xxl)
                            content
                                .frame(maxWidth: maxWidth)
                                .frame(maxWidth: .infinity)
                            Spacer(minLength: MacCheckTheme.Spacing.xxl)
                        }
                    } else {
                        content
                            .macCheckCenteredContent(maxWidth: maxWidth)
                    }
                }
                .padding(MacCheckTheme.Spacing.xl)
                .frame(minHeight: verticalCentering ? geometry.size.height : nil)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Export Alerts

private struct ExportAlertsModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showErrorAlert: Bool
    @Binding var showSuccessAlert: Bool
    let errorAlertMessage: String
    let successFileURL: URL?
    let onDismissError: () -> Void
    let onDismissSuccess: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .alert("Report Export Failed", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel, action: onDismissError)
                } message: {
                    Text(errorAlertMessage)
                }
                .alert("Report exported successfully.", isPresented: $showSuccessAlert) {
                    Button("Open File") {
                        if let successFileURL {
                            NSWorkspace.shared.open(successFileURL)
                        }
                        onDismissSuccess()
                    }
                    Button("Reveal in Finder") {
                        if let successFileURL {
                            NSWorkspace.shared.activateFileViewerSelecting([successFileURL])
                        }
                        onDismissSuccess()
                    }
                    Button("OK", role: .cancel, action: onDismissSuccess)
                }
        } else {
            content
        }
    }
}

#Preview("Coming Soon") {
    let store = AppStore()
    return ReportsView(viewModel: store.reportsViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .frame(width: 900, height: 800)
}
