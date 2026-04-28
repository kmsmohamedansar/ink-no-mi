import SwiftUI

/// Four visual depth planes so chrome, objects, and modals read as stacked layers—not one flat sheet.
///
/// **Layer 1 — Canvas:** workspace plane just above the app atmosphere (ambient rim only).
/// **Layer 2 — Objects:** elements sit on the board with contact + soft ambient shadow.
/// **Layer 3 — Floating UI:** tools, inspector, HUD—stronger lift + frosted blur (`thinMaterial`).
/// **Layer 4 — Modals:** command palette, overlays, blocking sheets—deepest shadow + richer material blur.
enum FlowDeskDepthLayer: Int, Comparable {
    case canvas = 1
    case boardObjects = 2
    case floatingChrome = 3
    case modal = 4

    static func < (lhs: FlowDeskDepthLayer, rhs: FlowDeskDepthLayer) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One shadow pass (color includes opacity).
struct FlowDeskDepthShadow: Sendable {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum FlowDeskDepth {
    /// **Layer 1** — Whole board sits slightly above the dashboard / workspace backdrop.
    static let canvasWorkspace: [FlowDeskDepthShadow] = [
        FlowDeskDepthShadow(color: Color.black.opacity(0.044), radius: 18, x: 0, y: 11),
        FlowDeskDepthShadow(color: Color.black.opacity(0.022), radius: 42, x: 0, y: 24)
    ]

    /// **Layer 2** — Secondary pass for framed elements (after a contact shadow from `elementShadowColor`).
    static let objectAmbient = FlowDeskDepthShadow(
        color: Color.black.opacity(0.038),
        radius: 18,
        x: 0,
        y: 9
    )

    /// **Layer 3** — Tool palette, inspector chrome, selection toolbars, zoom HUD.
    static let floatingChrome: [FlowDeskDepthShadow] = [
        FlowDeskDepthShadow(color: Color.black.opacity(0.125), radius: 26, x: 0, y: 14),
        FlowDeskDepthShadow(color: Color.black.opacity(0.058), radius: 52, x: 0, y: 26)
    ]

    /// **Layer 4** — Command palette, shortcut overlay, paywall-style surfaces.
    static let modalChrome: [FlowDeskDepthShadow] = [
        FlowDeskDepthShadow(color: Color.black.opacity(0.19), radius: 36, x: 0, y: 20),
        FlowDeskDepthShadow(color: Color.black.opacity(0.098), radius: 60, x: 0, y: 32)
    ]

    /// Scaled variants for compact HUD / contextual strips (still layer 3).
    static func floatingChromeScaled(mult1: CGFloat, mult2: CGFloat, y1: CGFloat, y2: CGFloat) -> [FlowDeskDepthShadow] {
        let base = floatingChrome
        guard base.count >= 2 else { return base }
        return [
            FlowDeskDepthShadow(
                color: base[0].color.opacity(Double(mult1)),
                radius: base[0].radius * mult2,
                x: base[0].x,
                y: base[0].y * y1
            ),
            FlowDeskDepthShadow(
                color: base[1].color.opacity(Double(mult1 * 0.92)),
                radius: base[1].radius * mult2,
                x: base[1].x,
                y: base[1].y * y2
            )
        ]
    }
}

extension View {
    /// Stacks one or more shadows (contact → ambient) for a deliberate depth read.
    func flowDeskDepthShadows(_ shadows: [FlowDeskDepthShadow]) -> some View {
        shadows.reduce(AnyView(self)) { view, spec in
            AnyView(
                view.shadow(color: spec.color, radius: spec.radius, x: spec.x, y: spec.y)
            )
        }
    }

    func flowDeskDepthShadow(_ spec: FlowDeskDepthShadow) -> some View {
        self.shadow(color: spec.color, radius: spec.radius, x: spec.x, y: spec.y)
    }
}
