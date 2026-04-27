import SwiftUI

enum FlowDeskMaterialLayer: Equatable { case none, ultraThin, thin, regular }

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
        let p = definition(for: settings.visualTheme)
        let isDark = colorScheme == .dark
        let a = AccentTokens.palette(settings.accentPalette)
        let fontStyle = settings.fontStyle == .system ? p.recommendedFont : settings.fontStyle
        let corners = settings.cornerStyle == .rounded ? p.recommendedCornerStyle : settings.cornerStyle
        let density = settings.interfaceDensity == .comfortable ? p.recommendedDensity : settings.interfaceDensity

        return .init(
            preset: p,
            workspaceBackground: isDark ? p.appBackground.opacity(0.42) : p.appBackground,
            canvasWorkspaceBackground: isDark ? p.canvasBackground.opacity(0.38) : p.canvasBackground,
            gridLineOpacity: settings.canvasGridStyle == .none ? 0 : (isDark ? 0.09 : 0.06),
            canvasGridInk: p.gridColor,
            canvasBottomDepthOpacity: isDark ? 0.065 : 0.038,
            canvasTopWashOpacity: isDark ? 0.009 : 0.03,
            canvasVignetteOpacity: isDark ? 0.09 : 0.045,
            canvasGrainOpacity: settings.canvasTextureEnabled ? (isDark ? 0.02 : 0.008) : 0,
            canvasGridEmphasis: settings.canvasGridStyle == .majorMinor ? 1 : 0.85,
            homeCardFill: p.cardBackground,
            homeCardFillTop: p.panelBackground,
            homeCardMaterial: isDark ? .thin : .none,
            homeCardBorderNormal: isDark ? 0.28 : 0.16,
            homeCardBorderHover: isDark ? 0.38 : 0.24,
            homeCardShadowOpacityNormal: isDark ? 0.34 : 0.08,
            homeCardShadowOpacityHover: isDark ? 0.45 : 0.14,
            homeCardShadowRadiusNormal: isDark ? 8 : 10,
            homeCardShadowRadiusHover: isDark ? 12 : 14,
            canvasTextBlockFill: p.cardBackground.opacity(isDark ? 0.25 : 1),
            canvasTextBlockBorderOpacity: isDark ? 0.26 : 0.12,
            canvasItemShadowNormal: isDark ? 0.44 : 0.08,
            canvasItemShadowSelected: isDark ? 0.58 : 0.14,
            canvasItemShadowRadiusNormal: isDark ? 8 : 10,
            canvasItemShadowRadiusSelected: isDark ? 12 : 14,
            canvasItemShadowYNormal: 2.5,
            canvasItemShadowYSelected: 4,
            chartCardFill: p.cardBackground.opacity(isDark ? 0.28 : 1),
            chartCardBorderOpacity: isDark ? 0.28 : 0.14,
            selectionStrokeColor: settings.useAccentInCanvasSelection ? a.accent : p.accent,
            selectionStrokeWidth: 1.5,
            sidebarListTint: p.panelBackground.opacity(isDark ? 0.24 : 0.82),
            sidebarFooterUseSystemBar: isDark,
            sidebarFooterMaterial: isDark ? .none : .thin,
            toolbarMaterial: isDark ? .ultraThin : .thin,
            toolbarFlatBackground: nil,
            inspectorChromeBackground: p.panelBackground.opacity(isDark ? 0.3 : 0.9),
            accent: a.accent,
            accentSoft: a.accentSoft,
            accentGradientStart: a.gradientStart,
            accentGradientEnd: a.gradientEnd,
            density: DensityTokens.tokens(for: density),
            corners: CornerTokens.tokens(for: corners),
            motion: MotionTokens.tokens(for: settings.motionLevel),
            font: ThemeFont(style: fontStyle)
        )
    }
}

struct AccentTokens { let accent: Color; let accentSoft: Color; let gradientStart: Color; let gradientEnd: Color
    static func palette(_ v: AccentPalette) -> AccentTokens {
        switch v {
        case .blue: return .init(accent: Color(hex: "#336DFF"), accentSoft: Color(hex: "#336DFF").opacity(0.2), gradientStart: Color(hex: "#336DFF"), gradientEnd: Color(hex: "#6F7FF7"))
        case .violet: return .init(accent: Color(hex: "#7C3AED"), accentSoft: Color(hex: "#7C3AED").opacity(0.2), gradientStart: Color(hex: "#8B5CF6"), gradientEnd: Color(hex: "#C084FC"))
        case .mint: return .init(accent: Color(hex: "#14B8A6"), accentSoft: Color(hex: "#14B8A6").opacity(0.22), gradientStart: Color(hex: "#14B8A6"), gradientEnd: Color(hex: "#22D3EE"))
        case .coral: return .init(accent: Color(hex: "#F97316"), accentSoft: Color(hex: "#F97316").opacity(0.2), gradientStart: Color(hex: "#FB7185"), gradientEnd: Color(hex: "#F97316"))
        case .amber: return .init(accent: Color(hex: "#D97706"), accentSoft: Color(hex: "#D97706").opacity(0.2), gradientStart: Color(hex: "#F59E0B"), gradientEnd: Color(hex: "#F97316"))
        case .rose: return .init(accent: Color(hex: "#E11D48"), accentSoft: Color(hex: "#E11D48").opacity(0.2), gradientStart: Color(hex: "#F43F5E"), gradientEnd: Color(hex: "#EC4899"))
        }
    }
}

struct ThemeFont: Equatable { let body: Font; let title: Font; let caption: Font
    init(style: AppFontStyle) {
        switch style {
        case .system: body = .system(size: 14); title = .system(size: 16, weight: .semibold); caption = .system(size: 12)
        case .rounded: body = .system(size: 14, design: .rounded); title = .system(size: 16, weight: .semibold, design: .rounded); caption = .system(size: 12, design: .rounded)
        case .serif: body = .system(size: 14, design: .serif); title = .system(size: 16, weight: .semibold, design: .serif); caption = .system(size: 12, design: .serif)
        case .mono: body = .system(size: 14, design: .monospaced); title = .system(size: 16, weight: .semibold, design: .monospaced); caption = .system(size: 12, design: .monospaced)
        }
    }
}

struct DensityTokens: Equatable { let spacingScale: CGFloat; let cardPadding: CGFloat; let panelPadding: CGFloat
    static let compact = DensityTokens(spacingScale: 0.9, cardPadding: 12, panelPadding: 10)
    static let comfortable = DensityTokens(spacingScale: 1, cardPadding: 16, panelPadding: 12)
    static let spacious = DensityTokens(spacingScale: 1.12, cardPadding: 20, panelPadding: 16)
    static func tokens(for value: InterfaceDensity) -> DensityTokens { value == .compact ? .compact : (value == .spacious ? .spacious : .comfortable) }
}

struct CornerTokens: Equatable { let card: CGFloat; let panel: CGFloat; let button: CGFloat; let input: CGFloat; let preview: CGFloat
    static func tokens(for v: CornerStyle) -> CornerTokens {
        switch v { case .soft: return .init(card: 20, panel: 18, button: 14, input: 12, preview: 14); case .rounded: return .init(card: 16, panel: 16, button: 12, input: 10, preview: 12); case .square: return .init(card: 10, panel: 10, button: 8, input: 7, preview: 8) }
    }
}

struct MotionTokens: Equatable { let quick: Animation; let standard: Animation; let smooth: Animation; let disabled: Bool
    static let full = MotionTokens(quick: .easeOut(duration: 0.12), standard: .easeOut(duration: 0.2), smooth: .easeOut(duration: 0.26), disabled: false)
    static let reduced = MotionTokens(quick: .easeOut(duration: 0.06), standard: .easeOut(duration: 0.12), smooth: .easeOut(duration: 0.15), disabled: false)
    static let none = MotionTokens(quick: .linear(duration: 0), standard: .linear(duration: 0), smooth: .linear(duration: 0), disabled: true)
    static func tokens(for v: MotionLevel) -> MotionTokens { v == .none ? .none : (v == .reduced ? .reduced : .full) }
}

typealias FlowDeskAppearanceTokens = DynamicTheme
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
            return .init(
                name: "Miro Bright",
                appBackground: Color(hex: "#F6F8FC"),
                canvasBackground: Color(hex: "#EEF3FB"),
                panelBackground: Color(hex: "#FFFFFF"),
                cardBackground: Color(hex: "#FFFFFF"),
                primaryText: Color(hex: "#111827"),
                secondaryText: Color(hex: "#4B5563"),
                border: Color(hex: "#D8E0EF"),
                accent: Color(hex: "#336DFF"),
                accentSoft: Color(hex: "#336DFF").opacity(0.2),
                gridColor: Color(hex: "#60708F"),
                shadowColor: Color.black.opacity(0.14),
                recommendedFont: .system,
                recommendedCornerStyle: .rounded,
                recommendedDensity: .comfortable
            )
        case .applePaper:
            return .init(
                name: "Apple Paper",
                appBackground: Color(hex: "#F8F5EF"),
                canvasBackground: Color(hex: "#F2EBDD"),
                panelBackground: Color(hex: "#FBF8F2"),
                cardBackground: Color(hex: "#FFFDF8"),
                primaryText: Color(hex: "#1F2937"),
                secondaryText: Color(hex: "#6B7280"),
                border: Color(hex: "#DDD3C2"),
                accent: Color(hex: "#4E7CF6"),
                accentSoft: Color(hex: "#4E7CF6").opacity(0.18),
                gridColor: Color(hex: "#76685A"),
                shadowColor: Color.black.opacity(0.16),
                recommendedFont: .rounded,
                recommendedCornerStyle: .soft,
                recommendedDensity: .comfortable
            )
        case .linearGraphite:
            return .init(
                name: "Linear Graphite",
                appBackground: Color(hex: "#11131A"),
                canvasBackground: Color(hex: "#0B0F16"),
                panelBackground: Color(hex: "#171B25"),
                cardBackground: Color(hex: "#1C2230"),
                primaryText: Color(hex: "#F5F7FB"),
                secondaryText: Color(hex: "#B9C1D2"),
                border: Color(hex: "#31394A"),
                accent: Color(hex: "#6EA8FF"),
                accentSoft: Color(hex: "#6EA8FF").opacity(0.22),
                gridColor: Color(hex: "#738099"),
                shadowColor: Color.black.opacity(0.45),
                recommendedFont: .system,
                recommendedCornerStyle: .rounded,
                recommendedDensity: .compact
            )
        case .studioNeutral:
            return .init(
                name: "Studio Neutral",
                appBackground: Color(hex: "#EEF1F4"),
                canvasBackground: Color(hex: "#DDE2E8"),
                panelBackground: Color(hex: "#F8FAFB"),
                cardBackground: Color(hex: "#FFFFFF"),
                primaryText: Color(hex: "#17202A"),
                secondaryText: Color(hex: "#5C6677"),
                border: Color(hex: "#CCD3DE"),
                accent: Color(hex: "#4361EE"),
                accentSoft: Color(hex: "#4361EE").opacity(0.18),
                gridColor: Color(hex: "#7A869A"),
                shadowColor: Color.black.opacity(0.14),
                recommendedFont: .serif,
                recommendedCornerStyle: .rounded,
                recommendedDensity: .spacious
            )
        case .auroraFocus:
            return .init(
                name: "Aurora Focus",
                appBackground: Color(hex: "#EEF4FF"),
                canvasBackground: Color(hex: "#E0EAFE"),
                panelBackground: Color(hex: "#F8FBFF"),
                cardBackground: Color(hex: "#FFFFFF"),
                primaryText: Color(hex: "#111827"),
                secondaryText: Color(hex: "#4B5563"),
                border: Color(hex: "#CFD9F0"),
                accent: Color(hex: "#5B6CFF"),
                accentSoft: Color(hex: "#5B6CFF").opacity(0.2),
                gridColor: Color(hex: "#6A77A1"),
                shadowColor: Color.black.opacity(0.14),
                recommendedFont: .rounded,
                recommendedCornerStyle: .soft,
                recommendedDensity: .comfortable
            )
        case .founderDesk:
            return .init(
                name: "Founder Desk",
                appBackground: Color(hex: "#F2F4F8"),
                canvasBackground: Color(hex: "#E7ECF4"),
                panelBackground: Color(hex: "#F7F9FC"),
                cardBackground: Color(hex: "#FFFFFF"),
                primaryText: Color(hex: "#101828"),
                secondaryText: Color(hex: "#475467"),
                border: Color(hex: "#C9D2E3"),
                accent: Color(hex: "#2E5BFF"),
                accentSoft: Color(hex: "#2E5BFF").opacity(0.2),
                gridColor: Color(hex: "#627089"),
                shadowColor: Color.black.opacity(0.16),
                recommendedFont: .rounded,
                recommendedCornerStyle: .rounded,
                recommendedDensity: .comfortable
            )
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
import AppKit
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

struct DynamicTheme: Equatable {
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

    static func resolve(colorScheme: ColorScheme, settings: AppAppearanceSettings) -> DynamicTheme {
        let base: DynamicTheme
        switch (settings.visualTheme, colorScheme) {
        case (.bright, .light): base = brightLight
        case (.bright, .dark): base = brightDark
        case (.calm, .light): base = calmLight
        case (.calm, .dark): base = calmDark
        case (.paper, .light): base = paperLight
        case (.paper, .dark): base = paperDark
        case (.graphite, .light): base = graphiteLight
        case (.graphite, .dark): base = graphiteDark
        case (.aurora, .light): base = auroraLight
        case (.aurora, .dark): base = auroraDark
        case (.studio, .light): base = studioLight
        case (.studio, .dark): base = studioDark
        @unknown default: base = paperLight
        }
        return base.applying(settings: settings)
    }

    private static let accentStrokeLight = DS.Color.accent
    private static let accentStrokeDark = Color(nsColor: NSColor(red: 0.55, green: 0.76, blue: 1.0, alpha: 1))

    private static let paperLight = DynamicTheme(
        workspaceBackground: DS.Color.appBackground,
        canvasWorkspaceBackground: DS.Color.canvas,
        gridLineOpacity: 0.03,
        canvasGridInk: Color(nsColor: NSColor(red: 0.28, green: 0.24, blue: 0.2, alpha: 1)),
        canvasBottomDepthOpacity: 0.042,
        canvasTopWashOpacity: 0.03,
        canvasVignetteOpacity: 0.028,
        canvasGrainOpacity: 0.007,
        canvasGridEmphasis: 1.0,
        homeCardFill: Color(nsColor: NSColor(red: 0.976, green: 0.949, blue: 0.91, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 0.996, green: 0.979, blue: 0.946, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.14,
        homeCardBorderHover: 0.19,
        homeCardShadowOpacityNormal: 0.05,
        homeCardShadowOpacityHover: 0.084,
        homeCardShadowRadiusNormal: 10,
        homeCardShadowRadiusHover: 13,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.992, green: 0.973, blue: 0.939, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.12,
        canvasItemShadowNormal: 0.05,
        canvasItemShadowSelected: 0.085,
        canvasItemShadowRadiusNormal: 8,
        canvasItemShadowRadiusSelected: 11,
        canvasItemShadowYNormal: 2,
        canvasItemShadowYSelected: 3,
        chartCardFill: Color(nsColor: NSColor(red: 0.994, green: 0.976, blue: 0.943, alpha: 1)),
        chartCardBorderOpacity: 0.12,
        selectionStrokeColor: accentStrokeLight.opacity(0.92),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.962, green: 0.943, blue: 0.908, alpha: 0.78)),
        sidebarFooterUseSystemBar: false,
        sidebarFooterMaterial: .thin,
        toolbarMaterial: .thin,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.985, green: 0.969, blue: 0.942, alpha: 0.9)),
        accent: DS.Color.accent,
        accentSoft: DS.Color.accent.opacity(0.2),
        accentGradientStart: DS.Color.accent,
        accentGradientEnd: DS.Color.secondaryAccent,
        density: .comfortable,
        corners: .rounded,
        motion: .full,
        font: .system
    )
    private static let paperDark = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.118, green: 0.102, blue: 0.092, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.048, green: 0.042, blue: 0.038, alpha: 1)),
        gridLineOpacity: 0.082,
        canvasGridInk: Color(nsColor: NSColor(red: 0.58, green: 0.53, blue: 0.49, alpha: 1)),
        canvasBottomDepthOpacity: 0.059,
        canvasTopWashOpacity: 0.01,
        canvasVignetteOpacity: 0.094,
        canvasGrainOpacity: 0.026,
        canvasGridEmphasis: 0.88,
        homeCardFill: Color(nsColor: NSColor(red: 0.27, green: 0.232, blue: 0.212, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 0.27, green: 0.232, blue: 0.212, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.22,
        homeCardBorderHover: 0.32,
        homeCardShadowOpacityNormal: 0.32,
        homeCardShadowOpacityHover: 0.44,
        homeCardShadowRadiusNormal: 8,
        homeCardShadowRadiusHover: 11,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.26, green: 0.228, blue: 0.208, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.22,
        canvasItemShadowNormal: 0.42,
        canvasItemShadowSelected: 0.56,
        canvasItemShadowRadiusNormal: 8,
        canvasItemShadowRadiusSelected: 12,
        canvasItemShadowYNormal: 2.75,
        canvasItemShadowYSelected: 4,
        chartCardFill: Color(nsColor: NSColor(red: 0.262, green: 0.23, blue: 0.21, alpha: 1)),
        chartCardBorderOpacity: 0.24,
        selectionStrokeColor: accentStrokeDark.opacity(0.94),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.152, green: 0.128, blue: 0.114, alpha: 0.94)),
        sidebarFooterUseSystemBar: true,
        sidebarFooterMaterial: .none,
        toolbarMaterial: .thin,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.21, green: 0.182, blue: 0.165, alpha: 0.92)),
        accent: accentStrokeDark,
        accentSoft: accentStrokeDark.opacity(0.24),
        accentGradientStart: accentStrokeDark,
        accentGradientEnd: Color(nsColor: NSColor.systemPurple),
        density: .comfortable,
        corners: .rounded,
        motion: .full,
        font: .system
    )
    private static let graphiteLight = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.972, green: 0.976, blue: 0.984, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.785, green: 0.792, blue: 0.808, alpha: 1)),
        gridLineOpacity: 0.065,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.045,
        canvasTopWashOpacity: 0.013,
        canvasVignetteOpacity: 0.054,
        canvasGrainOpacity: 0.018,
        canvasGridEmphasis: 0.86,
        homeCardFill: Color(nsColor: NSColor(red: 0.998, green: 0.999, blue: 1, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 0.998, green: 0.999, blue: 1, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.15,
        homeCardBorderHover: 0.22,
        homeCardShadowOpacityNormal: 0.055,
        homeCardShadowOpacityHover: 0.085,
        homeCardShadowRadiusNormal: 6,
        homeCardShadowRadiusHover: 9,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.994, green: 0.996, blue: 1, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.125,
        canvasItemShadowNormal: 0.065,
        canvasItemShadowSelected: 0.11,
        canvasItemShadowRadiusNormal: 7,
        canvasItemShadowRadiusSelected: 10,
        canvasItemShadowYNormal: 2.5,
        canvasItemShadowYSelected: 3.5,
        chartCardFill: Color(nsColor: NSColor(red: 0.992, green: 0.994, blue: 1, alpha: 1)),
        chartCardBorderOpacity: 0.125,
        selectionStrokeColor: accentStrokeLight.opacity(0.94),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.898, green: 0.905, blue: 0.922, alpha: 0.94)),
        sidebarFooterUseSystemBar: true,
        sidebarFooterMaterial: .none,
        toolbarMaterial: .ultraThin,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.948, green: 0.952, blue: 0.962, alpha: 0.96)),
        accent: DS.Color.accent,
        accentSoft: DS.Color.accent.opacity(0.2),
        accentGradientStart: DS.Color.accent,
        accentGradientEnd: Color(hex: "#8B5CF6"),
        density: .comfortable,
        corners: .rounded,
        motion: .full,
        font: .system
    )
    private static let graphiteDark = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.098, green: 0.104, blue: 0.124, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.048, green: 0.054, blue: 0.072, alpha: 1)),
        gridLineOpacity: 0.092,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.061,
        canvasTopWashOpacity: 0.009,
        canvasVignetteOpacity: 0.092,
        canvasGrainOpacity: 0.028,
        canvasGridEmphasis: 0.88,
        homeCardFill: Color(nsColor: NSColor(red: 0.22, green: 0.226, blue: 0.246, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 0.22, green: 0.226, blue: 0.246, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.24,
        homeCardBorderHover: 0.34,
        homeCardShadowOpacityNormal: 0.36,
        homeCardShadowOpacityHover: 0.48,
        homeCardShadowRadiusNormal: 8,
        homeCardShadowRadiusHover: 11,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.214, green: 0.222, blue: 0.242, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.26,
        canvasItemShadowNormal: 0.44,
        canvasItemShadowSelected: 0.58,
        canvasItemShadowRadiusNormal: 8,
        canvasItemShadowRadiusSelected: 12,
        canvasItemShadowYNormal: 2.75,
        canvasItemShadowYSelected: 4,
        chartCardFill: Color(nsColor: NSColor(red: 0.218, green: 0.226, blue: 0.246, alpha: 1)),
        chartCardBorderOpacity: 0.27,
        selectionStrokeColor: accentStrokeDark.opacity(0.93),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.118, green: 0.126, blue: 0.148, alpha: 0.92)),
        sidebarFooterUseSystemBar: true,
        sidebarFooterMaterial: .none,
        toolbarMaterial: .ultraThin,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.175, green: 0.184, blue: 0.204, alpha: 0.88)),
        accent: accentStrokeDark,
        accentSoft: accentStrokeDark.opacity(0.2),
        accentGradientStart: accentStrokeDark,
        accentGradientEnd: Color(hex: "#A855F7"),
        density: .comfortable,
        corners: .rounded,
        motion: .full,
        font: .system
    )
    private static let calmLight = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.965, green: 0.968, blue: 0.978, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.805, green: 0.812, blue: 0.828, alpha: 1)),
        gridLineOpacity: 0.055,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.038,
        canvasTopWashOpacity: 0.012,
        canvasVignetteOpacity: 0.046,
        canvasGrainOpacity: 0.016,
        canvasGridEmphasis: 0.84,
        homeCardFill: Color.white.opacity(0.34),
        homeCardFillTop: Color.white.opacity(0.34),
        homeCardMaterial: .regular,
        homeCardBorderNormal: 0.16,
        homeCardBorderHover: 0.24,
        homeCardShadowOpacityNormal: 0.06,
        homeCardShadowOpacityHover: 0.092,
        homeCardShadowRadiusNormal: 6,
        homeCardShadowRadiusHover: 9,
        canvasTextBlockFill: Color(nsColor: NSColor.white.withAlphaComponent(0.88)),
        canvasTextBlockBorderOpacity: 0.14,
        canvasItemShadowNormal: 0.07,
        canvasItemShadowSelected: 0.12,
        canvasItemShadowRadiusNormal: 7,
        canvasItemShadowRadiusSelected: 10,
        canvasItemShadowYNormal: 2.5,
        canvasItemShadowYSelected: 3.75,
        chartCardFill: Color(nsColor: NSColor.white.withAlphaComponent(0.9)),
        chartCardBorderOpacity: 0.15,
        selectionStrokeColor: accentStrokeLight.opacity(0.94),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor.white.withAlphaComponent(0.28)),
        sidebarFooterUseSystemBar: false,
        sidebarFooterMaterial: .thin,
        toolbarMaterial: .regular,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color.white.opacity(0.32),
        accent: Color(hex: "#3B82F6"),
        accentSoft: Color(hex: "#3B82F6").opacity(0.2),
        accentGradientStart: Color(hex: "#3B82F6"),
        accentGradientEnd: Color(hex: "#14B8A6"),
        density: .comfortable,
        corners: .soft,
        motion: .full,
        font: .rounded
    )
    private static let calmDark = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.082, green: 0.09, blue: 0.112, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.038, green: 0.046, blue: 0.064, alpha: 1)),
        gridLineOpacity: 0.09,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.056,
        canvasTopWashOpacity: 0.008,
        canvasVignetteOpacity: 0.084,
        canvasGrainOpacity: 0.024,
        canvasGridEmphasis: 0.86,
        homeCardFill: Color.white.opacity(0.11),
        homeCardFillTop: Color.white.opacity(0.11),
        homeCardMaterial: .regular,
        homeCardBorderNormal: 0.26,
        homeCardBorderHover: 0.36,
        homeCardShadowOpacityNormal: 0.38,
        homeCardShadowOpacityHover: 0.5,
        homeCardShadowRadiusNormal: 8,
        homeCardShadowRadiusHover: 11,
        canvasTextBlockFill: Color(nsColor: NSColor.white.withAlphaComponent(0.14)),
        canvasTextBlockBorderOpacity: 0.26,
        canvasItemShadowNormal: 0.45,
        canvasItemShadowSelected: 0.6,
        canvasItemShadowRadiusNormal: 8,
        canvasItemShadowRadiusSelected: 12,
        canvasItemShadowYNormal: 3,
        canvasItemShadowYSelected: 4.5,
        chartCardFill: Color(nsColor: NSColor.white.withAlphaComponent(0.16)),
        chartCardBorderOpacity: 0.28,
        selectionStrokeColor: accentStrokeDark.opacity(0.94),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color.white.opacity(0.12),
        sidebarFooterUseSystemBar: false,
        sidebarFooterMaterial: .thin,
        toolbarMaterial: .regular,
        toolbarFlatBackground: nil,
        inspectorChromeBackground: Color.white.opacity(0.14),
        accent: Color(hex: "#7DD3FC"),
        accentSoft: Color(hex: "#7DD3FC").opacity(0.18),
        accentGradientStart: Color(hex: "#60A5FA"),
        accentGradientEnd: Color(hex: "#2DD4BF"),
        density: .comfortable,
        corners: .soft,
        motion: .full,
        font: .rounded
    )
    private static let brightLight = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.988, green: 0.988, blue: 0.992, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.858, green: 0.862, blue: 0.875, alpha: 1)),
        gridLineOpacity: 0.075,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.048,
        canvasTopWashOpacity: 0.011,
        canvasVignetteOpacity: 0.049,
        canvasGrainOpacity: 0.015,
        canvasGridEmphasis: 0.86,
        homeCardFill: Color(nsColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.16,
        homeCardBorderHover: 0.24,
        homeCardShadowOpacityNormal: 0.048,
        homeCardShadowOpacityHover: 0.075,
        homeCardShadowRadiusNormal: 6,
        homeCardShadowRadiusHover: 9,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.996, green: 0.997, blue: 1, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.135,
        canvasItemShadowNormal: 0.06,
        canvasItemShadowSelected: 0.1,
        canvasItemShadowRadiusNormal: 7,
        canvasItemShadowRadiusSelected: 10,
        canvasItemShadowYNormal: 2.25,
        canvasItemShadowYSelected: 3.25,
        chartCardFill: Color(nsColor: NSColor(red: 0.994, green: 0.995, blue: 1, alpha: 1)),
        chartCardBorderOpacity: 0.135,
        selectionStrokeColor: accentStrokeLight.opacity(0.92),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.918, green: 0.918, blue: 0.93, alpha: 0.94)),
        sidebarFooterUseSystemBar: true,
        sidebarFooterMaterial: .none,
        toolbarMaterial: .none,
        toolbarFlatBackground: Color(nsColor: NSColor.windowBackgroundColor),
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.972, green: 0.972, blue: 0.98, alpha: 0.98)),
        accent: Color(hex: "#2563EB"),
        accentSoft: Color(hex: "#2563EB").opacity(0.16),
        accentGradientStart: Color(hex: "#2563EB"),
        accentGradientEnd: Color(hex: "#7C3AED"),
        density: .compact,
        corners: .rounded,
        motion: .full,
        font: .system
    )
    private static let brightDark = DynamicTheme(
        workspaceBackground: Color(nsColor: NSColor(red: 0.112, green: 0.11, blue: 0.116, alpha: 1)),
        canvasWorkspaceBackground: Color(nsColor: NSColor(red: 0.055, green: 0.055, blue: 0.06, alpha: 1)),
        gridLineOpacity: 0.108,
        canvasGridInk: Color.primary,
        canvasBottomDepthOpacity: 0.062,
        canvasTopWashOpacity: 0.008,
        canvasVignetteOpacity: 0.096,
        canvasGrainOpacity: 0.028,
        canvasGridEmphasis: 0.88,
        homeCardFill: Color(nsColor: NSColor(red: 0.232, green: 0.23, blue: 0.236, alpha: 1)),
        homeCardFillTop: Color(nsColor: NSColor(red: 0.232, green: 0.23, blue: 0.236, alpha: 1)),
        homeCardMaterial: .none,
        homeCardBorderNormal: 0.28,
        homeCardBorderHover: 0.38,
        homeCardShadowOpacityNormal: 0.4,
        homeCardShadowOpacityHover: 0.52,
        homeCardShadowRadiusNormal: 8,
        homeCardShadowRadiusHover: 11,
        canvasTextBlockFill: Color(nsColor: NSColor(red: 0.228, green: 0.226, blue: 0.232, alpha: 1)),
        canvasTextBlockBorderOpacity: 0.28,
        canvasItemShadowNormal: 0.45,
        canvasItemShadowSelected: 0.58,
        canvasItemShadowRadiusNormal: 7,
        canvasItemShadowRadiusSelected: 10,
        canvasItemShadowYNormal: 2.5,
        canvasItemShadowYSelected: 3.5,
        chartCardFill: Color(nsColor: NSColor(red: 0.224, green: 0.222, blue: 0.228, alpha: 1)),
        chartCardBorderOpacity: 0.3,
        selectionStrokeColor: accentStrokeDark.opacity(0.93),
        selectionStrokeWidth: 1.5,
        sidebarListTint: Color(nsColor: NSColor(red: 0.148, green: 0.146, blue: 0.152, alpha: 0.92)),
        sidebarFooterUseSystemBar: true,
        sidebarFooterMaterial: .none,
        toolbarMaterial: .none,
        toolbarFlatBackground: Color(nsColor: NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)),
        inspectorChromeBackground: Color(nsColor: NSColor(red: 0.192, green: 0.19, blue: 0.196, alpha: 0.94)),
        accent: Color(hex: "#60A5FA"),
        accentSoft: Color(hex: "#60A5FA").opacity(0.2),
        accentGradientStart: Color(hex: "#60A5FA"),
        accentGradientEnd: Color(hex: "#A78BFA"),
        density: .compact,
        corners: .rounded,
        motion: .full,
        font: .system
    )

    private static let auroraLight = brightLight
    private static let auroraDark = brightDark
    private static let studioLight = graphiteLight
    private static let studioDark = graphiteDark
}

extension DynamicTheme {
    private func applying(settings: AppAppearanceSettings) -> DynamicTheme {
        let accentTokens = AccentTokens.palette(settings.accentPalette)
        return DynamicTheme(
            workspaceBackground: workspaceBackground,
            canvasWorkspaceBackground: canvasWorkspaceBackground,
            gridLineOpacity: settings.canvasGridStyle == .none ? 0 : gridLineOpacity,
            canvasGridInk: canvasGridInk,
            canvasBottomDepthOpacity: canvasBottomDepthOpacity,
            canvasTopWashOpacity: canvasTopWashOpacity,
            canvasVignetteOpacity: canvasVignetteOpacity,
            canvasGrainOpacity: settings.canvasTextureEnabled ? canvasGrainOpacity : 0,
            canvasGridEmphasis: canvasGridEmphasis,
            homeCardFill: homeCardFill,
            homeCardFillTop: homeCardFillTop,
            homeCardMaterial: homeCardMaterial,
            homeCardBorderNormal: homeCardBorderNormal,
            homeCardBorderHover: homeCardBorderHover,
            homeCardShadowOpacityNormal: homeCardShadowOpacityNormal,
            homeCardShadowOpacityHover: homeCardShadowOpacityHover,
            homeCardShadowRadiusNormal: homeCardShadowRadiusNormal,
            homeCardShadowRadiusHover: homeCardShadowRadiusHover,
            canvasTextBlockFill: canvasTextBlockFill,
            canvasTextBlockBorderOpacity: canvasTextBlockBorderOpacity,
            canvasItemShadowNormal: canvasItemShadowNormal,
            canvasItemShadowSelected: canvasItemShadowSelected,
            canvasItemShadowRadiusNormal: canvasItemShadowRadiusNormal,
            canvasItemShadowRadiusSelected: canvasItemShadowRadiusSelected,
            canvasItemShadowYNormal: canvasItemShadowYNormal,
            canvasItemShadowYSelected: canvasItemShadowYSelected,
            chartCardFill: chartCardFill,
            chartCardBorderOpacity: chartCardBorderOpacity,
            selectionStrokeColor: settings.useAccentInCanvasSelection ? accentTokens.accent : selectionStrokeColor,
            selectionStrokeWidth: selectionStrokeWidth,
            sidebarListTint: sidebarListTint,
            sidebarFooterUseSystemBar: sidebarFooterUseSystemBar,
            sidebarFooterMaterial: sidebarFooterMaterial,
            toolbarMaterial: toolbarMaterial,
            toolbarFlatBackground: toolbarFlatBackground,
            inspectorChromeBackground: inspectorChromeBackground,
            accent: accentTokens.accent,
            accentSoft: accentTokens.accentSoft,
            accentGradientStart: accentTokens.gradientStart,
            accentGradientEnd: accentTokens.gradientEnd,
            density: DensityTokens.tokens(for: settings.interfaceDensity),
            corners: CornerTokens.tokens(for: settings.cornerStyle),
            motion: MotionTokens.tokens(for: settings.motionLevel),
            font: ThemeFont(style: settings.fontStyle)
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
