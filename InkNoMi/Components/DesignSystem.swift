import SwiftUI

struct DS {
    struct Color {
        static let canvas = SwiftUI.Color(hex: "#FBFAF6")
        static let appBackground = SwiftUI.Color(hex: "#F4F1EA")

        static let panel = SwiftUI.Color.white.opacity(0.7)

        static let textPrimary = SwiftUI.Color(hex: "#1C1C1E")
        static let textSecondary = SwiftUI.Color(hex: "#6B6B6B")

        static let border = SwiftUI.Color.black.opacity(0.06)
        static let hover = SwiftUI.Color.black.opacity(0.04)

        static let accent = SwiftUI.Color(hex: "#4C8DFF")
        static let accentWarm = SwiftUI.Color(hex: "#D6A84A")
    }

    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    struct Shadow {
        static let soft = (
            color: SwiftUI.Color.black.opacity(0.05),
            radius: CGFloat(10),
            x: CGFloat(0),
            y: CGFloat(2)
        )
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
