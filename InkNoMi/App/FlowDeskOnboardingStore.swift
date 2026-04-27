import Foundation
import Observation

/// App-wide first-use hints only. Not part of document or canvas persistence.
@Observable
final class FlowDeskOnboardingStore {
    private enum Key {
        static let firstRunCompleted = "inkNoMi.onboarding.firstRunCompleted"
        static let home = "flowDesk.onboarding.homeTipsDismissed"
        static let canvas = "flowDesk.onboarding.canvasTipsDismissed"
    }

    private let defaults: UserDefaults

    private(set) var firstRunCompleted: Bool
    private(set) var homeTipsDismissed: Bool
    private(set) var canvasTipsDismissed: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        firstRunCompleted = defaults.bool(forKey: Key.firstRunCompleted)
        homeTipsDismissed = defaults.bool(forKey: Key.home)
        canvasTipsDismissed = defaults.bool(forKey: Key.canvas)
    }

    var shouldShowFirstRunOnboarding: Bool {
        !firstRunCompleted
    }

    func completeFirstRunOnboarding() {
        guard !firstRunCompleted else { return }
        defaults.set(true, forKey: Key.firstRunCompleted)
        firstRunCompleted = true
    }

    func dismissHomeTips() {
        guard !homeTipsDismissed else { return }
        defaults.set(true, forKey: Key.home)
        homeTipsDismissed = true
    }

    func dismissCanvasTips() {
        guard !canvasTipsDismissed else { return }
        defaults.set(true, forKey: Key.canvas)
        canvasTipsDismissed = true
    }
}
