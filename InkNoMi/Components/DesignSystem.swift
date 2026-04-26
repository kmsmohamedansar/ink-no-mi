import SwiftUI

struct DS {
    struct Color {
        // InkNoMi identity: calm warm thinking surface.
        static let canvas = SwiftUI.Color(hex: "#FBFAF6")
        static let canvasTopWash = SwiftUI.Color(hex: "#FFFFFF")
        static let canvasBottom = SwiftUI.Color(hex: "#F5F2EA")
        static let appBackground = SwiftUI.Color(hex: "#F4F1EA")

        // Panels stay soft and translucent (70–85%) above canvas/app layers.
        static let panel = SwiftUI.Color.white.opacity(0.78)
        static let textPrimary = SwiftUI.Color(hex: "#1C1C1E")
        static let textSecondary = SwiftUI.Color(hex: "#6B6B6B")
        static let border = SwiftUI.Color.black.opacity(0.06)
        static let hover = SwiftUI.Color.black.opacity(0.04)

        // Single product accent: used only for active/selection/highlight states.
        static let accent = SwiftUI.Color(hex: "#4C8DFF")
        static let highlight = SwiftUI.Color(hex: "#DCE8FF")
        static let active = accent.opacity(0.14)
        static let destructive = SwiftUI.Color(red: 0.79, green: 0.24, blue: 0.22)
    }

    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
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
    }

    struct Shadow {
        static let soft = (
            color: SwiftUI.Color.black.opacity(0.05),
            radius: CGFloat(10),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        static let medium = (
            color: SwiftUI.Color.black.opacity(0.08),
            radius: CGFloat(14),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        static let elevated = (
            color: SwiftUI.Color.black.opacity(0.14),
            radius: CGFloat(18),
            x: CGFloat(0),
            y: CGFloat(8)
        )
    }

    struct Typography {
        static let title = Font.system(size: 28, weight: .bold)
        static let sectionLabel = Font.system(size: 12, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let toolLabel = Font.system(size: 13, weight: .medium)
    }

    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.12)
        static let smooth = SwiftUI.Animation.easeOut(duration: 0.18)
        static let spring = SwiftUI.Animation.spring(response: 0.34, dampingFraction: 0.82)
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
