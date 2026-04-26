import SwiftUI

/// Hosts the main window with appearance preferences applied (color scheme + environment).
struct FlowDeskRootView: View {
    let appearanceStore: FlowDeskAppearanceStore
    @State private var onboardingStore = FlowDeskOnboardingStore()
    @State private var purchaseManager = PurchaseManager()

    var body: some View {
        @Bindable var appearanceStore = appearanceStore
        MainWindowView()
            .environment(appearanceStore)
            .environment(onboardingStore)
            .environment(purchaseManager)
            .preferredColorScheme(appearanceStore.preferredColorScheme)
    }
}
