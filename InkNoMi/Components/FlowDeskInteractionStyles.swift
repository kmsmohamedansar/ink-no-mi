import SwiftUI

/// Canvas floating palette tools: hover lift + press tuck (spring).
struct FlowDeskCanvasToolButtonStyle: ButtonStyle {
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        let scale = configuration.isPressed ? 0.98 : (isHovered ? 1.02 : 1.0)
        return configuration.label
            .scaleEffect(scale)
            // Single spring avoids competing animations (hover jitter).
            .animation(FlowDeskMotion.lightSpring, value: scale)
    }
}

/// Subtle press feedback for plain home/dashboard buttons.
struct FlowDeskPlainCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(FlowDeskMotion.quickEaseOut, value: configuration.isPressed)
    }
}

/// Home creation / recent cards: press tuck + dim, stacks with hover scale from `cardContainer`.
struct FlowDeskHomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(FlowDeskMotion.quickEaseOut, value: configuration.isPressed)
    }
}

/// Toolbar and compact controls: light press dim.
struct FlowDeskToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(FlowDeskMotion.quickEaseOut, value: configuration.isPressed)
    }
}

