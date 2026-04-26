import SwiftUI

/// Bottom-trailing resize affordance (macOS window–like).
struct CanvasTextBlockResizeHandle: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.thinMaterial)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(DS.Color.border.opacity(1.2), lineWidth: 0.8)
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(DS.Color.textSecondary.opacity(0.92))
        }
        .frame(width: 20, height: 20)
        .shadow(
            color: Color.black.opacity(FlowDeskTheme.canvasAuxiliaryLabelShadowOpacity * 0.48),
            radius: FlowDeskTheme.canvasAuxiliaryLabelShadowRadius * 0.88,
            x: 0,
            y: FlowDeskTheme.canvasAuxiliaryLabelShadowY
        )
    }
}
