import SwiftUI

struct ProPaywallSheet: View {
    @Bindable var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var hoveredPlan: ProPlan?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Unlock your full workspace")
                    .font(.title2.weight(.semibold))
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
        }
        .padding(24)
        .frame(minWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 40, x: 0, y: 20)
        )
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
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(Color.white.opacity(hoveredPlan == plan ? 0.06 : 0))
                    .blendMode(.overlay)
            }
            .scaleEffect(hoveredPlan == plan ? DS.Interaction.hoverScale : 1)
            .offset(y: hoveredPlan == plan ? -1 : 0)
            .animation(.easeOut(duration: DS.Interaction.hoverDuration), value: hoveredPlan == plan)
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.isProcessingPurchase)
        .onHover { inside in
            hoveredPlan = inside ? plan : nil
        }
    }
}
