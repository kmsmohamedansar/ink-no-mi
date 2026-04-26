import SwiftUI

/// Live preview while drawing in canvas space (absolute coordinates, full board size).
struct CanvasFreehandDraftOverlay: View {
    let canvasPoints: [CGPoint]
    let color: CanvasRGBAColor
    let lineWidth: CGFloat
    let opacity: Double

    var body: some View {
        let previewPoints = StrokePathSmoothing.livePreviewPoints(canvasPoints)
        let path = StrokePathSmoothing.smoothPath(from: previewPoints)
        path
            .stroke(
                color.swiftUIColor.opacity(opacity),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            .transaction { tx in
                // Keep in-flight drawing updates immediate; avoid per-point animation churn.
                tx.animation = nil
            }
            .allowsHitTesting(false)
    }
}
