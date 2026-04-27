import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum VisualTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case miroBright
    case applePaper
    case linearGraphite
    case studioNeutral
    case auroraFocus
    case founderDesk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .miroBright: return "Miro Bright"
        case .applePaper: return "Apple Paper"
        case .linearGraphite: return "Linear Graphite"
        case .studioNeutral: return "Studio Neutral"
        case .auroraFocus: return "Aurora Focus"
        case .founderDesk: return "Founder Desk"
        }
    }

    var isProTheme: Bool {
        switch self {
        case .auroraFocus, .founderDesk:
            return true
        case .miroBright, .applePaper, .linearGraphite, .studioNeutral:
            return false
        }
    }
}

enum AccentPalette: String, CaseIterable, Codable, Sendable, Identifiable {
    case blue
    case violet
    case mint
    case coral
    case amber
    case rose

    var id: String { rawValue }
}

enum AppFontStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case rounded
    case serif
    case mono

    var id: String { rawValue }
}

enum InterfaceDensity: String, CaseIterable, Codable, Sendable, Identifiable {
    case compact
    case comfortable
    case spacious

    var id: String { rawValue }
}

enum CornerStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case soft
    case rounded
    case square

    var id: String { rawValue }
}

enum MotionLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case full
    case reduced
    case none

    var id: String { rawValue }
}

enum CanvasBackgroundStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case clean
    case paper
    case grid
    case dots
    case gradient

    var id: String { rawValue }
}

enum CanvasGridStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case none
    case lines
    case dots
    case majorMinor

    var id: String { rawValue }
}

struct AppAppearanceSettings: Codable, Equatable, Sendable {
    var appearanceMode: AppearanceMode
    var visualTheme: VisualTheme
    var accentPalette: AccentPalette
    var useAccentInCanvasSelection: Bool
    var fontStyle: AppFontStyle
    var interfaceDensity: InterfaceDensity
    var cornerStyle: CornerStyle
    var motionLevel: MotionLevel
    var canvasBackgroundStyle: CanvasBackgroundStyle
    var canvasGridStyle: CanvasGridStyle
    var canvasTextureEnabled: Bool
    var canvasColorGlowEnabled: Bool

    static let `default` = AppAppearanceSettings(
        appearanceMode: .system,
        visualTheme: .founderDesk,
        accentPalette: .blue,
        useAccentInCanvasSelection: true,
        fontStyle: .rounded,
        interfaceDensity: .comfortable,
        cornerStyle: .rounded,
        motionLevel: .full,
        canvasBackgroundStyle: .paper,
        canvasGridStyle: .majorMinor,
        canvasTextureEnabled: true,
        canvasColorGlowEnabled: true
    )
}
