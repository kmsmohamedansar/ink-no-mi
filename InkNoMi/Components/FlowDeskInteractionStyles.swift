import SwiftUI

/// Canvas floating palette tools: hover lift + press tuck.
struct FlowDeskCanvasToolButtonStyle: ButtonStyle {
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let scale = isPressed ? DS.Interaction.pressScale : (isHovered ? DS.Interaction.hoverScale : 1.0)
        let yOffset: CGFloat = isPressed ? 0.6 : (isHovered ? -1 : 0)
        let shadowOpacity = isPressed ? 0.06 : (isHovered ? 0.12 : 0.06)
        let shadowRadius: CGFloat = isPressed ? 8 : (isHovered ? 20 : 12)
        return configuration.label
            .scaleEffect(scale)
            .offset(y: yOffset)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: isHovered ? 10 : 4)
            .animation(isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound, value: isPressed)
            .animation(FlowDeskMotion.premiumLiftEaseOut, value: isHovered)
    }
}

/// Subtle press feedback for plain home/dashboard buttons.
struct FlowDeskPlainCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : 1)
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
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : 1)
            .offset(y: configuration.isPressed ? 1.2 : 0)
            .brightness(configuration.isPressed ? -0.012 : 0)
            .opacity(configuration.isPressed ? 0.975 : 1)
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
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : 1)
            .opacity(configuration.isPressed ? 0.91 : 1)
            .animation(
                configuration.isPressed ? FlowDeskMotion.pressCompress : FlowDeskMotion.pressRebound,
                value: configuration.isPressed
            )
    }
}

