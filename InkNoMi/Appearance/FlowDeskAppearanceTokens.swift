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
            return .init(name: "Miro Bright", appBackground: Color(hex: "#F6F8FC"), canvasBackground: Color(hex: "#EEF3FB"), panelBackground: Color(hex: "#FFFFFF"), cardBackground: Color(hex: "#FFFFFF"), primaryText: Color(hex: "#111827"), secondaryText: Color(hex: "#4B5563"), border: Color(hex: "#D8E0EF"), accent: Color(hex: "#336DFF"), accentSoft: Color(hex: "#336DFF").opacity(0.2), gridColor: Color(hex: "#60708F"), shadowColor: Color.black.opacity(0.14), recommendedFont: .system, recommendedCornerStyle: .rounded, recommendedDensity: .comfortable)
        case .applePaper:
            return .init(name: "Apple Paper", appBackground: Color(hex: "#F8F5EF"), canvasBackground: Color(hex: "#F2EBDD"), panelBackground: Color(hex: "#FBF8F2"), cardBackground: Color(hex: "#FFFDF8"), primaryText: Color(hex: "#1F2937"), secondaryText: Color(hex: "#6B7280"), border: Color(hex: "#DDD3C2"), accent: Color(hex: "#4E7CF6"), accentSoft: Color(hex: "#4E7CF6").opacity(0.18), gridColor: Color(hex: "#76685A"), shadowColor: Color.black.opacity(0.16), recommendedFont: .rounded, recommendedCornerStyle: .soft, recommendedDensity: .comfortable)
        case .linearGraphite:
            return .init(name: "Linear Graphite", appBackground: Color(hex: "#11131A"), canvasBackground: Color(hex: "#0B0F16"), panelBackground: Color(hex: "#171B25"), cardBackground: Color(hex: "#1C2230"), primaryText: Color(hex: "#F5F7FB"), secondaryText: Color(hex: "#C7CFDF"), border: Color(hex: "#31394A"), accent: Color(hex: "#6EA8FF"), accentSoft: Color(hex: "#6EA8FF").opacity(0.22), gridColor: Color(hex: "#738099"), shadowColor: Color.black.opacity(0.45), recommendedFont: .system, recommendedCornerStyle: .rounded, recommendedDensity: .compact)
        case .studioNeutral:
            return .init(name: "Studio Neutral", appBackground: Color(hex: "#EEF1F4"), canvasBackground: Color(hex: "#DDE2E8"), panelBackground: Color(hex: "#F8FAFB"), cardBackground: Color(hex: "#FFFFFF"), primaryText: Color(hex: "#17202A"), secondaryText: Color(hex: "#5C6677"), border: Color(hex: "#CCD3DE"), accent: Color(hex: "#4361EE"), accentSoft: Color(hex: "#4361EE").opacity(0.18), gridColor: Color(hex: "#7A869A"), shadowColor: Color.black.opacity(0.14), recommendedFont: .serif, recommendedCornerStyle: .rounded, recommendedDensity: .spacious)
        case .auroraFocus:
            return .init(name: "Aurora Focus", appBackground: Color(hex: "#EEF4FF"), canvasBackground: Color(hex: "#E0EAFE"), panelBackground: Color(hex: "#F8FBFF"), cardBackground: Color(hex: "#FFFFFF"), primaryText: Color(hex: "#111827"), secondaryText: Color(hex: "#4B5563"), border: Color(hex: "#CFD9F0"), accent: Color(hex: "#5B6CFF"), accentSoft: Color(hex: "#5B6CFF").opacity(0.2), gridColor: Color(hex: "#6A77A1"), shadowColor: Color.black.opacity(0.14), recommendedFont: .rounded, recommendedCornerStyle: .soft, recommendedDensity: .comfortable)
        case .founderDesk:
            return .init(name: "Founder Desk", appBackground: Color(hex: "#F2F4F8"), canvasBackground: Color(hex: "#E7ECF4"), panelBackground: Color(hex: "#F7F9FC"), cardBackground: Color(hex: "#FFFFFF"), primaryText: Color(hex: "#101828"), secondaryText: Color(hex: "#475467"), border: Color(hex: "#C9D2E3"), accent: Color(hex: "#2E5BFF"), accentSoft: Color(hex: "#2E5BFF").opacity(0.2), gridColor: Color(hex: "#627089"), shadowColor: Color.black.opacity(0.16), recommendedFont: .rounded, recommendedCornerStyle: .rounded, recommendedDensity: .comfortable)
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
            gridLineOpacity: settings.canvasGridStyle == .none ? 0 : (isDark ? 0.09 : 0.06),
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
        case .blue: return .init(accent: Color(hex: "#336DFF"), accentSoft: Color(hex: "#336DFF").opacity(0.2), gradientStart: Color(hex: "#336DFF"), gradientEnd: Color(hex: "#6F7FF7"))
        case .violet: return .init(accent: Color(hex: "#7C3AED"), accentSoft: Color(hex: "#7C3AED").opacity(0.2), gradientStart: Color(hex: "#8B5CF6"), gradientEnd: Color(hex: "#C084FC"))
        case .mint: return .init(accent: Color(hex: "#14B8A6"), accentSoft: Color(hex: "#14B8A6").opacity(0.22), gradientStart: Color(hex: "#14B8A6"), gradientEnd: Color(hex: "#22D3EE"))
        case .coral: return .init(accent: Color(hex: "#F97316"), accentSoft: Color(hex: "#F97316").opacity(0.2), gradientStart: Color(hex: "#FB7185"), gradientEnd: Color(hex: "#F97316"))
        case .amber: return .init(accent: Color(hex: "#D97706"), accentSoft: Color(hex: "#D97706").opacity(0.2), gradientStart: Color(hex: "#F59E0B"), gradientEnd: Color(hex: "#F97316"))
        case .rose: return .init(accent: Color(hex: "#E11D48"), accentSoft: Color(hex: "#E11D48").opacity(0.2), gradientStart: Color(hex: "#F43F5E"), gradientEnd: Color(hex: "#EC4899"))
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

    static let full = MotionTokens(quick: .easeOut(duration: 0.12), standard: .easeOut(duration: 0.2), smooth: .easeOut(duration: 0.26), disabled: false)
    static let reduced = MotionTokens(quick: .easeOut(duration: 0.06), standard: .easeOut(duration: 0.12), smooth: .easeOut(duration: 0.15), disabled: false)
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
