import SwiftUI

/// Canvas floating palette tools: hover lift + press tuck (spring).
struct FlowDeskCanvasToolButtonStyle: ButtonStyle {
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let scale = isPressed ? 0.976 : (isHovered ? 1.012 : 1.0)
        let yOffset: CGFloat = isPressed ? 0.8 : (isHovered ? -1.4 : 0)
        let shadowOpacity = isPressed ? 0.08 : (isHovered ? 0.18 : 0.1)
        let shadowRadius: CGFloat = isPressed ? 4 : (isHovered ? 10 : 6)
        return configuration.label
            .scaleEffect(scale)
            .offset(y: yOffset)
            .brightness(isHovered ? 0.012 : 0)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: isHovered ? 4 : 2)
            .animation(isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound, value: isPressed)
            .animation(FlowDeskMotion.premiumLiftEaseOut.delay(0.02), value: isHovered)
    }
}

/// Subtle press feedback for plain home/dashboard buttons.
struct FlowDeskPlainCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.976 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(
                configuration.isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound,
                value: configuration.isPressed
            )
    }
}

/// Home creation / recent cards: press tuck + dim, stacks with hover scale from `cardContainer`.
struct FlowDeskHomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.974 : 1)
            .opacity(configuration.isPressed ? 0.965 : 1)
            .animation(
                configuration.isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound,
                value: configuration.isPressed
            )
    }
}

/// Toolbar and compact controls: light press dim.
struct FlowDeskToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.978 : 1)
            .opacity(configuration.isPressed ? 0.91 : 1)
            .animation(
                configuration.isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound,
                value: configuration.isPressed
            )
    }
}

