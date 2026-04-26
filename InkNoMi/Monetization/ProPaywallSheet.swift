import SwiftUI

struct ProPaywallSheet: View {
    @Bindable var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Upgrade to InkNoMi Pro")
                .font(.title3.weight(.semibold))

            if let feature = purchaseManager.requestedFeature {
                Text("Unlock \(feature.displayName) and all Pro tools.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Unlock advanced tools and unlimited boards.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                planButton(.monthly)
                planButton(.yearly)
            }

            HStack(spacing: 14) {
                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .disabled(purchaseManager.isProcessingPurchase)

                Spacer()

                Button("Not now") {
                    purchaseManager.isPaywallPresented = false
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(22)
        .frame(minWidth: 420)
    }

    private func planButton(_ plan: ProPlan) -> some View {
        Button {
            Task { await purchaseManager.purchase(plan: plan) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.headline)
                    Text(plan.displayPrice)
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
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.isProcessingPurchase)
    }
}
