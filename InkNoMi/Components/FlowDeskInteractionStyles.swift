import SwiftUI

// MARK: - Shared press + hover (ease-out 120–180 ms)

private struct FlowDeskPressHoverChrome<Content: View>: View {
    enum Kind {
        case toolbar
        case plainCard
    }

    let kind: Kind
    let isPressed: Bool
    let content: Content

    @State private var hovered = false

    init(kind: Kind, isPressed: Bool, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.isPressed = isPressed
        self.content = content()
    }

    var body: some View {
        content
            .onHover { hovered = $0 }
            .scaleEffect(isPressed ? DS.Interaction.pressScale : 1)
            .offset(y: liftOffset)
            .opacity(kind == .toolbar ? (isPressed ? 0.91 : 1) : (isPressed ? 0.96 : 1))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .animation(FlowDeskMotion.hoverEase, value: hovered)
            .animation(isPressed ? FlowDeskMotion.uiPressDown : FlowDeskMotion.uiPressRelease, value: isPressed)
    }

    private var liftOffset: CGFloat {
        if isPressed {
            return kind == .toolbar ? 0.35 : 0.28
        }
        return hovered ? DS.Interaction.hoverLiftPoints : 0
    }

    private var shadowColor: Color {
        guard hovered, !isPressed else { return .clear }
        return Color.black.opacity(kind == .toolbar ? 0.055 : 0.045)
    }

    private var shadowRadius: CGFloat {
        hovered && !isPressed ? 10 : 0
    }

    private var shadowY: CGFloat {
        hovered && !isPressed ? 4 : 0
    }
}

/// Canvas floating palette tools: hover lift + press tuck (caller tracks hover for active affordances).
struct FlowDeskCanvasToolButtonStyle: ButtonStyle {
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let scale = isPressed ? DS.Interaction.pressScale : (isHovered ? DS.Interaction.hoverScale : 1.0)
        let yOffset: CGFloat = isPressed ? 0.6 : (isHovered ? DS.Interaction.hoverLiftPoints : 0)
        let shadowOpacity = isPressed ? 0.06 : (isHovered ? 0.12 : 0.06)
        let shadowRadius: CGFloat = isPressed ? 8 : (isHovered ? 20 : 12)
        return configuration.label
            .scaleEffect(scale)
            .offset(y: yOffset)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: isHovered ? 10 : 4)
            .animation(isPressed ? FlowDeskMotion.uiPressDown : FlowDeskMotion.uiPressRelease, value: isPressed)
            .animation(FlowDeskMotion.hoverEase, value: isHovered)
    }
}

/// Default for `.plain` replacements: press tuck + subtle hover lift + shadow (rows, menus, chrome).
struct FlowDeskPlainInteractionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FlowDeskPressHoverChrome(kind: .toolbar, isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

/// Subtle press feedback for plain home/dashboard buttons (legacy name).
struct FlowDeskPlainCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FlowDeskPressHoverChrome(kind: .plainCard, isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

/// Home creation / recent cards: press tuck + dim (hover lift stays at card chrome level where needed).
struct FlowDeskHomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : 1)
            .offset(y: configuration.isPressed ? 1.2 : 0)
            .brightness(configuration.isPressed ? -0.012 : 0)
            .opacity(configuration.isPressed ? 0.975 : 1)
            .animation(
                configuration.isPressed ? FlowDeskMotion.uiPressDown : FlowDeskMotion.uiPressRelease,
                value: configuration.isPressed
            )
    }
}

/// Toolbar and compact controls.
struct FlowDeskToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FlowDeskPressHoverChrome(kind: .toolbar, isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

/// Subtle loading shimmer used by skeleton placeholders.
private struct FlowDeskSkeletonShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.16),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: geo.size.width * 0.55)
                        .rotationEffect(.degrees(18))
                        .offset(x: geo.size.width * phase)
                    }
                    .allowsHitTesting(false)
                    .blendMode(.softLight)
                    .mask(content)
                }
            }
            .onAppear {
                guard active else { return }
                phase = -1
                withAnimation(FlowDeskMotion.slowEaseInOut.repeatForever(autoreverses: false)) {
                    phase = 1.35
                }
            }
            .onChange(of: active) { _, newValue in
                if newValue {
                    phase = -1
                    withAnimation(FlowDeskMotion.slowEaseInOut.repeatForever(autoreverses: false)) {
                        phase = 1.35
                    }
                } else {
                    phase = -1
                }
            }
    }
}

extension View {
    func flowDeskSkeletonShimmer(active: Bool = true) -> some View {
        modifier(FlowDeskSkeletonShimmerModifier(active: active))
    }
}
