import SwiftUI

/// Central animation timings and curves used across canvas microinteractions.
@MainActor
enum FlowDeskMotion {
    static let quickEaseOut = Animation.easeOut(duration: 0.12)
    static let microQuickEaseOut = Animation.easeOut(duration: 0.09)
    static let standardEaseOut = Animation.easeOut(duration: 0.2)
    static let smoothEaseOut = Animation.easeOut(duration: 0.15)
    static let lightSpring = Animation.easeOut(duration: 0.14)
    static let mellowSpring = Animation.easeOut(duration: 0.15)
    static let premiumLiftEaseOut = Animation.easeOut(duration: 0.12)
    static let pressCompress = Animation.easeOut(duration: 0.08)
    static let pressRebound = Animation.easeOut(duration: 0.12)
    static let hoverGlow = Animation.easeOut(duration: 0.14)
    static let modalEnter = Animation.easeOut(duration: 0.15).delay(0.02)
    static let canvasEnter = Animation.easeOut(duration: 0.26).delay(0.05)
    static let selectionGlowIn = Animation.easeOut(duration: 0.2).delay(0.03)
    static let selectionPulseOut = Animation.easeOut(duration: 0.22)
    static let snapCueFlash = Animation.easeOut(duration: 0.1)
    static let drawingLiftFade = Animation.easeOut(duration: 0.12)

    static let insertTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.96)),
        removal: .opacity.combined(with: .scale(scale: 0.95))
    )

    static let deleteTransition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95))
    static let handleTransition: AnyTransition = .scale(scale: 0.84).combined(with: .opacity)
    static let modalEntryTransition: AnyTransition = .opacity
        .combined(with: .scale(scale: 0.965))
        .combined(with: .offset(y: 12))
}

private struct FlowDeskModalEntranceModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.97)
            .offset(y: isVisible ? 0 : 10)
            .animation(FlowDeskMotion.modalEnter, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    /// Subtle fade + scale + upward settle for sheet/modal content.
    func flowDeskModalEntrance() -> some View {
        modifier(FlowDeskModalEntranceModifier())
    }
}
