import Foundation

enum ProFeature: String, Sendable, CaseIterable {
    case unlimitedBoards
    case advancedTemplates
    case appearanceCustomization
    case highResExport
    case smartConvert

    var displayName: String {
        switch self {
        case .unlimitedBoards: return "Unlimited Boards"
        case .advancedTemplates: return "Advanced Templates"
        case .appearanceCustomization: return "Appearance Customization"
        case .highResExport: return "High Resolution Export"
        case .smartConvert: return "Smart Convert"
        }
    }
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
