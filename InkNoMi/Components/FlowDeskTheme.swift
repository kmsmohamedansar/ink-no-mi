import AppKit
import SwiftUI

/// Geometry and export-time constants. **Dynamic colors** come from `FlowDeskAppearanceTokens`
/// (resolved per `ColorScheme` + user style preset) and are injected via `@Environment(\.flowDeskTokens)`.
enum FlowDeskTheme {
    enum DepthLevel {
        case base
        case elevated
        case floating
    }

    // MARK: - Core color identity

    /// Primary UI accent used across selection, highlights, and active controls.
    static let accentBlue = DS.Color.accent
    static let accentGold = DS.Color.highlight
    static let textPrimary = DS.Color.textPrimary
    static let textSecondary = DS.Color.textSecondary
    static let borderLight = DS.Color.border
    static let hoverNeutral = DS.Color.hover

    // MARK: - Depth (Level 2 floating panels — single shadow system)

    /// Tight, modern lift—subtle elevation without heavy blur.
    static let floatingPanelShadowOpacity: Double = 0.085
    static let floatingPanelShadowRadius: CGFloat = DS.Shadow.medium.radius
    static let floatingPanelShadowY: CGFloat = DS.Shadow.medium.y

    static func depthShadow(for level: DepthLevel) -> (color: Color, radius: CGFloat, y: CGFloat) {
        switch level {
        case .base:
            return (DS.Shadow.base.color, DS.Shadow.base.radius, DS.Shadow.base.y)
        case .elevated:
            return (DS.Shadow.soft.color, DS.Shadow.soft.radius, DS.Shadow.soft.y)
        case .floating:
            return (DS.Shadow.elevated.color, DS.Shadow.elevated.radius, DS.Shadow.elevated.y)
        }
    }

    /// Subtle global palette harmonization: gently reduce saturation and blend toward warm-paper neutral.
    static func harmonizedColor(_ color: Color, desaturation: CGFloat = 0.07, warmth: CGFloat = 0.06) -> Color {
        #if os(macOS)
        guard let converted = NSColor(color).usingColorSpace(.deviceRGB) else { return color }
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        converted.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let reducedS = max(0, s * (1 - desaturation))
        let toned = NSColor(hue: h, saturation: reducedS, brightness: b, alpha: a).usingColorSpace(.deviceRGB) ?? converted

        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        toned.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        // Warm neutral anchor (#F4EFE6-ish) for subtle cohesion.
        let wr: CGFloat = 0.956
        let wg: CGFloat = 0.937
        let wb: CGFloat = 0.902
        let t = max(0, min(1, warmth))
        let out = NSColor(
            red: r1 * (1 - t) + wr * t,
            green: g1 * (1 - t) + wg * t,
            blue: b1 * (1 - t) + wb * t,
            alpha: a1
        )
        return Color(out)
        #else
        return color
        #endif
    }

    static func surfaceGradient(for level: DepthLevel, colorScheme: ColorScheme) -> LinearGradient {
        switch (level, colorScheme) {
        case (.base, .light):
            return LinearGradient(
                colors: [harmonizedColor(DS.Color.canvasTopWash), harmonizedColor(DS.Color.canvasBottom)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case (.elevated, .light):
            return LinearGradient(
                colors: [harmonizedColor(DS.Color.surfaceTop), harmonizedColor(DS.Color.surfaceBottom)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case (.floating, .light):
            return LinearGradient(
                colors: [harmonizedColor(DS.Color.surfaceFloatingTop), harmonizedColor(DS.Color.surfaceFloatingBottom)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case (.base, .dark):
            return LinearGradient(
                colors: [harmonizedColor(Color.white.opacity(0.06)), harmonizedColor(Color.black.opacity(0.12))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case (.elevated, .dark):
            return LinearGradient(
                colors: [harmonizedColor(Color.white.opacity(0.11)), harmonizedColor(Color.black.opacity(0.2))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case (.floating, .dark):
            return LinearGradient(
                colors: [harmonizedColor(Color.white.opacity(0.15)), harmonizedColor(Color.black.opacity(0.24))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        @unknown default:
            return LinearGradient(
                colors: [harmonizedColor(DS.Color.surfaceTop), harmonizedColor(DS.Color.surfaceBottom)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func borderColor(for level: DepthLevel, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(level == .floating ? 0.2 : 0.14)
        }
        return DS.Color.borderWarm.opacity(level == .floating ? 1.15 : (level == .elevated ? 1 : 0.85))
    }

    static func topInnerHighlight(for level: DepthLevel, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(level == .floating ? 0.1 : 0.07)
        }
        return DS.Color.topInnerHighlight.opacity(level == .floating ? 0.9 : 0.72)
    }

    /// App chrome backdrop: center reads gently brighter than edges.
    static func homeAtmosphereWash(colorScheme: ColorScheme) -> RadialGradient {
        RadialGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.035), Color.clear, Color.black.opacity(0.09)]
                : [DS.Color.canvasTopWash.opacity(0.42), DS.Color.canvas.opacity(0.08), DS.Color.backgroundVignette.opacity(0.85)],
            center: .center,
            startRadius: 120,
            endRadius: 1600
        )
    }

    private static let backdropGrainTileNSImage: NSImage = {
        let w = 96
        let h = 96
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w,
            pixelsHigh: h,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: w * 4,
            bitsPerPixel: 32
        ), let data = rep.bitmapData else {
            return NSImage(size: NSSize(width: 16, height: 16))
        }
        for y in 0..<h {
            for x in 0..<w {
                var u = UInt64(x) &* 56_628_437 ^ UInt64(y) &* 362_436_069
                u ^= u << 7
                u ^= u >> 9
                let t = Double(u & 0xFFFF) / 65_535.0
                let g = UInt8(min(255, max(0, Int((0.52 + (t - 0.5) * 0.08) * 255.0))))
                let o = y * w * 4 + x * 4
                data[o] = g
                data[o + 1] = g
                data[o + 2] = g
                data[o + 3] = 255
            }
        }
        let img = NSImage(size: NSSize(width: w, height: h))
        img.addRepresentation(rep)
        return img
    }()

    @ViewBuilder
    static func premiumBackgroundBase(includeGrain: Bool = true) -> some View {
        ZStack {
            DS.Color.appBackground

            RadialGradient(
                colors: [
                    DS.Color.backgroundCenterLift.opacity(0.72),
                    DS.Color.backgroundCenterLift.opacity(0.26),
                    Color.clear
                ],
                center: .center,
                startRadius: 120,
                endRadius: 1200
            )
            .blendMode(.softLight)

            RadialGradient(
                colors: [
                    Color.clear,
                    DS.Color.backgroundEdgeShade.opacity(0.44)
                ],
                center: .center,
                startRadius: 420,
                endRadius: 1900
            )
            .blendMode(.multiply)

            RadialGradient(
                colors: [
                    Color.clear,
                    DS.Color.backgroundVignette
                ],
                center: .center,
                startRadius: 560,
                endRadius: 2200
            )
            .blendMode(.multiply)
            .opacity(0.52)

            if includeGrain {
                Image(nsImage: backdropGrainTileNSImage)
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity(0.016)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Canvas readability (dense boards)

    /// Elements outside the selection + one connector hop use this opacity (see `CanvasBoardView`).
    static let canvasBoardReadabilityDeemphasisOpacity: CGFloat = 0.86

    // MARK: - Canvas workspace (export / previews only)

    /// Matches warm-paper light tokens for predictable PNG/PDF output (board mat, not home chrome).
    static func canvasWorkspaceBackground(for colorScheme: ColorScheme) -> Color {
        DynamicTheme.resolve(colorScheme: colorScheme, settings: .default).canvasWorkspaceBackground
    }

    static var canvasWorkspaceBackgroundExport: Color {
        DynamicTheme.resolve(colorScheme: .light, settings: .default).canvasWorkspaceBackground
    }

    static func gridLineOpacity(for colorScheme: ColorScheme) -> Double {
        DynamicTheme.resolve(colorScheme: colorScheme, settings: .default).gridLineOpacity
    }

    // MARK: - Framed canvas items (geometry; aligned with `FlowDeskLayout.cardCornerRadius`)

    static var textBlockCornerRadius: CGFloat { FlowDeskLayout.cardCornerRadius }
    static var textBlockContentPadding: EdgeInsets { FlowDeskLayout.canvasCardContentPadding }

    static var chartCardCornerRadius: CGFloat { FlowDeskLayout.cardCornerRadius }
    static var chartCardContentPadding: CGFloat { FlowDeskLayout.canvasCardContentPadding.leading }
    static var chartTitleSpacing: CGFloat { FlowDeskLayout.chartTitleElementSpacing }

    static var shapeSelectionChromeCorner: CGFloat { FlowDeskLayout.shapeSelectionCornerRadius }
    static var strokeSelectionChromeCorner: CGFloat { FlowDeskLayout.strokeSelectionCornerRadius }

    // MARK: - Selection & handles (geometry; stroke color lives on tokens in canvas views)

    static let selectionStrokeWidth: CGFloat = 1.25
    static let selectionAccentOpacity: Double = 0.92

    /// Single product accent (aligned with appearance token accent bases).
    static let brandAccent = accentBlue

    static var selectionStrokeColor: Color {
        brandAccent.opacity(selectionAccentOpacity)
    }

    // MARK: - Shadows (export + legacy callers)

    static func cardShadowOpacity(selected: Bool) -> Double {
        let t = DynamicTheme.resolve(colorScheme: .light, settings: .default)
        return selected ? t.canvasItemShadowSelected : t.canvasItemShadowNormal
    }

    static func cardShadowRadius(selected: Bool) -> CGFloat {
        let t = DynamicTheme.resolve(colorScheme: .light, settings: .default)
        return selected ? t.canvasItemShadowRadiusSelected : t.canvasItemShadowRadiusNormal
    }

    static func cardShadowY(selected: Bool) -> CGFloat {
        let t = DynamicTheme.resolve(colorScheme: .light, settings: .default)
        return selected ? t.canvasItemShadowYSelected : t.canvasItemShadowYNormal
    }

    // MARK: - Floating panel chrome (palette, toolbars, HUD)

    /// Hairline rim shared by palette rail, context panels, selection toolbars, zoom HUD, tips.
    static var chromeHairlineBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.borderWarm.opacity(0.95),
                Color.primary.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    static func floatingPanelStackedFill(
        tokens: FlowDeskAppearanceTokens,
        colorScheme: ColorScheme,
        cornerRadius: CGFloat,
        lightOpacity: Double,
        darkOpacity: Double
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(surfaceGradient(for: .floating, colorScheme: colorScheme).opacity(colorScheme == .dark ? darkOpacity * 1.45 : lightOpacity))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tokens.homeCardFill.opacity(colorScheme == .dark ? darkOpacity * 0.5 : lightOpacity * 0.78))
        }
    }

    /// Connector labels and similar inline canvas annotations (one shadow language).
    static let canvasAuxiliaryLabelShadowOpacity: Double = 0.12
    static let canvasAuxiliaryLabelShadowOpacityHover: Double = 0.22
    static let canvasAuxiliaryLabelShadowRadius: CGFloat = 2
    static let canvasAuxiliaryLabelShadowRadiusHover: CGFloat = 3
    static let canvasAuxiliaryLabelShadowY: CGFloat = 1

    // MARK: - Canvas mat (infinite board surface)

    /// Neutral 72×72 tile; `overlay` at low opacity reads as paper tooth, not speckle noise.
    private static let canvasMatGrainTileNSImage: NSImage = {
        let w = 72
        let h = 72
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w,
            pixelsHigh: h,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: w * 4,
            bitsPerPixel: 32
        ), let data = rep.bitmapData else {
            return NSImage(size: NSSize(width: 16, height: 16))
        }
        for y in 0..<h {
            for x in 0..<w {
                var u = UInt64(x) &* 92_837_111 ^ UInt64(y) &* 689_287_499
                u = u &* 2_246_822_519
                u ^= u >> 13
                u = u &* 3_266_489_917
                let t = Double(u & 0xFFFF) / 65_535.0
                let g = UInt8(min(255, max(0, Int((0.48 + (t - 0.5) * 0.11) * 255.0))))
                let o = y * w * 4 + x * 4
                data[o] = g
                data[o + 1] = g
                data[o + 2] = g
                data[o + 3] = 255
            }
        }
        let img = NSImage(size: NSSize(width: w, height: h))
        img.addRepresentation(rep)
        return img
    }()

    /// Layered board “environment”: warm base → center lift → top air wash → readable grid → soft vignette → paper grain.
    /// Light mode uses a warm stone mat so the surface reads as physical workspace, not cold flat grey.
    @ViewBuilder
    static func canvasWorkspaceMatBackground(
        tokens: FlowDeskAppearanceTokens,
        colorScheme: ColorScheme,
        showGrid: Bool,
        spotlightCenter: UnitPoint,
        zoomScale: CGFloat = 1,
        idleLuminanceAmount: Double = 0,
        gridFadeCenter: UnitPoint = .center,
        includeFilmGrain: Bool,
        interactionLift: Bool = false
    ) -> some View {
        let isLight = colorScheme == .light
        /// Warm neutral paper base (premium light canvas).
        let matBaseLight = Color(hex: "#F4F1EA")
        /// Light taupe grid ink — paired with low opacity so lines stay auxiliary.
        let gridInkLight = Color(hex: "#ADA8A2")
        let gridLineOpacityBase: Double = {
            let base = tokens.gridLineOpacity * tokens.canvasGridEmphasis
            if isLight {
                return min(base * 0.92, 0.038)
            }
            return min(base * 0.74, 0.054)
        }()
        // Zoom-aware drafting feel: fade grid when zoomed out, sharpen as you zoom in.
        let zoomT = min(max((zoomScale - 0.25) / 1.75, 0), 1) // normalized around useful drafting range
        let gridLineOpacity = gridLineOpacityBase * (0.62 + 0.56 * zoomT)
        let gridLineWidth = FlowDeskLayout.gridLineWidth * (0.92 + 0.24 * zoomT)
        /// Radial center lift — subtle physical-surface lighting (target ~0.06–0.1 range).
        let radialPeak: Double = isLight ? 0.09 : 0.07
        /// Ultra-subtle grayscale noise (1–2%) so the surface avoids digital flatness.
        let grainOpacity: Double = {
            let floor = 0.01
            let ceiling = 0.02
            if includeFilmGrain {
                return min(max(tokens.canvasGrainOpacity, floor), ceiling)
            }
            return 0
        }()

        ZStack {
            Group {
                if isLight {
                    matBaseLight
                } else {
                    tokens.canvasWorkspaceBackground
                }
            }

            // Center radial lift — reads as ambient light on the mat.
            RadialGradient(
                colors: [
                    Color.white.opacity(radialPeak),
                    Color.white.opacity(radialPeak * 0.35),
                    Color.clear
                ],
                center: spotlightCenter,
                startRadius: 80,
                endRadius: 920
            )
            .blendMode(.softLight)
            .allowsHitTesting(false)

            // Top wash: white → transparent (open, airy ceiling light).
            LinearGradient(
                colors: [
                    Color.white.opacity(isLight ? 0.42 : 0.14),
                    Color.white.opacity(0)
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .blendMode(.normal)
            .allowsHitTesting(false)

            // Ultra-subtle vertical depth pass: barely brighter at top, slightly warmer/darker near bottom.
            LinearGradient(
                colors: [
                    Color.white.opacity(isLight ? 0.03 : 0.018),
                    Color.clear,
                    Color(hex: "#D9D1C5").opacity(isLight ? 0.026 : 0.016)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
            .opacity(isLight ? 0.88 : 0.74)
            .allowsHitTesting(false)

            // Idle luminance drift (10–15s cadence): barely perceptible life in the surface.
            Color.white
                .opacity((isLight ? 0.0032 : 0.0024) * abs(idleLuminanceAmount))
                .blendMode(idleLuminanceAmount >= 0 ? .softLight : .multiply)
                .allowsHitTesting(false)

            // Gentle vertical depth (warm floor) — keeps hierarchy without muddy grey.
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "#E5E0D8").opacity(isLight ? 0.38 : 0.2)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.35),
                endPoint: .bottom
            )
            .blendMode(.multiply)
            .opacity(isLight ? 0.55 : 0.45)
            .allowsHitTesting(false)

            if showGrid {
                CanvasGridOverlay(
                    spacing: 24,
                    lineWidth: gridLineWidth,
                    lineOpacity: gridLineOpacity,
                    gridInk: isLight ? gridInkLight : tokens.canvasGridInk.opacity(0.92),
                    majorLineStride: 4
                )
                .mask {
                    GeometryReader { proxy in
                        let fadeRadius = hypot(proxy.size.width, proxy.size.height) * 0.5
                        RadialGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.9), location: 0.22),
                                .init(color: .white.opacity(0.52), location: 0.52),
                                .init(color: .white.opacity(0.06), location: 1)
                            ],
                            center: gridFadeCenter,
                            startRadius: 0,
                            endRadius: fadeRadius
                        )
                    }
                }
                .allowsHitTesting(false)
            }

            // Ultra-soft vignette — subtle edge darkening to keep attention near center.
            RadialGradient(
                stops: [
                    .init(color: .clear, location: 0.55),
                    .init(color: Color.black.opacity(isLight ? 0.018 : 0.03), location: 0.82),
                    .init(color: Color.black.opacity(isLight ? 0.032 : 0.05), location: 1)
                ],
                center: .center,
                startRadius: 760,
                endRadius: 2_900
            )
            .blendMode(.multiply)
            .allowsHitTesting(false)

            if includeFilmGrain, grainOpacity > 0.0001 {
                Image(nsImage: canvasMatGrainTileNSImage)
                    .resizable(resizingMode: .tile)
                    .saturation(0)
                    .blendMode(.softLight)
                    .opacity(grainOpacity)
                    .allowsHitTesting(false)
            }
        }
        .brightness(interactionLift ? 0.015 : 0)
        .animation(FlowDeskMotion.fastEaseOut, value: interactionLift)
    }
}

// MARK: - Inspector

/// Section headers: same density as sidebar section titles for quick scanning.
struct FlowDeskInspectorSectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(FlowDeskTypography.inspectorEyebrow)
            .foregroundStyle(DS.Color.textTertiary.opacity(colorScheme == .dark ? 0.86 : 1))
            .textCase(.uppercase)
            .tracking(FlowDeskTypeTracking.labelUppercase)
            .padding(.bottom, FlowDeskLayout.inspectorSectionHeaderBottomSpacing)
    }
}

// MARK: - Brand identity

/// Calm wordmark: rounded “Flow” + slightly quieter “Desk” (not system all-caps eyebrow).
struct FlowDeskWordmark: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("Ink")
                .font(FlowDeskFont.display(size: FlowDeskTypeScale.h2, weight: .semibold))
                .tracking(FlowDeskTypeTracking.displayH2)
            Text(" no Mi")
                .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.h2, weight: .medium))
                .tracking(FlowDeskTypeTracking.displayTight)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Ink no Mi")
    }
}

/// Stacked “sheets” mark—product-owned silhouette instead of a lone SF Symbol.
struct FlowDeskSheetsStackMark: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 80

    var body: some View {
        let corner = size * 0.12
        let sheetW = size * 0.56
        let sheetH = size * 0.7
        let isDark = colorScheme == .dark

        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(tokens.homeCardFill.opacity(isDark ? 0.32 : 0.46))
                .frame(width: sheetW, height: sheetH)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Color.primary.opacity(isDark ? 0.12 : 0.08), lineWidth: 0.75)
                }
                .rotationEffect(.degrees(-8))
                .offset(x: -size * 0.1, y: size * 0.06)
                .shadow(color: .black.opacity(isDark ? 0.22 : 0.07), radius: size * 0.045, x: 0, y: size * 0.022)

            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(tokens.homeCardFill.opacity(isDark ? 0.42 : 0.58))
                .frame(width: sheetW, height: sheetH)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Color.primary.opacity(isDark ? 0.14 : 0.1), lineWidth: 0.75)
                }
                .rotationEffect(.degrees(4))
                .offset(x: size * 0.04, y: -size * 0.02)
                .shadow(color: .black.opacity(isDark ? 0.28 : 0.085), radius: size * 0.05, x: 0, y: size * 0.03)

            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(tokens.workspaceBackground)
                .frame(width: sheetW, height: sheetH)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Color.primary.opacity(isDark ? 0.2 : 0.11), lineWidth: 1)
                }
                .shadow(color: .black.opacity(isDark ? 0.35 : 0.1), radius: size * 0.055, x: 0, y: size * 0.038)
        }
        .frame(width: size * 1.2, height: size * 1.05)
        .accessibilityHidden(true)
    }
}

