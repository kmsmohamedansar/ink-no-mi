import SwiftUI

/// Unified group-selection container for multi-selected framed elements (canvas coordinates).
struct CanvasMultiSelectionBoundsOverlay: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    let elements: [CanvasElementRecord]
    let selectedIDs: Set<UUID>

    private var unionRect: CGRect? {
        let framed = elements.filter {
            selectedIDs.contains($0.id) && CanvasSnapEngine.participatesInSnapping($0.kind)
        }
        guard framed.count > 1 else { return nil }
        var r = CGRect(
            x: CGFloat(framed[0].x),
            y: CGFloat(framed[0].y),
            width: CGFloat(framed[0].width),
            height: CGFloat(framed[0].height)
        )
        for el in framed.dropFirst() {
            r = r.union(
                CGRect(x: CGFloat(el.x), y: CGFloat(el.y), width: CGFloat(el.width), height: CGFloat(el.height))
            )
        }
        return r
    }

    var body: some View {
        if let rect = unionRect {
            let cornerRadius: CGFloat = 14
            let shadowOpacity = colorScheme == .dark ? 0.24 : 0.11
            let glowOpacity = colorScheme == .dark ? 0.28 : 0.2

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
                .frame(width: rect.width + 10, height: rect.height + 10)
                .position(x: rect.midX, y: rect.midY)
                .shadow(color: Color.black.opacity(shadowOpacity), radius: 20, x: 0, y: 10)
                .shadow(color: tokens.selectionStrokeColor.opacity(glowOpacity), radius: 22, x: 0, y: 0)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            tokens.selectionStrokeColor.opacity(0.84),
                            style: StrokeStyle(lineWidth: 1.35, dash: [8, 5])
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(tokens.selectionStrokeColor.opacity(0.2), lineWidth: 9)
                        .blur(radius: 9)
                }
                .allowsHitTesting(false)
        } else {
            EmptyView()
        }
    }
}
