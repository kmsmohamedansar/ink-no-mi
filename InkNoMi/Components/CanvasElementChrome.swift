import SwiftUI

/// Placeholder chrome for a canvas element until per-kind editors exist.
struct CanvasElementChrome: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    let element: CanvasElementRecord
    var isSelected: Bool

    var body: some View {
        let corner = FlowDeskLayout.chromeCompactCornerRadius
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(tokens.homeCardFill.opacity(colorScheme == .dark ? 0.14 : 0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(
                            isSelected ? tokens.selectionStrokeColor.opacity(0.92) : Color.primary.opacity(0.08),
                            lineWidth: isSelected ? FlowDeskLayout.chromeHairlineBorderWidth + 0.35 : FlowDeskLayout.chromeHairlineBorderWidth
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.05),
                    radius: 4,
                    x: 0,
                    y: 1.5
                )

            VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                Label(element.kind.displayName, systemImage: element.kind.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("z \(element.zIndex)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(FlowDeskLayout.canvasContextTemplateRowPadding)
        }
    }
}

extension View {
    /// Shared object-depth language for canvas elements: base shadow, hover lift, active soft glow.
    func canvasObjectDepthSurface(
        isHovered: Bool,
        isSelected: Bool,
        isActive: Bool = false,
        isDragging: Bool,
        tokens: FlowDeskAppearanceTokens
    ) -> some View {
        let focused = isSelected || isActive
        let baseOpacity = isDragging
            ? 0.14
            : (focused ? tokens.canvasItemShadowSelected : tokens.canvasItemShadowNormal)
        let baseRadius = isDragging
            ? 14
            : (focused ? tokens.canvasItemShadowRadiusSelected : tokens.canvasItemShadowRadiusNormal)
        let baseY = isDragging
            ? 8
            : (focused ? tokens.canvasItemShadowYSelected : tokens.canvasItemShadowYNormal)
        let hoverOpacity = (!focused && isHovered && !isDragging) ? 0.07 : 0
        let hoverRadius: CGFloat = (!focused && isHovered && !isDragging) ? 11 : 0
        let hoverY: CGFloat = (!focused && isHovered && !isDragging) ? 4 : 0
        let hoverGlowOpacity = (!focused && isHovered && !isDragging) ? 0.16 : 0
        let hoverGlowRadius: CGFloat = (!focused && isHovered && !isDragging) ? 14 : 0
        let activeGlowOpacity = focused ? 0.2 : 0
        let activeGlowRadius: CGFloat = focused ? 18 : 0

        return self
            .shadow(color: Color.black.opacity(baseOpacity), radius: baseRadius, x: 0, y: baseY)
            .shadow(color: Color.black.opacity(hoverOpacity), radius: hoverRadius, x: 0, y: hoverY)
            .shadow(color: tokens.selectionStrokeColor.opacity(hoverGlowOpacity), radius: hoverGlowRadius, x: 0, y: 0)
            .shadow(color: tokens.selectionStrokeColor.opacity(activeGlowOpacity), radius: activeGlowRadius, x: 0, y: 0)
    }
}

extension CGSize {
    /// Tiny drag smoothing to reduce mechanical jitter while preserving responsiveness.
    func smoothedToward(_ target: CGSize, response: CGFloat = 0.2) -> CGSize {
        CGSize(
            width: width + (target.width - width) * response,
            height: height + (target.height - height) * response
        )
    }
}

private extension CanvasElementKind {
    var displayName: String {
        switch self {
        case .textBlock: return "Text block"
        case .stickyNote: return "Sticky note"
        case .stroke: return "Drawing"
        case .shape: return "Shape"
        case .chart: return "Chart"
        case .connector: return "Connector"
        @unknown default: return "Element"
        }
    }

    var systemImage: String {
        switch self {
        case .textBlock: return "text.alignleft"
        case .stickyNote: return "note.text"
        case .stroke: return "scribble.variable"
        case .shape: return "square.on.circle"
        case .chart: return "chart.bar"
        case .connector: return "arrow.triangle.branch"
        @unknown default: return "square.dashed"
        }
    }
}
