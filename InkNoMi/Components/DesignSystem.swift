import SwiftUI

struct DS {
    struct Color {
        // Strict visual system.
        static let background = SwiftUI.Color(hex: "#F7FAFD")
        static let cardBackground = SwiftUI.Color(hex: "#FFFFFF")
        static let primaryAccent = SwiftUI.Color(hex: "#336DFF")
        static let secondaryAccent = SwiftUI.Color(hex: "#6F7FF7")
        static let borderSubtle = SwiftUI.Color(hex: "#1A1D24").opacity(0.10)
        static let borderStrong = SwiftUI.Color(hex: "#1A1D24").opacity(0.16)
        static let textPrimary = SwiftUI.Color(hex: "#171A21")
        static let textSecondary = SwiftUI.Color(hex: "#565D6D")
        static let textTertiary = SwiftUI.Color(hex: "#8D93A3")

        // Compatibility aliases used across existing UI.
        static let canvas = background
        static let canvasTopWash = SwiftUI.Color(hex: "#FBFDFF")
        static let canvasBottom = SwiftUI.Color(hex: "#EFF3F8")
        static let appBackground = background
        static let backgroundCenterLift = SwiftUI.Color(hex: "#FCFEFF")
        static let backgroundEdgeShade = SwiftUI.Color(hex: "#EDF2F8")
        static let backgroundVignette = SwiftUI.Color.black.opacity(0.045)
        static let surfaceTop = SwiftUI.Color(hex: "#FFFFFF")
        static let surfaceBottom = SwiftUI.Color(hex: "#F4F7FC")
        static let surfaceFloatingTop = SwiftUI.Color(hex: "#FFFFFF")
        static let surfaceFloatingBottom = SwiftUI.Color(hex: "#F2F6FF")
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
        static let homeSidebarBorder = SwiftUI.Color(hex: "#CBD5E1").opacity(0.55)
        static let homeMainBackground = SwiftUI.Color(hex: "#F8FBFF")
        static let homeMainBackgroundEdge = SwiftUI.Color(hex: "#EAF2FF")
        static let homeMainGrid = SwiftUI.Color(hex: "#94A3B8").opacity(0.16)
        static let homeGlowBlue = SwiftUI.Color(hex: "#93C5FD").opacity(0.30)
        static let homeGlowPurple = SwiftUI.Color(hex: "#C4B5FD").opacity(0.22)
        static let homeChipFill = SwiftUI.Color.white.opacity(0.95)
        static let homeChipHover = SwiftUI.Color(hex: "#E2E8F0")
        static let homeChipActive = SwiftUI.Color(hex: "#DBEAFE")
        static let homePromptFill = SwiftUI.Color.white.opacity(0.97)
        static let homePromptBorder = SwiftUI.Color(hex: "#BFDBFE").opacity(0.7)
        static let homePromptInputFill = SwiftUI.Color(hex: "#F8FAFC")
        static let homePromptInputBorder = SwiftUI.Color(hex: "#CBD5E1").opacity(0.8)
    }

    struct Elevation {
        static let base = (radius: CGFloat(8), opacity: Double(0.04), y: CGFloat(2))
        static let card = (radius: CGFloat(14), opacity: Double(0.07), y: CGFloat(6))
        static let floating = (radius: CGFloat(22), opacity: Double(0.11), y: CGFloat(12))
        static let active = (radius: CGFloat(30), opacity: Double(0.16), y: CGFloat(16))
    }

    struct Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
    }

    struct Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32

        // Home layout rhythm.
        static let section: CGFloat = 36
        static let cardPadding: CGFloat = 18
        static let grid: CGFloat = 22
    }

    struct Shadow {
        static let base = (color: SwiftUI.Color.black.opacity(Elevation.base.opacity), radius: Elevation.base.radius, x: CGFloat(0), y: Elevation.base.y)
        static let soft = (color: SwiftUI.Color.black.opacity(Elevation.card.opacity), radius: Elevation.card.radius, x: CGFloat(0), y: Elevation.card.y)
        static let medium = (color: SwiftUI.Color.black.opacity(Elevation.floating.opacity), radius: Elevation.floating.radius, x: CGFloat(0), y: Elevation.floating.y)
        static let elevated = (color: SwiftUI.Color.black.opacity(Elevation.active.opacity), radius: Elevation.active.radius, x: CGFloat(0), y: Elevation.active.y)
    }

    struct Typography {
        static let hero = Font.system(size: 40, weight: .bold, design: .rounded)
        static let heroTracking: CGFloat = -0.85
        static let heroLineSpacing: CGFloat = 3

        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let sectionTracking: CGFloat = -0.18
        static let sectionTopSpacing: CGFloat = DS.Spacing.sm

        static let body = Font.system(size: 14.5, weight: .regular)
        static let bodyLineSpacing: CGFloat = 4.5

        static let label = Font.system(size: 12, weight: .regular)
        static let labelTracking: CGFloat = 0.45
        static let caption = Font.system(size: 11.5, weight: .regular)
        static let toolLabel = Font.system(size: 13, weight: .medium)
    }

    struct Animation {
        static let quick = FlowDeskMotion.quickEaseOut
        static let smooth = FlowDeskMotion.smoothEaseOut
        static let spring = FlowDeskMotion.mellowSpring
    }

    struct Interaction {
        static let hoverScale: CGFloat = 1.02
        static let pressScale: CGFloat = 0.97
        static let hoverDuration: Double = 0.18
        static let pressDuration: Double = 0.12
        static let releaseDuration: Double = 0.16
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
