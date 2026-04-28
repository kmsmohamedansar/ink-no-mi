import AppKit
import Foundation
import SwiftUI

/// Plain-text block content and styling. Designed for Codable persistence and future rich-text migration.
struct TextBlockPayload: Codable, Equatable, Sendable {
    var text: String
    /// Font size in points (canvas space).
    var fontSize: Double
    var isBold: Bool
    var fontFamily: TextBlockFontFamily
    var fontWeight: TextBlockFontWeight
    var color: CanvasRGBAColor
    var alignment: TextBlockAlignment

    static let `default` = TextBlockPayload(
        text: "",
        fontSize: 15,
        isBold: false,
        fontFamily: .systemSans,
        fontWeight: .regular,
        color: .defaultText,
        alignment: .leading
    )

    private enum CodingKeys: String, CodingKey {
        case text
        case fontSize
        case isBold
        case fontFamily
        case fontWeight
        case color
        case alignment
    }

    init(
        text: String,
        fontSize: Double,
        isBold: Bool,
        fontFamily: TextBlockFontFamily = .systemSans,
        fontWeight: TextBlockFontWeight = .regular,
        color: CanvasRGBAColor,
        alignment: TextBlockAlignment
    ) {
        self.text = text
        self.fontSize = fontSize
        self.isBold = isBold
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.color = color
        self.alignment = alignment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedBold = try container.decodeIfPresent(Bool.self, forKey: .isBold) ?? false
        let decodedWeight = try container.decodeIfPresent(TextBlockFontWeight.self, forKey: .fontWeight)

        text = try container.decode(String.self, forKey: .text)
        fontSize = try container.decode(Double.self, forKey: .fontSize)
        isBold = decodedBold
        fontFamily = try container.decodeIfPresent(TextBlockFontFamily.self, forKey: .fontFamily) ?? .systemSans
        fontWeight = decodedWeight ?? (decodedBold ? .semibold : .regular)
        color = try container.decode(CanvasRGBAColor.self, forKey: .color)
        alignment = try container.decode(TextBlockAlignment.self, forKey: .alignment)
    }
}

enum TextBlockFontFamily: String, Codable, CaseIterable, Sendable {
    case systemSans
    case rounded
    case serif
    case monospaced

    var displayName: String {
        switch self {
        case .systemSans: return "System"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .monospaced: return "Mono"
        }
    }
}

enum TextBlockFontWeight: String, Codable, CaseIterable, Sendable {
    case regular
    case medium
    case semibold
    case bold
}

enum TextBlockAlignment: String, Codable, CaseIterable, Sendable {
    case leading
    case center
    case trailing
}

/// sRGB storage for stable JSON across appearances (separate from dynamic semantic colors).
struct CanvasRGBAColor: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    static let defaultText = CanvasRGBAColor(red: 0.12, green: 0.12, blue: 0.14, opacity: 1)

    init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    init(nsColor: NSColor) {
        let c = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

extension TextBlockAlignment {
    var multilineTextAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: return .topLeading
        case .center: return .top
        case .trailing: return .topTrailing
        }
    }
}

extension TextBlockPayload {
    var swiftUIFont: Font {
        switch fontFamily {
        case .systemSans:
            return .system(size: CGFloat(fontSize), weight: fontWeight.swiftUIFontWeight)
        case .rounded:
            return .system(size: CGFloat(fontSize), weight: fontWeight.swiftUIFontWeight, design: .rounded)
        case .serif:
            return .system(size: CGFloat(fontSize), weight: fontWeight.swiftUIFontWeight, design: .serif)
        case .monospaced:
            return .system(size: CGFloat(fontSize), weight: fontWeight.swiftUIFontWeight, design: .monospaced)
        }
    }
}

private extension TextBlockFontWeight {
    var swiftUIFontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

}
