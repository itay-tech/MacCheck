import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    @State private var showRestoreNotice = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.xxl) {
                    FeatureComparisonSection(rows: FeatureComparisonCatalog.rows)
                    ProBenefitsSection(benefits: FeatureComparisonCatalog.benefits)
                    PricingSection(plan: PricingPlanCatalog.lifetime)
                    actionSection
                }
                .padding(MacCheckTheme.Spacing.xl)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 680, idealHeight: 860)
        .background(MacCheckTheme.secondaryBackground)
        .alert("Restore Purchases", isPresented: $showRestoreNotice) {
            Button("OK", role: .cancel) {
                storeKitManager.clearRestoreNotice()
            }
        } message: {
            Text(storeKitManager.restoreNotice ?? "")
        }
        .onChange(of: storeKitManager.restoreNotice) { _, newValue in
            showRestoreNotice = newValue != nil
        }
        .onAppear {
            storeKitManager.printPaywallDiagnostics(context: "Paywall appear (before reload)")
            Task {
                await storeKitManager.loadProductsIfNeeded(force: true)
                storeKitManager.printPaywallDiagnostics(context: "Paywall appear (after reload)")
            }
        }
        .onChange(of: storeKitManager.canPurchase) { _, _ in
            storeKitManager.printPaywallDiagnostics(context: "canPurchase changed")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: MacCheckTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MacCheckTheme.Spacing.sm) {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    Image(systemName: "crown.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(MacCheckTheme.proGradient)

                    Text("Upgrade to MacCheck Pro")
                        .font(.title2.weight(.bold))
                }

                Text("Unlock advanced monitoring, predictions and long-term Mac insights.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: MacCheckTheme.Spacing.md)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(MacCheckTheme.Spacing.xl)
        .background {
            MacCheckTheme.proGradient
                .opacity(0.07)
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: MacCheckTheme.Spacing.md) {
            if let error = storeKitManager.productLoadError, !storeKitManager.isLoadingProducts {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let error = storeKitManager.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if entitlementManager.isPro {
                proMemberStatus
            } else {
                purchaseActions
            }

            legalNote
        }
        .padding(.top, MacCheckTheme.Spacing.sm)
    }

    private var proMemberStatus: some View {
        VStack(spacing: MacCheckTheme.Spacing.sm) {
            Label("You're a Pro member", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
    }

    private var purchaseActions: some View {
        VStack(spacing: MacCheckTheme.Spacing.sm) {
            Button {
                Task { await storeKitManager.purchaseLifetime() }
            } label: {
                HStack(spacing: MacCheckTheme.Spacing.sm) {
                    if storeKitManager.isPurchasing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Unlock Pro")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!storeKitManager.canPurchase)

            Button("Restore Purchases") {
                Task { await storeKitManager.restorePurchases() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(storeKitManager.isPurchasing)
        }
    }

    private var legalNote: some View {
        Text("One-time purchase through the App Store.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview("Free User") {
    let entitlementManager = EntitlementManager()
    return PaywallView()
        .environmentObject(StoreKitManager(entitlementManager: entitlementManager))
        .environmentObject(entitlementManager)
}
