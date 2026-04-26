import Foundation
import CoreGraphics
#if canImport(StoreKit)
import StoreKit
#endif
import Observation

enum ProFeatureGate: String, Sendable {
    case convertDiagram
    case smartConvert
    case mindMapAutoLayout
    case highResolutionExport
    case unlimitedBoards

    var displayName: String {
        switch self {
        case .convertDiagram: return "Convert to Diagram"
        case .smartConvert: return "Smart Ink Convert"
        case .mindMapAutoLayout: return "Mind Map Auto Layout"
        case .highResolutionExport: return "High Resolution Export"
        case .unlimitedBoards: return "Unlimited Boards"
        }
    }
}

enum ProPlan: String, CaseIterable, Sendable {
    case monthly
    case yearly

    var displayPrice: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$29.99"
        }
    }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

@Observable
@MainActor
final class PurchaseManager {
    // In v1 we persist this local entitlement. Replace with verified StoreKit entitlement state later.
    var isProUser: Bool {
        didSet { UserDefaults.standard.set(isProUser, forKey: Self.proUserDefaultsKey) }
    }

    var isPaywallPresented = false
    var requestedFeature: ProFeatureGate?
    var purchaseMessage: String?
    var isProcessingPurchase = false

    static let freeBoardLimit = 3
    static let freeExportScale: CGFloat = 1
    static let proExportScale: CGFloat = CanvasExportService.defaultRenderScale
    private static let proUserDefaultsKey = "InkNoMi.ProUser"

    init() {
        isProUser = UserDefaults.standard.bool(forKey: Self.proUserDefaultsKey)
    }

    func requirePro(for feature: ProFeatureGate) -> Bool {
        if isProUser { return true }
        requestedFeature = feature
        isPaywallPresented = true
        return false
    }

    func purchase(plan: ProPlan) async {
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        #if canImport(StoreKit)
        // TODO: Replace this placeholder with Product.products(for:) + verified transaction flow.
        _ = plan
        #else
        _ = plan
        #endif

        isProUser = true
        purchaseMessage = "InkNoMi Pro unlocked."
        isPaywallPresented = false
    }

    func restorePurchases() async {
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        #if canImport(StoreKit)
        // TODO: Replace this placeholder with AppStore.sync() and entitlement verification.
        #endif

        purchaseMessage = isProUser ? "Purchases restored." : "No prior Pro purchase found."
    }
}
