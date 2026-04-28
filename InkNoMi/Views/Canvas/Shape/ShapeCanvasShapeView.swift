import CoreGraphics
import SwiftUI

/// Vector drawing for a shape inside its element bounds (stroke-aligned inset).
/// Renders fills as subtle gradients with soft inner shading; borders stay in the 1.5–2pt “designed UI” band.
struct ShapeCanvasShapeView: View {
    let payload: ShapePayload

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let lwRaw = max(1, CGFloat(payload.lineWidth))
            /// Border weight used for layout inset (premium stroke is clamped for filled shapes).
            let layoutLw = payload.supportsFill ? PremiumShapeAppearance.borderWidth(for: lwRaw) : lwRaw
            let inset = layoutLw * 0.5
            let rect = CGRect(
                x: inset,
                y: inset,
                width: max(0, w - layoutLw),
                height: max(0, h - layoutLw)
            )

            ZStack {
                switch payload.kind {
                case .rectangle:
                    rectangleBody(rect: rect, lw: lwRaw)
                case .roundedRectangle:
                    roundedRectBody(rect: rect, lw: lwRaw)
                case .ellipse:
                    ellipseBody(rect: rect, lw: lwRaw)
                case .line:
                    lineBody(rect: rect, lw: lwRaw, arrow: false)
                case .arrow:
                    lineBody(rect: rect, lw: lwRaw, arrow: true)
                }
            }
            .frame(width: w, height: h)
        }
    }

    @ViewBuilder
    private func rectangleBody(rect: CGRect, lw: CGFloat) -> some View {
        let r = min(CGFloat(payload.cornerRadius), min(rect.width, rect.height) * 0.5)
        filledShapeBundle(
            rect: rect,
            cornerRadius: r,
            lw: lw,
            lineJoin: .miter
        ) {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .path(in: rect)
        }
    }

    @ViewBuilder
    private func roundedRectBody(rect: CGRect, lw: CGFloat) -> some View {
        let r = min(CGFloat(payload.cornerRadius), min(rect.width, rect.height) * 0.5)
        filledShapeBundle(
            rect: rect,
            cornerRadius: r,
            lw: lw,
            lineJoin: .round
        ) {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .path(in: rect)
        }
    }

    @ViewBuilder
    private func ellipseBody(rect: CGRect, lw: CGFloat) -> some View {
        filledShapeBundle(rect: rect, cornerRadius: nil as CGFloat?, lw: lw, lineJoin: .round) {
            Ellipse()
                .path(in: rect)
        }
    }

    /// Shared stack: gradient fill, inner shading, cohesive border (filled primitives only).
    private func filledShapeBundle<F: Shape>(
        rect: CGRect,
        cornerRadius: CGFloat?,
        lw: CGFloat,
        lineJoin: CGLineJoin,
        @ViewBuilder shapePath: () -> F
    ) -> some View {
        let gradient = PremiumShapeAppearance.fillGradient(fill: payload.fillColor)
        let borderColor = PremiumShapeAppearance.borderColor(fill: payload.fillColor, stroke: payload.strokeColor)
        let borderW = PremiumShapeAppearance.borderWidth(for: lw)

        return ZStack {
            shapePath()
                .fill(payload.supportsFill ? gradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                .overlay {
                    if payload.supportsFill {
                        PremiumShapeAppearance.innerShadowShape(rect: rect, cornerRadius: cornerRadius)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }

            shapePath()
                .stroke(borderColor, style: StrokeStyle(lineWidth: borderW, lineJoin: lineJoin))
        }
    }

    @ViewBuilder
    private func lineBody(rect: CGRect, lw: CGFloat, arrow: Bool) -> some View {
        let strokeColor = PremiumShapeAppearance.lineStrokeColor(payload.strokeColor)
        let strokeW = max(1.5, min(3.0, lw))
        let start = CGPoint(x: rect.minX, y: rect.midY)
        let endX = arrow ? rect.maxX - min(18, rect.width * 0.12) : rect.maxX
        let end = CGPoint(x: endX, y: rect.midY)

        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            strokeColor,
            style: StrokeStyle(lineWidth: strokeW, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: Color.black.opacity(0.12), radius: strokeW * 1.2, x: 0, y: strokeW * 0.35)
        .shadow(color: strokeColor.opacity(0.28), radius: strokeW * 0.9, x: 0, y: 0)

        if arrow {
            let headLen = min(14, max(8, rect.height * 0.35))
            let headHalf = headLen * 0.55
            let tip = CGPoint(x: rect.maxX, y: rect.midY)
            let base = CGPoint(x: end.x, y: end.y)
            Path { path in
                path.move(to: tip)
                path.addLine(to: CGPoint(x: base.x - headLen, y: base.y - headHalf))
                path.addLine(to: CGPoint(x: base.x - headLen, y: base.y + headHalf))
                path.closeSubpath()
            }
            .fill(strokeColor)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Premium appearance (fills, inner depth, border harmony)

private enum PremiumShapeAppearance {
    /// Keeps borders in the “card UI” range while still honoring thinner/thicker editor values weakly.
    static func borderWidth(for request: CGFloat) -> CGFloat {
        max(1.5, min(2.0, request))
    }

    static func fillGradient(fill: CanvasRGBAColor) -> LinearGradient {
        let hi = lifted(fill, delta: 0.055)
        let lo = lifted(fill, delta: -0.085)
        let mid = fill
        return LinearGradient(
            stops: [
                .init(color: hi.swiftUIColor.opacity(fill.opacity), location: 0),
                .init(color: mid.swiftUIColor.opacity(fill.opacity), location: 0.52),
                .init(color: lo.swiftUIColor.opacity(fill.opacity), location: 1)
            ],
            startPoint: UnitPoint(x: 0.15, y: 0.12),
            endPoint: UnitPoint(x: 0.92, y: 0.95)
        )
    }

    /// Border reads slightly darker than the fill center, blended with user stroke so color picks still matter.
    static func borderColor(fill: CanvasRGBAColor, stroke: CanvasRGBAColor) -> Color {
        let rim = lifted(fill, delta: -0.22)
        let t = 0.42
        let opacity = rim.opacity * (1 - t) + stroke.opacity * t
        return CanvasRGBAColor(
            red: rim.red * (1 - t) + stroke.red * t,
            green: rim.green * (1 - t) + stroke.green * t,
            blue: rim.blue * (1 - t) + stroke.blue * t,
            opacity: min(1, opacity + 0.08)
        ).swiftUIColor
    }

    static func lineStrokeColor(_ stroke: CanvasRGBAColor) -> Color {
        stroke.swiftUIColor
    }

    /// Soft inner shading (multiply + subtle highlight) so fills feel dimensional, not flat ink.
    @ViewBuilder
    static func innerShadowShape(rect: CGRect, cornerRadius: CGFloat?) -> some View {
        if let r = cornerRadius {
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.13),
                                Color.black.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: UnitPoint(x: 0.72, y: 0.78)
                        )
                    )
                    .blur(radius: 6)
                    .mask(RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color.white))

                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    .blur(radius: 2)
                    .mask(RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color.white))
            }
            .blendMode(.multiply)
            .opacity(0.88)
            .allowsHitTesting(false)
        } else {
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.black.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 7)
                    .mask(Ellipse().fill(Color.white))

                Ellipse()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    .blur(radius: 2)
                    .mask(Ellipse().fill(Color.white))
            }
            .blendMode(.multiply)
            .opacity(0.85)
            .allowsHitTesting(false)
        }
    }

    private static func lifted(_ c: CanvasRGBAColor, delta: Double) -> CanvasRGBAColor {
        CanvasRGBAColor(
            red: clamp01(c.red + delta),
            green: clamp01(c.green + delta * 0.97),
            blue: clamp01(c.blue + delta * 0.95),
            opacity: c.opacity
        )
    }

    private static func clamp01(_ x: Double) -> Double {
        min(1, max(0, x))
    }
}
