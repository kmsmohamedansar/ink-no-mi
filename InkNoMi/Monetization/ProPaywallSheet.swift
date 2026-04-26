import SwiftUI

struct ProPaywallSheet: View {
    @Bindable var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Unlock your full workspace")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Create unlimited boards, access advanced templates, and build without limits.")
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
            }
            .font(.caption)
            .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.md) {
                Button("Continue") {
                    Task { await purchaseManager.purchase(plan: .yearly) }
                }
                .disabled(purchaseManager.isProcessingPurchase)
                .buttonStyle(.borderedProminent)

                Button("Not now") {
                    purchaseManager.isPaywallPresented = false
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textSecondary)

                Spacer()

                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .disabled(purchaseManager.isProcessingPurchase)
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(DS.Spacing.xl)
        .frame(minWidth: 460)
    }

    private func planButton(_ plan: ProPlan, highlighted: Bool = false) -> some View {
        Button {
            Task { await purchaseManager.purchase(plan: plan) }
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
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(DS.Color.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .stroke(highlighted ? DS.Color.accent.opacity(0.34) : DS.Color.border)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.isProcessingPurchase)
    }
}
