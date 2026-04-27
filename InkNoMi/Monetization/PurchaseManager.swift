import Foundation
import CoreGraphics
#if canImport(StoreKit)
import StoreKit
#endif
import Observation

enum ProFeature: String, Sendable, CaseIterable {
    case unlimitedBoards
    case advancedTemplates
    case appearanceCustomization
    case highResExport
    case smartConvert
}

@MainActor
struct FeatureGate {
    private let purchaseManager: PurchaseManager

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
    }

    func canUse(_ feature: ProFeature) -> Bool {
        if purchaseManager.isProUser { return true }
        switch feature {
        case .unlimitedBoards, .advancedTemplates, .appearanceCustomization, .highResExport, .smartConvert:
            return false
        }
    }

    @discardableResult
    func requirePro(_ feature: ProFeature, source: String) -> Bool {
        guard !canUse(feature) else { return true }
        purchaseManager.presentUpgrade(for: feature, source: source)
        return false
    }
}

enum ProPlan: String, CaseIterable, Sendable {
    case monthly
    case yearly

    var displayPrice: String {
        switch self {
        case .monthly: return "$4.99 / month"
        case .yearly: return "$29.99 / year"
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
    var requestedFeature: ProFeature?
    var paywallSource: String?
    var purchaseMessage: String?
    var isProcessingPurchase = false

    static let freeBoardLimit = 3
    static let freeExportScale: CGFloat = 1
    static let proExportScale: CGFloat = CanvasExportService.defaultRenderScale
    private static let proUserDefaultsKey = "InkNoMi.ProUser"

    init() {
        isProUser = UserDefaults.standard.bool(forKey: Self.proUserDefaultsKey)
    }

    func presentUpgrade(for feature: ProFeature, source: String) {
        requestedFeature = feature
        paywallSource = source
        isPaywallPresented = true
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
