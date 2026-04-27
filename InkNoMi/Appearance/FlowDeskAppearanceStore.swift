import SwiftUI

final class AppearanceManager: ObservableObject {
    @Published var settings: AppAppearanceSettings {
        didSet {
            saveSettings()
            applyTheme()
        }
    }

    private let defaults: UserDefaults
    private let storageKey = "InkNoMi.AppearanceSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = .default
        loadSettings()
        applyTheme()
    }

    func applyTheme() {
        objectWillChange.send()
    }

    func resetToDefaults() {
        settings = .default
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func loadSettings() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(AppAppearanceSettings.self, from: data)
        else {
            settings = .default
            return
        }
        settings = decoded
    }
}

typealias FlowDeskAppearanceStore = AppearanceManager

// MARK: - Environment

private enum FlowDeskAppearanceStoreKey: EnvironmentKey {
    static let defaultValue = AppearanceManager()
}

private enum FlowDeskAppearanceTokensKey: EnvironmentKey {
    static let defaultValue = DynamicTheme.fallback
}

extension EnvironmentValues {
    var flowDeskAppearanceStore: AppearanceManager {
        get { self[FlowDeskAppearanceStoreKey.self] }
        set { self[FlowDeskAppearanceStoreKey.self] = newValue }
    }

    var flowDeskTokens: DynamicTheme {
        get { self[FlowDeskAppearanceTokensKey.self] }
        set { self[FlowDeskAppearanceTokensKey.self] = newValue }
    }
}
