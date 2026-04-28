import SwiftUI

/// Bottom-trailing resize affordance (larger circular touch target).
struct CanvasTextBlockResizeHandle: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
            Circle()
                .strokeBorder(DS.Color.border.opacity(1.1), lineWidth: 0.8)
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(DS.Color.textSecondary.opacity(0.92))
        }
        .frame(width: 28, height: 28)
        .contentShape(Circle())
        .shadow(
            color: Color.black.opacity(FlowDeskTheme.canvasAuxiliaryLabelShadowOpacity * 0.48),
            radius: FlowDeskTheme.canvasAuxiliaryLabelShadowRadius * 0.88,
            x: 0,
            y: FlowDeskTheme.canvasAuxiliaryLabelShadowY
        )
    }
}
