import SwiftUI

/// Hosts the main window with appearance preferences applied (color scheme + environment).
struct FlowDeskRootView: View {
    @ObservedObject var appearanceStore: AppearanceManager
    @State private var purchaseManager = PurchaseManager()

    var body: some View {
        MainWindowView()
        .environmentObject(appearanceStore)
        .environment(purchaseManager)
        .preferredColorScheme(appearanceStore.settings.appearanceMode.preferredColorScheme)
    }
}
