import StoreKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var analyticsConsentManager: AnalyticsConsentManager
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var showPaywall = false
    @State private var showExportPlaceholder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                    DashboardSectionHeader(
                        title: "Settings",
                        subtitle: "App preferences, privacy, and data management.",
                        systemImage: "gearshape"
                    )

                    proStatusSection
                    privacySection
                    dataManagementSection
                    supportSection
                    aboutSection
                    appInformationSection
                }
                .padding(MacCheckTheme.Spacing.xl)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(MacCheckTheme.secondaryBackground)
            .navigationTitle("Settings")
            .toolbar {
                ProUpgradeToolbarContent(showPaywall: $showPaywall)
            }
            .onAppear {
                viewModel.refreshDataStats()
            }
        }
        .proPaywallSheet(isPresented: $showPaywall, source: .settings)
        .confirmationDialog(
            "Clear History?",
            isPresented: $viewModel.showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete History", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all stored health snapshots.")
        }
        .alert("History Cleared", isPresented: $viewModel.showClearSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All stored health snapshots have been removed from this Mac.")
        }
        .alert(
            "Could Not Clear History",
            isPresented: Binding(
                get: { viewModel.clearHistoryError != nil },
                set: { if !$0 { viewModel.clearHistoryError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.clearHistoryError = nil
            }
        } message: {
            Text(viewModel.clearHistoryError ?? "")
        }
        .alert("Export History", isPresented: $showExportPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("History export will be available in a future update.")
        }
    }

    // MARK: - Pro Status

    private var proStatusSection: some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            if entitlementManager.isPro {
                proActiveCard
            } else {
                freePlanCard
            }

            SettingsCard {
                VStack(spacing: MacCheckTheme.Spacing.md) {
                    SettingsActionRow(
                        title: "Check for Updates",
                        systemImage: "arrow.triangle.2.circlepath"
                    ) {
                        openURL(AppLinks.checkForUpdatesURL)
                    }

                    SettingsActionRow(
                        title: "Rate MacCheck",
                        systemImage: "star"
                    ) {
                        requestReview()
                    }
                }
            }
        }
    }

    private var proActiveCard: some View {
        HStack(alignment: .center, spacing: MacCheckTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(MacCheckTheme.proGradient.opacity(0.18))
                    .frame(width: 56, height: 56)

                Image(systemName: "crown.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MacCheckTheme.proGradient)
            }

            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Text("Pro Active")
                        .font(.title3.weight(.bold))
                    ProBadge()
                }

                Text("Lifetime Access")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .macCheckHeroCard()
    }

    private var freePlanCard: some View {
        SettingsCard {
            HStack(alignment: .center, spacing: MacCheckTheme.Spacing.lg) {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                    Text("Free Plan")
                        .font(.title3.weight(.bold))

                    Text("Upgrade to unlock full history, predictions, and advanced charts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: MacCheckTheme.Spacing.md)

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Pro")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - App Information

    private var appInformationSection: some View {
        settingsSection(
            title: "App Information",
            subtitle: "Version details for this installation",
            systemImage: "info.circle"
        ) {
            SettingsCard {
                VStack(spacing: MacCheckTheme.Spacing.md) {
                    SettingsInfoRow(label: "App Name", value: AppMetadata.appName)
                    SettingsInfoRow(label: "Version", value: AppMetadata.version)
                    SettingsInfoRow(label: "Build", value: AppMetadata.buildNumber)
                    SettingsInfoRow(
                        label: "Health Score Engine",
                        value: "v\(AppMetadata.healthScoreEngineVersion)"
                    )
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        settingsSection(
            title: "Privacy",
            subtitle: "How MacCheck handles your data",
            systemImage: "hand.raised.fill"
        ) {
            SettingsCard {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
                    SettingsBulletRow(text: "All health data stays on this Mac.")
                    SettingsBulletRow(text: "No cloud sync.")
                    SettingsBulletRow(text: "Optional anonymous usage analytics can be enabled below.")
                    SettingsBulletRow(text: "No personal files, documents, serial numbers, or health history are collected.")

                    if analyticsConsentManager.hasMadeDecision {
                        Toggle("Share Anonymous Analytics", isOn: analyticsToggleBinding)
                            .font(.subheadline.weight(.medium))
                    }

                    Divider()
                        .padding(.vertical, MacCheckTheme.Spacing.xs)

                    Button {
                        openURL(AppLinks.privacyPolicy)
                    } label: {
                        HStack(spacing: MacCheckTheme.Spacing.sm) {
                            Text("View Privacy Policy")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        settingsSection(
            title: "Data Management",
            subtitle: "Local snapshot storage on this Mac",
            systemImage: "externaldrive"
        ) {
            SettingsCard {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
                    VStack(spacing: MacCheckTheme.Spacing.md) {
                        SettingsInfoRow(
                            label: "Total Snapshots",
                            value: "\(viewModel.snapshotCount)"
                        )
                        SettingsInfoRow(
                            label: "Oldest Snapshot",
                            value: formattedDate(viewModel.oldestSnapshotDate)
                        )
                        SettingsInfoRow(
                            label: "Newest Snapshot",
                            value: formattedDate(viewModel.newestSnapshotDate)
                        )
                    }

                    VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xs) {
                        Text("Storage Path")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.snapshotsFilePath)
                            .font(.caption)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    HStack(spacing: MacCheckTheme.Spacing.md) {
                        Button("Export History") {
                            showExportPlaceholder = true
                        }
                        .buttonStyle(.bordered)

                        Button("Clear History", role: .destructive) {
                            viewModel.showClearConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.snapshotCount == 0)
                    }
                }
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        settingsSection(
            title: "Support",
            subtitle: "Get help or report a problem",
            systemImage: "lifepreserver"
        ) {
            SettingsCard {
                HStack(spacing: MacCheckTheme.Spacing.md) {
                    Button("Contact Support") {
                        openURL(AppLinks.contactSupportURL)
                    }
                    .buttonStyle(.bordered)

                    Button("Report Issue") {
                        openURL(AppLinks.reportIssueURL)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        settingsSection(
            title: "About MacCheck",
            subtitle: nil,
            systemImage: "desktopcomputer"
        ) {
            SettingsCard {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.md) {
                    Text("MacCheck helps monitor battery health, storage usage, memory pressure and overall Mac performance over time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("About MacCheck") {
                        openURL(AppLinks.aboutMacCheck)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Helpers

    private var analyticsToggleBinding: Binding<Bool> {
        Binding(
            get: { analyticsConsentManager.isEnabled },
            set: { analyticsConsentManager.setEnabled($0) }
        )
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String?,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.lg) {
            DashboardSectionHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )
            content()
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    let store = AppStore()
    return SettingsView(viewModel: store.settingsViewModel)
        .environmentObject(store.entitlementManager)
        .environmentObject(store.storeKitManager)
        .environmentObject(store.analyticsConsentManager)
        .frame(width: 900, height: 900)
}
