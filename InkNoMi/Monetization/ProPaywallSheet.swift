import SwiftUI

struct ProPaywallSheet: View {
    @Bindable var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var hoveredPlan: ProPlan?
    @State private var selectedPlan: ProPlan = .yearly

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Unlock InkNoMi Pro")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Build unlimited workspaces, use advanced templates, and export in high quality.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                planButton(.monthly)
                planButton(.yearly, highlighted: true)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Label("Cancel anytime", systemImage: "checkmark.circle")
                Label("No data loss", systemImage: "lock.shield")
                Label("Secure checkout via Apple", systemImage: "checkmark.shield")
            }
            .font(.caption)
            .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.md) {
                Button(primaryCTAButtonTitle) {
                    Task { await purchaseManager.purchase(plan: selectedPlan) }
                }
                .disabled(purchaseManager.isProcessingPurchase)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.Color.accent)
                )
                .foregroundStyle(.white)

                Button("Not now") {
                    purchaseManager.isPaywallPresented = false
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textTertiary)

                Spacer()

                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .disabled(purchaseManager.isProcessingPurchase)
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textSecondary)
            }

            Text("You can keep using existing boards on Free. Upgrade only unlocks advanced limits and exports.")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
            Text(planDisclosureText)
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(24)
        .frame(minWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 18, x: 0, y: 8)
        )
    }

    private func planButton(_ plan: ProPlan, highlighted: Bool = false) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.headline)
                    HStack(spacing: DS.Spacing.xs) {
                        Text(plan.displayPrice)
                        if highlighted {
                            Text("Best value")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, DS.Spacing.xs + 2)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DS.Color.active)
                                )
                        }
                    }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if purchaseManager.isProcessingPurchase {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? DS.Color.accent : .secondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(DS.Color.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .stroke(
                                isSelected ? DS.Color.accent.opacity(0.48) : (highlighted ? DS.Color.accent.opacity(0.34) : DS.Color.border),
                                lineWidth: isSelected ? 1 : 0.8
                            )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(Color.white.opacity(hoveredPlan == plan ? 0.035 : 0))
                    .blendMode(.overlay)
            }
            .scaleEffect(hoveredPlan == plan ? 1.008 : 1)
            .offset(y: hoveredPlan == plan ? -1 : 0)
            .animation(.easeOut(duration: DS.Interaction.hoverDuration), value: hoveredPlan == plan)
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.isProcessingPurchase)
        .onHover { inside in
            hoveredPlan = inside ? plan : nil
        }
    }

    private var primaryCTAButtonTitle: String {
        purchaseManager.isProcessingPurchase ? "Processing..." : "Start Pro - \(selectedPlan.displayPrice)"
    }

    private var planDisclosureText: String {
        switch selectedPlan {
        case .monthly:
            return "Billed monthly. Manage or cancel anytime in App Store subscriptions."
        case .yearly:
            return "Billed yearly. Manage or cancel anytime in App Store subscriptions."
        }
    }
}
