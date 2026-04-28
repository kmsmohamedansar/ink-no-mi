import SwiftUI

/// Central animation timings and curves used across canvas microinteractions.
@MainActor
enum FlowDeskMotion {
    /// Unified motion language durations.
    static let fastDuration: Double = 0.12
    static let mediumDuration: Double = 0.18
    static let slowDuration: Double = 0.24

    static let fastEaseOut = Animation.easeOut(duration: fastDuration)
    static let mediumEaseOut = Animation.easeOut(duration: mediumDuration)
    static let slowEaseOut = Animation.easeOut(duration: slowDuration)
    static let fastEaseInOut = Animation.easeInOut(duration: fastDuration)
    static let mediumEaseInOut = Animation.easeInOut(duration: mediumDuration)
    static let slowEaseInOut = Animation.easeInOut(duration: slowDuration)

    /// Existing semantic aliases now mapped to fast/medium/slow tokens.
    static let hoverEase = fastEaseOut
    static let uiPressDown = fastEaseOut
    static let uiPressRelease = fastEaseOut
    static let uiHoverLift = hoverEase
    static let uiRouteTransition = mediumEaseOut
    static let uiOverlayPresent = mediumEaseOut

    static let quickEaseOut = fastEaseOut
    static let microQuickEaseOut = fastEaseOut
    static let standardEaseOut = mediumEaseOut
    static let smoothEaseOut = mediumEaseOut
    static let lightSpring = fastEaseOut
    static let mellowSpring = mediumEaseOut
    static let premiumLiftEaseOut = hoverEase
    static let pressCompress = fastEaseOut
    static let pressRebound = mediumEaseOut
    static let hoverGlow = hoverEase
    static let modalEnter = mediumEaseOut
    /// Primary shell navigation (home ↔ editor): snappy; element canvas drops use separate timings.
    static let canvasEnter = mediumEaseOut
    static let selectionGlowIn = mediumEaseOut
    static let selectionPulseOut = slowEaseOut

    static let handleInsertSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let snapCueFlash = fastEaseOut
    static let drawingLiftFade = fastEaseOut

    static let insertTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.96)),
        removal: .opacity.combined(with: .scale(scale: 0.95))
    )

    static let deleteTransition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95))
    static let handleTransition: AnyTransition = .asymmetric(
        insertion: .scale(scale: 0.48, anchor: .bottomTrailing)
            .combined(with: .opacity)
            .combined(with: .offset(x: 4, y: 4)),
        removal: .scale(scale: 0.88, anchor: .bottomTrailing).combined(with: .opacity)
    )
    static let modalEntryTransition: AnyTransition = .opacity
        .combined(with: .scale(scale: 0.965))
}

private struct FlowDeskModalEntranceModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.965)
            .animation(FlowDeskMotion.modalEnter, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    /// Subtle fade + scale-up entrance for modal content.
    func flowDeskModalEntrance() -> some View {
        modifier(FlowDeskModalEntranceModifier())
    }
}
