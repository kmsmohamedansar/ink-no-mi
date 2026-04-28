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

/// Shadow + material tier for lifted surfaces (see `flowDeskDepthHierarchy` layers 3–4).
enum FlowDeskFloatingChromeShadowStyle {
    /// Layer 3 — primary floating chrome (tools, inspector-scale panels).
    case toolPalette
    /// Layer 3 — lighter HUD / contextual strips.
    case contextualToolbar
    case compactHUD
    /// Layer 4 — modals, command surfaces, blocking overlays.
    case modalPanel

    fileprivate var shadowLayers: [FlowDeskDepthShadow] {
        switch self {
        case .toolPalette:
            return FlowDeskDepth.floatingChrome
        case .contextualToolbar:
            return FlowDeskDepth.floatingChromeScaled(mult1: 0.9, mult2: 0.78, y1: 0.9, y2: 0.9)
        case .compactHUD:
            return FlowDeskDepth.floatingChromeScaled(mult1: 0.82, mult2: 0.66, y1: 0.86, y2: 0.86)
        case .modalPanel:
            return FlowDeskDepth.modalChrome
        }
    }

    fileprivate var panelMaterial: Material {
        switch self {
        case .modalPanel:
            return .regularMaterial
        default:
            return .thinMaterial
        }
    }
}

private struct FlowDeskFloatingPanelChromeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var cornerRadius: CGFloat
    var shadowStyle: FlowDeskFloatingChromeShadowStyle
    var lightOpacity: Double
    var darkOpacity: Double

    private var baseTint: Color {
        colorScheme == .dark
            ? Color.white.opacity(darkOpacity * 0.45)
            : Color.white.opacity(lightOpacity * 0.55)
    }

    private var frostedOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.14
    }

    private var sheenGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.2), location: 0),
                .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.07), location: 0.28),
                .init(color: Color.clear, location: 0.58),
                .init(color: Color.black.opacity(colorScheme == .dark ? 0.08 : 0.04), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var rimLightColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.14 : 0.26)
    }

    private var panelHoverGlowColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12)
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(shadowStyle.panelMaterial)
                    .overlay {
                        shape.fill(.ultraThinMaterial).opacity(frostedOpacity)
                    }
                    .overlay {
                        shape.fill(baseTint)
                    }
                    .overlay {
                        shape.fill(sheenGradient).blendMode(.softLight)
                    }
            }
            .flowDeskDepthShadows(shadowStyle.shadowLayers)
            .shadow(
                color: panelHoverGlowColor.opacity(isHovered ? 1 : 0),
                radius: isHovered ? 16 : 0,
                x: 0,
                y: 0
            )
            .overlay {
                shape
                    .strokeBorder(
                        Color.black.opacity(0.05),
                        lineWidth: FlowDeskLayout.chromeHairlineBorderWidth
                    )
                    .overlay {
                        shape
                            .strokeBorder(rimLightColor, lineWidth: 0.6)
                            .blendMode(.overlay)
                    }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .animation(FlowDeskMotion.hoverEase, value: isHovered)
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
