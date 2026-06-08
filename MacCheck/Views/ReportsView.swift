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
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
        }
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
        ScrollView {
            ReportsComingSoonPage()
                .padding(MacCheckTheme.Spacing.xl)
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
        ScrollView {
            ReportsLockedPage {
                showPaywall = true
            }
            .padding(.vertical, MacCheckTheme.Spacing.xl)
        }
    }

    private var proContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                DashboardSectionHeader(
                    title: "Reports",
                    subtitle: "Export professional PDF reports for your Mac.",
                    systemImage: "doc.richtext"
                )

                if let statusMessage = viewModel.statusMessage {
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

                ReportsOverviewHero(overview: viewModel.pageData.overview)

                HStack(alignment: .top, spacing: MacCheckTheme.Spacing.xl) {
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
            .padding(MacCheckTheme.Spacing.xl)
            .frame(maxWidth: 1080)
            .frame(maxWidth: .infinity)
        }
    }

    private func reportColumn(model: ReportCardModel, type: ReportType, buttonTitle: String) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
            ReportCard(model: model)

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
