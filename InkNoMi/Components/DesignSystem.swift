import SwiftUI

struct DS {
    struct Color {
        // Strict visual system.
        static let background = SwiftUI.Color(hex: "#F7F4EE")
        static let cardBackground = SwiftUI.Color(hex: "#FFFFFF")
        static let primaryAccent = SwiftUI.Color(hex: "#336DFF")
        static let secondaryAccent = SwiftUI.Color(hex: "#6F7FF7")
        static let borderSubtle = SwiftUI.Color.black.opacity(0.05)
        static let borderStrong = SwiftUI.Color.black.opacity(0.08)
        static let textPrimary = SwiftUI.Color(hex: "#111827")
        static let textSecondary = SwiftUI.Color(hex: "#4B5563")
        static let textTertiary = SwiftUI.Color(hex: "#9CA3AF")

        // Compatibility aliases used across existing UI.
        static let canvas = background
        static let canvasTopWash = SwiftUI.Color(hex: "#FBF8F3")
        static let canvasBottom = SwiftUI.Color(hex: "#EEE8DE")
        static let appBackground = background
        static let backgroundCenterLift = SwiftUI.Color(hex: "#FCFAF6")
        static let backgroundEdgeShade = SwiftUI.Color(hex: "#EDE6DA")
        static let backgroundVignette = SwiftUI.Color.black.opacity(0.045)
        static let surfaceTop = SwiftUI.Color(hex: "#FFFFFF")
        static let surfaceBottom = SwiftUI.Color(hex: "#F7F3EC")
        static let surfaceFloatingTop = SwiftUI.Color(hex: "#FFFFFF")
        static let surfaceFloatingBottom = SwiftUI.Color(hex: "#F6F1E8")
        static let panel = cardBackground.opacity(0.92)
        static let border = borderSubtle
        static let borderWarm = borderStrong
        static let topInnerHighlight = SwiftUI.Color.white.opacity(0.46)
        static let hover = SwiftUI.Color.black.opacity(0.045)
        static let accent = primaryAccent
        static let highlight = SwiftUI.Color(hex: "#E4EBFF")
        static let active = primaryAccent.opacity(0.20)
        static let destructive = SwiftUI.Color(red: 0.79, green: 0.24, blue: 0.22)
        static let creationSurfaceBase = background
        static let creationSurfaceCenter = SwiftUI.Color.white.opacity(0.76)
        static let creationSurfaceEdge = SwiftUI.Color(hex: "#EAF0F9")
        static let creationSurfaceGrid = SwiftUI.Color.black.opacity(0.03)
        static let creationCardSurface = SwiftUI.Color(hex: "#F7FAFF").opacity(0.98)
        static let creationCardBorder = borderStrong
        static let homeSidebarSurface = SwiftUI.Color.white.opacity(0.92)
        static let homeSidebarBorder = SwiftUI.Color(hex: "#E5E7EB")
        static let homeMainBackground = SwiftUI.Color(hex: "#F8FAFC")
        static let homeMainBackgroundEdge = SwiftUI.Color(hex: "#F8FAFC")
        static let homeMainGrid = SwiftUI.Color(hex: "#CBD5E1").opacity(0.16)
        static let homeGlowBlue = SwiftUI.Color(hex: "#60A5FA").opacity(0.10)
        static let homeGlowPurple = SwiftUI.Color(hex: "#8B5CF6").opacity(0.06)
        static let homeChipFill = SwiftUI.Color.white.opacity(0.95)
        static let homeChipHover = SwiftUI.Color(hex: "#E2E8F0")
        static let homeChipActive = SwiftUI.Color(hex: "#DBEAFE")
        static let homePromptFill = SwiftUI.Color.white.opacity(0.97)
        static let homePromptBorder = SwiftUI.Color(hex: "#BFDBFE").opacity(0.7)
        static let homePromptInputFill = SwiftUI.Color(hex: "#F8FAFC")
        static let homePromptInputBorder = SwiftUI.Color(hex: "#CBD5E1").opacity(0.8)
    }

    struct Elevation {
        // Level 1: no shadow
        static let base = (radius: CGFloat(0), opacity: Double(0), y: CGFloat(0))
        // Level 2: cards
        static let card = (radius: CGFloat(12), opacity: Double(0.06), y: CGFloat(4))
        // Level 3: hover cards
        static let floating = (radius: CGFloat(20), opacity: Double(0.12), y: CGFloat(10))
        // Level 4: modals/dialogs
        static let active = (radius: CGFloat(40), opacity: Double(0.18), y: CGFloat(20))
    }

    struct Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        // Home layout rhythm.
        static let section: CGFloat = 32
        static let cardPadding: CGFloat = 16
        static let grid: CGFloat = 24
    }

    struct Shadow {
        static let base = (color: SwiftUI.Color.black.opacity(Elevation.base.opacity), radius: Elevation.base.radius, x: CGFloat(0), y: Elevation.base.y)
        static let soft = (color: SwiftUI.Color.black.opacity(Elevation.card.opacity), radius: Elevation.card.radius, x: CGFloat(0), y: Elevation.card.y)
        static let medium = (color: SwiftUI.Color.black.opacity(Elevation.floating.opacity), radius: Elevation.floating.radius, x: CGFloat(0), y: Elevation.floating.y)
        static let elevated = (color: SwiftUI.Color.black.opacity(Elevation.active.opacity), radius: Elevation.active.radius, x: CGFloat(0), y: Elevation.active.y)
    }

    struct Typography {
        static let hero = Font.system(size: 40, weight: .bold, design: .rounded)
        static let heroTracking: CGFloat = -0.45
        static let heroLineSpacing: CGFloat = 2

        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let sectionTracking: CGFloat = -0.18
        static let sectionTopSpacing: CGFloat = DS.Spacing.sm

        static let body = Font.system(size: 14.5, weight: .regular)
        static let bodyLineSpacing: CGFloat = 5

        static let label = Font.system(size: 12, weight: .regular)
        static let labelTracking: CGFloat = 0.6
        static let caption = Font.system(size: 11.5, weight: .regular)
        static let toolLabel = Font.system(size: 13, weight: .medium)
    }

    struct Animation {
        static let quick = FlowDeskMotion.quickEaseOut
        static let smooth = FlowDeskMotion.smoothEaseOut
        static let spring = FlowDeskMotion.mellowSpring
    }

    struct Interaction {
        static let hoverScale: CGFloat = 1.015
        static let pressScale: CGFloat = 0.98
        static let hoverDuration: Double = 0.12
        static let pressDuration: Double = 0.1
        static let releaseDuration: Double = 0.14
    }
}

extension SwiftUI.Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        default:
            r = 1
            g = 0
            b = 1
            a = 1
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
