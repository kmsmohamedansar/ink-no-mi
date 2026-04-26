import SwiftUI

/// Central animation timings and curves used across canvas microinteractions.
enum FlowDeskMotion {
    static let quickEaseOut = Animation.easeOut(duration: 0.12)
    static let standardEaseOut = Animation.easeOut(duration: 0.15)
    static let smoothEaseOut = Animation.easeOut(duration: 0.18)
    static let lightSpring = Animation.spring(response: 0.22, dampingFraction: 0.88)

    static let insertTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.96)),
        removal: .opacity.combined(with: .scale(scale: 0.95))
    )

    static let deleteTransition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95))
    static let handleTransition: AnyTransition = .scale(scale: 0.7).combined(with: .opacity)
}
