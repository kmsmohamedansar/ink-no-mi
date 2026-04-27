import SwiftUI

extension View {
    /// Applies toolbar material or flat fill from the active appearance preset.
    @ViewBuilder
    func flowDeskToolbarChrome(_ tokens: FlowDeskAppearanceTokens) -> some View {
        if let flat = tokens.toolbarFlatBackground {
            toolbarBackground(flat, for: .windowToolbar)
        } else if let material = tokens.toolbarMaterial.material {
            toolbarBackground(material, for: .windowToolbar)
        } else {
            self
        }
    }

    @ViewBuilder
    func flowDeskSidebarFooterBackground(_ tokens: FlowDeskAppearanceTokens) -> some View {
        if tokens.sidebarFooterUseSystemBar {
            background(.bar)
        } else if let material = tokens.sidebarFooterMaterial.material {
            background(material)
        } else {
            background(.bar)
        }
    }
}

extension FlowDeskAppearanceTokens {
    /// Fills a rounded rect for home-style cards (subtle surface gradient + optional material per preset).
    @ViewBuilder
    func homeCardFillBackground(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if let material = homeCardMaterial.material {
            ZStack {
                shape.fill(homeCardFill)
                shape.fill(.clear).background(material, in: shape)
            }
        } else {
            shape.fill(homeCardFill)
        }
    }
}

// MARK: - Unified home / dashboard card container (ZStack: background → clipped content → overlays)

/// Rounded card shell: background + shadows on a dedicated layer, padded content clipped to the same radius, hairline + border overlays on top.
private struct FlowDeskCardContainerModifier: ViewModifier {
    @Environment(\.flowDeskTokens) private var tokens

    var cornerRadius: CGFloat
    @Binding var isHovered: Bool
    var scaleOnHover: CGFloat
    var contentInsets: EdgeInsets
    var contentAlignment: Alignment
    /// When true, content uses `maxHeight: .infinity` so vertical alignment (e.g. `.center`) can apply in tight rows.
    var contentFillsHeight: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack(alignment: .topLeading) {
            tokens.homeCardFillBackground(cornerRadius: cornerRadius)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .clipShape(shape)
                .shadow(
                    color: Color.black.opacity(
                        isHovered ? tokens.homeCardShadowOpacityHover : tokens.homeCardShadowOpacityNormal
                    ),
                    radius: isHovered ? tokens.homeCardShadowRadiusHover : tokens.homeCardShadowRadiusNormal,
                    x: 0,
                    y: isHovered ? FlowDeskLayout.cardShadowYHover : FlowDeskLayout.cardShadowYNormal
                )

            Group {
                if contentFillsHeight {
                    content
                        .padding(contentInsets)
                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: contentAlignment)
                } else {
                    content
                        .padding(contentInsets)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: contentAlignment)
                }
            }
            .clipped()
            .clipShape(shape)
            .contentShape(shape)
        }
        .overlay {
            shape
                .strokeBorder(
                    Color.black.opacity(0.05),
                    lineWidth: FlowDeskLayout.cardBorderLineWidth
                )
                .allowsHitTesting(false)
                .overlay {
                    if isHovered {
                        shape
                            .fill(Color.white.opacity(0.06))
                            .blendMode(.overlay)
                    }
                }
        }
        .offset(y: isHovered ? -1 : 0)
        .scaleEffect(isHovered ? scaleOnHover : 1)
        .animation(FlowDeskMotion.premiumLiftEaseOut, value: isHovered)
    }
}

extension View {
    /// Home / dashboard cards: background (solid fill + one shadow) → clipped content → stroke only. Corner radius defaults to `FlowDeskLayout.cardCornerRadius`.
    func cardContainer(
        cornerRadius: CGFloat = FlowDeskLayout.cardCornerRadius,
        isHovered: Binding<Bool>,
        scaleOnHover: CGFloat = 1.0,
        contentInsets: EdgeInsets = FlowDeskLayout.homeCardContentInsets,
        contentAlignment: Alignment = .topLeading,
        contentFillsHeight: Bool = false
    ) -> some View {
        modifier(FlowDeskCardContainerModifier(
            cornerRadius: cornerRadius,
            isHovered: isHovered,
            scaleOnHover: scaleOnHover,
            contentInsets: contentInsets,
            contentAlignment: contentAlignment,
            contentFillsHeight: contentFillsHeight
        ))
    }
}

/// Reusable template / metadata capsule (home cards).
struct FlowDeskTemplateChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, FlowDeskLayout.spaceS)
            .padding(.vertical, FlowDeskLayout.spaceXS)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(FlowDeskLayout.chipBackgroundOpacity))
            )
            .frame(maxWidth: 200, alignment: .leading)
            .clipped()
    }
}

// MARK: - Floating canvas chrome (palette, toolbars, HUD, tips)

/// Shadow tier for one family of lifted surfaces (see `flowDeskFloatingPanelChrome`).
enum FlowDeskFloatingChromeShadowStyle {
    case toolPalette
    case contextualToolbar
    case compactHUD

    fileprivate var shadowFactors: (opacity: CGFloat, radius: CGFloat, y: CGFloat) {
        switch self {
        case .toolPalette:
            return (1, 1, 1)
        case .contextualToolbar:
            return (0.9, 0.7, 0.68)
        case .compactHUD:
            return (0.82, 0.66, 0.62)
        }
    }

    fileprivate var depthLevel: FlowDeskTheme.DepthLevel {
        switch self {
        case .compactHUD:
            return .elevated
        case .contextualToolbar, .toolPalette:
            return .floating
        }
    }
}

private struct FlowDeskFloatingPanelChromeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat
    var shadowStyle: FlowDeskFloatingChromeShadowStyle
    var lightOpacity: Double
    var darkOpacity: Double

    func body(content: Content) -> some View {
        let f = shadowStyle.shadowFactors
        let depthShadow = DS.Shadow.medium
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(darkOpacity * 0.45)
                                    : Color.white.opacity(lightOpacity * 0.55)
                            )
                    }
                .shadow(
                    color: Color.black.opacity(0.12 * Double(f.opacity)),
                    radius: depthShadow.radius * f.radius,
                    x: 0,
                    y: depthShadow.y * f.y
                )
            }
            .overlay {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                shape
                    .strokeBorder(
                        Color.black.opacity(0.05),
                        lineWidth: FlowDeskLayout.chromeHairlineBorderWidth
                    )
            }
    }
}

extension View {
    func flowDeskFloatingPanelChrome(
        cornerRadius: CGFloat = 16,
        shadowStyle: FlowDeskFloatingChromeShadowStyle,
        lightTintOpacity: Double = 0.11,
        darkTintOpacity: Double = 0.08
    ) -> some View {
        modifier(FlowDeskFloatingPanelChromeModifier(
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle,
            lightOpacity: lightTintOpacity,
            darkOpacity: darkTintOpacity
        ))
    }
}
