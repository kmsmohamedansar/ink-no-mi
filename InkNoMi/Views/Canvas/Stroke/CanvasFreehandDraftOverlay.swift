import SwiftUI

/// Live preview while drawing in canvas space (absolute coordinates, full board size).
struct CanvasFreehandDraftOverlay: View {
    let canvasPoints: [CGPoint]
    let color: CanvasRGBAColor
    let lineWidth: CGFloat
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            let preview = StrokePathSmoothing.livePreviewPoints(canvasPoints)
            guard !preview.isEmpty else { return }

            let sampled: [CGPoint] = {
                if preview.count == 1 { return preview }
                return StrokePathSmoothing.sampledSmoothPolyline(from: preview, samplesPerSegment: 9)
            }()

            InkStyleStrokeDrawing.drawInkStroke(
                context: &context,
                sampledPoints: sampled,
                color: color.swiftUIColor,
                baseLineWidth: lineWidth,
                baseOpacity: CGFloat(opacity)
            )
        }
        .transaction { tx in
            tx.animation = nil
        }
        .allowsHitTesting(false)
    }
}
