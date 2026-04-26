import CoreGraphics
import SwiftUI

enum StrokePathSmoothing {
    /// Builds a path for stroking using Catmull-Rom to Bezier interpolation.
    static func smoothPath(from points: [CGPoint]) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }
        if points.count == 1 {
            let p = points[0]
            path.addEllipse(in: CGRect(x: p.x - 0.5, y: p.y - 0.5, width: 1, height: 1))
            return path
        }

        path.move(to: points[0])
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        // Catmull-Rom spline converted into cubic Bezier segments.
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = (i + 2 < points.count) ? points[i + 2] : p2

            let c1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let c2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }

    /// Skip samples closer than `minDistance` (canvas points) to keep payloads smaller.
    static func decimatedCanvasPoints(_ raw: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard let first = raw.first else { return [] }
        var out: [CGPoint] = [first]
        var last = first
        for p in raw.dropFirst() {
            if hypot(p.x - last.x, p.y - last.y) >= minDistance {
                out.append(p)
                last = p
            }
        }
        if let end = raw.last, let o = out.last, hypot(o.x - end.x, o.y - end.y) > 0.25 {
            out.append(end)
        }
        return out
    }
}
