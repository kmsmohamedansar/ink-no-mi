import SwiftUI

/// Renders a freehand stroke in **element-local** coordinates (origin top-left of element frame).
struct FreehandStrokeShapeView: View {
    let points: [StrokePathPoint]
    let color: CanvasRGBAColor
    let lineWidth: CGFloat
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            let cgPoints: [CGPoint] = points.map { CGPoint(x: $0.x, y: $0.y) }
            guard !cgPoints.isEmpty else { return }

            let sampled: [CGPoint] = {
                if cgPoints.count == 1 { return cgPoints }
                let perSeg = min(14, max(6, 2000 / max(cgPoints.count, 1)))
                let sp = StrokePathSmoothing.sampledSmoothPolyline(
                    from: cgPoints,
                    samplesPerSegment: perSeg
                )
                return sp.isEmpty ? cgPoints : sp
            }()

            InkStyleStrokeDrawing.drawInkStroke(
                context: &context,
                sampledPoints: sampled,
                color: color.swiftUIColor,
                baseLineWidth: lineWidth,
                baseOpacity: CGFloat(opacity)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
