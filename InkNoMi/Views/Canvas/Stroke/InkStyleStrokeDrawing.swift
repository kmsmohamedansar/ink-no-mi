import SwiftUI

/// Variable-width ink pass: tapers stroke ends and applies a light opacity rhythm (pen / pencil preview + committed).
enum InkStyleStrokeDrawing {

    /// Renders along a **polyline** (typically from `StrokePathSmoothing.sampledSmoothPolyline`).
    static func drawInkStroke(
        context: inout GraphicsContext,
        sampledPoints: [CGPoint],
        color: Color,
        baseLineWidth: CGFloat,
        baseOpacity: CGFloat
    ) {
        guard baseLineWidth > 0, baseOpacity > 0 else { return }

        if sampledPoints.count == 1, let p = sampledPoints.first {
            let r = max(1, baseLineWidth * 0.46)
            let dot = Circle().path(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
            context.fill(dot, with: .color(color.opacity(Double(baseOpacity))))
            return
        }

        guard sampledPoints.count >= 2 else { return }

        let lengths = cumulativeLengths(sampledPoints)
        let totalArc = max(lengths.last ?? 1, 0.0001)
        let segCount = sampledPoints.count - 1
        let shortStroke = segCount < 14

        for i in 0..<segCount {
            let a = sampledPoints[i]
            let b = sampledPoints[i + 1]
            let len = hypot(b.x - a.x, b.y - a.y)
            if len < 0.008 { continue }

            let tMid = ((lengths[i] + lengths[i + 1]) * 0.5) / totalArc
            let widthMul = inkWidthMultiplier(arcParameter: tMid, isShortStroke: shortStroke)
            let opacityMul = inkOpacityMultiplier(segmentIndex: i, segmentCount: segCount)

            var segment = Path()
            segment.move(to: a)
            segment.addLine(to: b)

            let w = baseLineWidth * widthMul
            let o = Double(baseOpacity * opacityMul)

            context.stroke(
                segment,
                with: .color(color.opacity(o)),
                style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private static func cumulativeLengths(_ points: [CGPoint]) -> [CGFloat] {
        var out: [CGFloat] = [0]
        for i in 1..<points.count {
            let d = hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
            out.append(out[i - 1] + d)
        }
        return out
    }

    /// Dual-ended taper using arc-length parameter in `[0, 1]`.
    private static func inkWidthMultiplier(arcParameter t: CGFloat, isShortStroke: Bool) -> CGFloat {
        let taperFrac: CGFloat = isShortStroke ? 0.22 : 0.11
        let tipFloor: CGFloat = isShortStroke ? 0.48 : 0.34

        let left = tipFloor + (1 - tipFloor) * smoothstep(0, taperFrac, t)
        let right = tipFloor + (1 - tipFloor) * smoothstep(0, taperFrac, 1 - t)
        return left * right
    }

    /// Very subtle deterministic variation so strokes feel organic, not flat vector lines.
    private static func inkOpacityMultiplier(segmentIndex: Int, segmentCount: Int) -> CGFloat {
        guard segmentCount > 0 else { return 1 }
        let i = Double(segmentIndex)
        let n = Double(segmentCount)
        let wave = 0.055 * sin(i * 0.85 + n * 0.19) + 0.035 * sin(i * 2.11 - 0.4)
        return CGFloat(1 + wave).clamped(to: 0.91...1.07)
    }

    private static func smoothstep(_ a: CGFloat, _ b: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = min(max((x - a) / max(b - a, 0.0001), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
