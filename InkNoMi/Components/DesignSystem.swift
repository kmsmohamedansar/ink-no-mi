import SwiftUI

struct DS {
    struct Color {
        // Warm neutrals (stone-tinted), rich primary blues — avoids cold “default SaaS grey”.
        static let background = SwiftUI.Color(hex: "#F5F2EC")
        static let cardBackground = SwiftUI.Color(hex: "#FFFDF9")
        static let primaryAccent = SwiftUI.Color(hex: "#2957EE")
        static let secondaryAccent = SwiftUI.Color(hex: "#8BA3FF")
        static let premiumBlueStart = SwiftUI.Color(hex: "#1F4DFF")
        static let premiumBlueEnd = SwiftUI.Color(hex: "#6FA8FF")
        static let borderSubtle = SwiftUI.Color(hex: "#2F2A27").opacity(0.045)
        static let borderStrong = SwiftUI.Color(hex: "#2F2A27").opacity(0.075)
        static let textPrimary = SwiftUI.Color(hex: "#171310")
        static let textSecondary = SwiftUI.Color(hex: "#6B625A")
        static let textTertiary = SwiftUI.Color(hex: "#B5ABA2")

        // Compatibility aliases used across existing UI.
        static let canvas = background
        static let canvasTopWash = SwiftUI.Color(hex: "#FBF9F5")
        static let canvasBottom = SwiftUI.Color(hex: "#EDE8DD")
        static let appBackground = background
        static let backgroundCenterLift = SwiftUI.Color(hex: "#FCFAF7")
        static let backgroundEdgeShade = SwiftUI.Color(hex: "#E8E2D8")
        static let backgroundVignette = SwiftUI.Color(hex: "#292524").opacity(0.045)
        static let surfaceTop = SwiftUI.Color(hex: "#FFFDF9")
        static let surfaceBottom = SwiftUI.Color(hex: "#F4EFE6")
        static let surfaceFloatingTop = SwiftUI.Color(hex: "#FFFDF9")
        static let surfaceFloatingBottom = SwiftUI.Color(hex: "#F2EDE4")
        static let panel = cardBackground.opacity(0.92)
        static let border = borderSubtle
        static let borderWarm = borderStrong
        static let topInnerHighlight = SwiftUI.Color.white.opacity(0.46)
        static let hover = SwiftUI.Color(hex: "#312B28").opacity(0.045)
        static let accent = primaryAccent
        static let premiumBlueGradient = LinearGradient(
            colors: [premiumBlueStart, premiumBlueEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let highlight = SwiftUI.Color(hex: "#E8EEFF")
        static let active = primaryAccent.opacity(0.20)
        static let destructive = SwiftUI.Color(red: 0.79, green: 0.24, blue: 0.22)

        /// Board / creation surfaces — soft pastels (lavender mist, warm paper).
        static let creationSurfaceBase = background
        static let creationSurfaceCenter = SwiftUI.Color.white.opacity(0.78)
        static let creationSurfaceEdge = SwiftUI.Color(hex: "#EDE9FE").opacity(0.95)
        static let creationSurfaceGrid = SwiftUI.Color(hex: "#292524").opacity(0.032)
        static let creationCardSurface = SwiftUI.Color(hex: "#FAF8FF").opacity(0.98)
        static let creationCardBorder = borderStrong
        static let homeSidebarSurface = SwiftUI.Color(hex: "#FFFDF9").opacity(0.94)
        static let homeSidebarBorder = SwiftUI.Color(hex: "#D8D0C8")
        static let homeMainBackground = SwiftUI.Color(hex: "#F7F5F1")
        static let homeMainBackgroundEdge = SwiftUI.Color(hex: "#EFEBE5")
        static let homeMainGrid = SwiftUI.Color(hex: "#B0A69D").opacity(0.14)
        static let homeGlowBlue = SwiftUI.Color(hex: "#93C5FD").opacity(0.14)
        static let homeGlowPurple = SwiftUI.Color(hex: "#C4B5FD").opacity(0.10)
        static let homeChipFill = SwiftUI.Color(hex: "#FFFDF9").opacity(0.96)
        static let homeChipHover = SwiftUI.Color(hex: "#E9E2DA")
        static let homeChipActive = SwiftUI.Color(hex: "#DBEAFE")
        static let homePromptFill = SwiftUI.Color(hex: "#FFFDF9").opacity(0.98)
        static let homePromptBorder = SwiftUI.Color(hex: "#BFDBFE").opacity(0.65)
        static let homePromptInputFill = SwiftUI.Color(hex: "#FAFAF9")
        static let homePromptInputBorder = SwiftUI.Color(hex: "#D8CFC6").opacity(0.85)
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
        /// Uses **SF Pro Display** (see `FlowDeskFont`).
        static let hero = FlowDeskFont.display(size: FlowDeskTypeScale.h1, weight: .bold)
        static let heroTracking: CGFloat = FlowDeskTypeTracking.displayH1
        static let heroLineSpacing: CGFloat = 2

        static let sectionTitle = FlowDeskFont.display(size: FlowDeskTypeScale.h2, weight: .semibold)
        static let sectionTracking: CGFloat = FlowDeskTypeTracking.displayH2
        static let sectionTopSpacing: CGFloat = DS.Spacing.sm

        /// Board name in the editor toolbar — reads like a document title, not a form field.
        static let boardTitle = FlowDeskFont.display(size: FlowDeskTypeScale.h2 + 3, weight: .semibold)
        static let boardTitleTracking: CGFloat = FlowDeskTypeTracking.displayH2

        /// Primary body: **SF Pro Text**.
        static let body = FlowDeskFont.uiText(size: FlowDeskTypeScale.body, weight: .regular)
        static let bodyLineSpacing: CGFloat = 5

        static let label = FlowDeskFont.uiText(size: 12, weight: .regular)
        static let labelTracking: CGFloat = FlowDeskTypeTracking.labelUppercase
        static let caption = FlowDeskFont.uiText(size: FlowDeskTypeScale.caption, weight: .regular)
        static let toolLabel = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium)
    }

    struct Icon {
        /// Standard icon sizing/stroke for primary app chrome and controls.
        static let standardSize: CGFloat = 13
        static let standardWeight: Font.Weight = .semibold
        static let accessorySize: CGFloat = 12
    }

    struct Animation {
        static let fast = FlowDeskMotion.fastEaseOut
        static let medium = FlowDeskMotion.mediumEaseOut
        static let slow = FlowDeskMotion.slowEaseOut
        static let quick = fast
        static let smooth = medium
        static let spring = medium
    }

    struct Interaction {
        /// Subtle hover emphasis for cards / surfaces (paired with motion tokens).
        static let hoverScale: CGFloat = 1.012
        /// Slight scale-down on press (instant ease-out, no bounce).
        static let pressScale: CGFloat = 0.98
        /// Vertical lift when hovered (toolbar, plain controls).
        static let hoverLiftPoints: CGFloat = -1
        static let hoverDuration: Double = 0.14
        static let pressDuration: Double = 0.12
        static let releaseDuration: Double = 0.12
    }
}

extension Image {
    /// Product-wide icon treatment: one stroke weight, one rendering style.
    func flowDeskStandardIcon(size: CGFloat = DS.Icon.standardSize) -> some View {
        self
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size, weight: DS.Icon.standardWeight))
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
