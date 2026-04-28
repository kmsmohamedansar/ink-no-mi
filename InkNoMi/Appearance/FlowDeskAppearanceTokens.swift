import SwiftUI

enum FlowDeskMaterialLayer: Equatable {
    case none
    case ultraThin
    case thin
    case regular

    var material: Material? {
        switch self {
        case .none: return nil
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        }
    }
}

struct CuratedPresetDefinition: Equatable {
    let name: String
    let appBackground: Color
    let canvasBackground: Color
    let panelBackground: Color
    let cardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let border: Color
    let accent: Color
    let accentSoft: Color
    let gridColor: Color
    let shadowColor: Color
    let recommendedFont: AppFontStyle
    let recommendedCornerStyle: CornerStyle
    let recommendedDensity: InterfaceDensity
}

struct DynamicTheme: Equatable {
    let preset: CuratedPresetDefinition
    let workspaceBackground: Color
    let canvasWorkspaceBackground: Color
    let gridLineOpacity: Double
    let canvasGridInk: Color
    let canvasBottomDepthOpacity: Double
    let canvasTopWashOpacity: Double
    let canvasVignetteOpacity: Double
    let canvasGrainOpacity: Double
    let canvasGridEmphasis: Double
    let homeCardFill: Color
    let homeCardFillTop: Color
    let homeCardMaterial: FlowDeskMaterialLayer
    let homeCardBorderNormal: Double
    let homeCardBorderHover: Double
    let homeCardShadowOpacityNormal: Double
    let homeCardShadowOpacityHover: Double
    let homeCardShadowRadiusNormal: CGFloat
    let homeCardShadowRadiusHover: CGFloat
    let canvasTextBlockFill: Color
    let canvasTextBlockBorderOpacity: Double
    let canvasItemShadowNormal: Double
    let canvasItemShadowSelected: Double
    let canvasItemShadowRadiusNormal: CGFloat
    let canvasItemShadowRadiusSelected: CGFloat
    let canvasItemShadowYNormal: CGFloat
    let canvasItemShadowYSelected: CGFloat
    let chartCardFill: Color
    let chartCardBorderOpacity: Double
    let selectionStrokeColor: Color
    let selectionStrokeWidth: CGFloat
    let sidebarListTint: Color
    let sidebarFooterUseSystemBar: Bool
    let sidebarFooterMaterial: FlowDeskMaterialLayer
    let toolbarMaterial: FlowDeskMaterialLayer
    let toolbarFlatBackground: Color?
    let inspectorChromeBackground: Color
    let accent: Color
    let accentSoft: Color
    let accentGradientStart: Color
    let accentGradientEnd: Color
    let density: DensityTokens
    let corners: CornerTokens
    let motion: MotionTokens
    let font: ThemeFont

    static let fallback = resolve(colorScheme: .light, settings: .default)

    static func definition(for preset: VisualTheme) -> CuratedPresetDefinition {
        switch preset {
        case .miroBright:
            return .init(name: "Miro Bright", appBackground: Color(hex: "#F5F2EC"), canvasBackground: Color(hex: "#EBE7DF"), panelBackground: Color(hex: "#FFFDF9"), cardBackground: Color(hex: "#FFFDF9"), primaryText: Color(hex: "#1C1917"), secondaryText: Color(hex: "#57534E"), border: Color(hex: "#D6D3CD"), accent: Color(hex: "#2957EE"), accentSoft: Color(hex: "#2957EE").opacity(0.2), gridColor: Color(hex: "#A8A29E"), shadowColor: Color(hex: "#292524").opacity(0.13), recommendedFont: .system, recommendedCornerStyle: .rounded, recommendedDensity: .comfortable)
        case .applePaper:
            return .init(name: "Apple Paper", appBackground: Color(hex: "#F8F5EF"), canvasBackground: Color(hex: "#F1EBE0"), panelBackground: Color(hex: "#FBF8F4"), cardBackground: Color(hex: "#FFFDF8"), primaryText: Color(hex: "#1C1917"), secondaryText: Color(hex: "#57534E"), border: Color(hex: "#D9D4CA"), accent: Color(hex: "#4B6BF5"), accentSoft: Color(hex: "#4B6BF5").opacity(0.18), gridColor: Color(hex: "#948C82"), shadowColor: Color(hex: "#292524").opacity(0.14), recommendedFont: .rounded, recommendedCornerStyle: .soft, recommendedDensity: .comfortable)
        case .linearGraphite:
            return .init(name: "Linear Graphite", appBackground: Color(hex: "#141210"), canvasBackground: Color(hex: "#0E0D0C"), panelBackground: Color(hex: "#1A1816"), cardBackground: Color(hex: "#201E1C"), primaryText: Color(hex: "#FAFAF9"), secondaryText: Color(hex: "#D6D3D1"), border: Color(hex: "#44403C"), accent: Color(hex: "#7CB4FF"), accentSoft: Color(hex: "#7CB4FF").opacity(0.22), gridColor: Color(hex: "#A8A29E"), shadowColor: Color.black.opacity(0.45), recommendedFont: .system, recommendedCornerStyle: .rounded, recommendedDensity: .compact)
        case .studioNeutral:
            return .init(name: "Studio Neutral", appBackground: Color(hex: "#EDEAE4"), canvasBackground: Color(hex: "#DDD9D2"), panelBackground: Color(hex: "#FAF8F5"), cardBackground: Color(hex: "#FFFDF9"), primaryText: Color(hex: "#1C1917"), secondaryText: Color(hex: "#57534E"), border: Color(hex: "#CAC5BD"), accent: Color(hex: "#3D52F5"), accentSoft: Color(hex: "#3D52F5").opacity(0.18), gridColor: Color(hex: "#94A098"), shadowColor: Color(hex: "#292524").opacity(0.12), recommendedFont: .serif, recommendedCornerStyle: .rounded, recommendedDensity: .spacious)
        case .auroraFocus:
            return .init(name: "Aurora Focus", appBackground: Color(hex: "#F2F0FF"), canvasBackground: Color(hex: "#E8E4FF"), panelBackground: Color(hex: "#FBFAFF"), cardBackground: Color(hex: "#FFFDFB"), primaryText: Color(hex: "#1C1917"), secondaryText: Color(hex: "#57534E"), border: Color(hex: "#D4D0E8"), accent: Color(hex: "#5C64F2"), accentSoft: Color(hex: "#5C64F2").opacity(0.2), gridColor: Color(hex: "#9894B8"), shadowColor: Color(hex: "#3730A3").opacity(0.08), recommendedFont: .rounded, recommendedCornerStyle: .soft, recommendedDensity: .comfortable)
        case .founderDesk:
            return .init(name: "Founder Desk", appBackground: Color(hex: "#F3F1EC"), canvasBackground: Color(hex: "#E8E4DC"), panelBackground: Color(hex: "#FAF9F6"), cardBackground: Color(hex: "#FFFDF9"), primaryText: Color(hex: "#1C1917"), secondaryText: Color(hex: "#57534E"), border: Color(hex: "#CEC9C2"), accent: Color(hex: "#2A52F0"), accentSoft: Color(hex: "#2A52F0").opacity(0.2), gridColor: Color(hex: "#908B84"), shadowColor: Color(hex: "#292524").opacity(0.14), recommendedFont: .rounded, recommendedCornerStyle: .rounded, recommendedDensity: .comfortable)
        }
    }

    static func resolve(colorScheme: ColorScheme, settings: AppAppearanceSettings) -> DynamicTheme {
        let preset = definition(for: settings.visualTheme)
        let isDark = colorScheme == .dark
        let accentTokens = AccentTokens.palette(settings.accentPalette)
        let fontStyle = settings.fontStyle == .system ? preset.recommendedFont : settings.fontStyle
        let cornerStyle = settings.cornerStyle == .rounded ? preset.recommendedCornerStyle : settings.cornerStyle
        let density = settings.interfaceDensity == .comfortable ? preset.recommendedDensity : settings.interfaceDensity

        return DynamicTheme(
            preset: preset,
            workspaceBackground: isDark ? preset.appBackground.opacity(0.42) : preset.appBackground,
            canvasWorkspaceBackground: isDark ? preset.canvasBackground.opacity(0.38) : preset.canvasBackground,
            gridLineOpacity: settings.canvasGridStyle == .none ? 0 : (isDark ? 0.052 : 0.036),
            canvasGridInk: preset.gridColor,
            canvasBottomDepthOpacity: isDark ? 0.065 : 0.038,
            canvasTopWashOpacity: isDark ? 0.009 : 0.03,
            canvasVignetteOpacity: isDark ? 0.09 : 0.045,
            canvasGrainOpacity: settings.canvasTextureEnabled ? (isDark ? 0.02 : 0.008) : 0,
            canvasGridEmphasis: settings.canvasGridStyle == .majorMinor ? 1 : 0.85,
            homeCardFill: preset.cardBackground,
            homeCardFillTop: preset.panelBackground,
            homeCardMaterial: isDark ? .thin : .none,
            homeCardBorderNormal: isDark ? 0.28 : 0.16,
            homeCardBorderHover: isDark ? 0.38 : 0.24,
            homeCardShadowOpacityNormal: isDark ? 0.34 : 0.08,
            homeCardShadowOpacityHover: isDark ? 0.45 : 0.14,
            homeCardShadowRadiusNormal: isDark ? 8 : 10,
            homeCardShadowRadiusHover: isDark ? 12 : 14,
            canvasTextBlockFill: preset.cardBackground.opacity(isDark ? 0.25 : 1),
            canvasTextBlockBorderOpacity: isDark ? 0.26 : 0.12,
            canvasItemShadowNormal: isDark ? 0.44 : 0.08,
            canvasItemShadowSelected: isDark ? 0.58 : 0.14,
            canvasItemShadowRadiusNormal: isDark ? 8 : 10,
            canvasItemShadowRadiusSelected: isDark ? 12 : 14,
            canvasItemShadowYNormal: 2.5,
            canvasItemShadowYSelected: 4,
            chartCardFill: preset.cardBackground.opacity(isDark ? 0.28 : 1),
            chartCardBorderOpacity: isDark ? 0.28 : 0.14,
            selectionStrokeColor: settings.useAccentInCanvasSelection ? accentTokens.accent : preset.accent,
            selectionStrokeWidth: 1.5,
            sidebarListTint: preset.panelBackground.opacity(isDark ? 0.24 : 0.82),
            sidebarFooterUseSystemBar: isDark,
            sidebarFooterMaterial: isDark ? .none : .thin,
            toolbarMaterial: isDark ? .ultraThin : .thin,
            toolbarFlatBackground: nil,
            inspectorChromeBackground: preset.panelBackground.opacity(isDark ? 0.3 : 0.9),
            accent: accentTokens.accent,
            accentSoft: accentTokens.accentSoft,
            accentGradientStart: accentTokens.gradientStart,
            accentGradientEnd: accentTokens.gradientEnd,
            density: DensityTokens.tokens(for: density),
            corners: CornerTokens.tokens(for: cornerStyle),
            motion: MotionTokens.tokens(for: settings.motionLevel),
            font: ThemeFont(style: fontStyle)
        )
    }
}

struct AccentTokens {
    let accent: Color
    let accentSoft: Color
    let gradientStart: Color
    let gradientEnd: Color

    static func palette(_ value: AccentPalette) -> AccentTokens {
        switch value {
        case .blue:
            return .init(
                accent: Color(hex: "#2A57F0"),
                accentSoft: Color(hex: "#2A57F0").opacity(0.22),
                gradientStart: Color(hex: "#1D3FB5"),
                gradientEnd: Color(hex: "#B4C9FF")
            )
        case .violet:
            return .init(
                accent: Color(hex: "#6D4AE8"),
                accentSoft: Color(hex: "#6D4AE8").opacity(0.22),
                gradientStart: Color(hex: "#5B21B6"),
                gradientEnd: Color(hex: "#DDD6FE")
            )
        case .mint:
            return .init(
                accent: Color(hex: "#0D9488"),
                accentSoft: Color(hex: "#0D9488").opacity(0.24),
                gradientStart: Color(hex: "#0F766E"),
                gradientEnd: Color(hex: "#CCFBF1")
            )
        case .coral:
            return .init(
                accent: Color(hex: "#EA580C"),
                accentSoft: Color(hex: "#EA580C").opacity(0.22),
                gradientStart: Color(hex: "#F97316"),
                gradientEnd: Color(hex: "#FECDD3")
            )
        case .amber:
            return .init(
                accent: Color(hex: "#CA6A06"),
                accentSoft: Color(hex: "#CA6A06").opacity(0.22),
                gradientStart: Color(hex: "#D97706"),
                gradientEnd: Color(hex: "#FDE68A")
            )
        case .rose:
            return .init(
                accent: Color(hex: "#E11D48"),
                accentSoft: Color(hex: "#E11D48").opacity(0.22),
                gradientStart: Color(hex: "#BE123C"),
                gradientEnd: Color(hex: "#FBCFE8")
            )
        }
    }
}

struct ThemeFont: Equatable {
    let body: Font
    let title: Font
    let caption: Font

    init(style: AppFontStyle) {
        switch style {
        case .system:
            body = .system(size: 14, weight: .regular)
            title = .system(size: 16, weight: .semibold)
            caption = .system(size: 12, weight: .regular)
        case .rounded:
            body = .system(size: 14, weight: .regular, design: .rounded)
            title = .system(size: 16, weight: .semibold, design: .rounded)
            caption = .system(size: 12, weight: .regular, design: .rounded)
        case .serif:
            body = .system(size: 14, weight: .regular, design: .serif)
            title = .system(size: 16, weight: .semibold, design: .serif)
            caption = .system(size: 12, weight: .regular, design: .serif)
        case .mono:
            body = .system(size: 14, weight: .regular, design: .monospaced)
            title = .system(size: 16, weight: .semibold, design: .monospaced)
            caption = .system(size: 12, weight: .regular, design: .monospaced)
        }
    }

    static let system = ThemeFont(style: .system)
}

struct DensityTokens: Equatable {
    let spacingScale: CGFloat
    let cardPadding: CGFloat
    let panelPadding: CGFloat

    static let compact = DensityTokens(spacingScale: 0.9, cardPadding: 12, panelPadding: 10)
    static let comfortable = DensityTokens(spacingScale: 1, cardPadding: 16, panelPadding: 12)
    static let spacious = DensityTokens(spacingScale: 1.12, cardPadding: 20, panelPadding: 16)

    static func tokens(for density: InterfaceDensity) -> DensityTokens {
        switch density {
        case .compact: return .compact
        case .comfortable: return .comfortable
        case .spacious: return .spacious
        }
    }
}

struct CornerTokens: Equatable {
    let card: CGFloat
    let panel: CGFloat
    let button: CGFloat
    let input: CGFloat
    let preview: CGFloat

    static func tokens(for style: CornerStyle) -> CornerTokens {
        switch style {
        case .soft: return .init(card: 20, panel: 18, button: 14, input: 12, preview: 14)
        case .rounded: return .init(card: 16, panel: 16, button: 12, input: 10, preview: 12)
        case .square: return .init(card: 10, panel: 10, button: 8, input: 7, preview: 8)
        }
    }
}

struct MotionTokens: Equatable {
    let quick: Animation
    let standard: Animation
    let smooth: Animation
    let disabled: Bool

    static let full = MotionTokens(quick: FlowDeskMotion.fastEaseOut, standard: FlowDeskMotion.mediumEaseOut, smooth: FlowDeskMotion.slowEaseOut, disabled: false)
    static let reduced = MotionTokens(quick: FlowDeskMotion.fastEaseOut, standard: FlowDeskMotion.fastEaseOut, smooth: FlowDeskMotion.mediumEaseOut, disabled: false)
    static let none = MotionTokens(quick: .linear(duration: 0), standard: .linear(duration: 0), smooth: .linear(duration: 0), disabled: true)

    static func tokens(for value: MotionLevel) -> MotionTokens {
        switch value {
        case .full: return .full
        case .reduced: return .reduced
        case .none: return .none
        }
    }
}

typealias FlowDeskAppearanceTokens = DynamicTheme
