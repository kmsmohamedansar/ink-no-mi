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

    /// Fast live pass for in-progress feedback while drawing.
    static func livePreviewPoints(_ raw: [CGPoint]) -> [CGPoint] {
        let filtered = filterJitter(raw, epsilon: 0.45)
        let decimated = decimatedCanvasPoints(filtered, minDistance: 1.2)
        return movingAverageSmooth(decimated, passes: 1, windowRadius: 1)
    }

    /// Slightly more refined pass after stroke commit.
    static func finalizedStrokePoints(_ raw: [CGPoint]) -> [CGPoint] {
        let filtered = filterJitter(raw, epsilon: 0.55)
        let decimated = decimatedCanvasPoints(filtered, minDistance: 1.6)
        let passes = decimated.count > 800 ? 1 : 2
        let smoothed = movingAverageSmooth(decimated, passes: passes, windowRadius: 2)
        return decimatedCanvasPoints(smoothed, minDistance: 1.8)
    }

    private static func filterJitter(_ raw: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard let first = raw.first else { return [] }
        var out: [CGPoint] = [first]
        for p in raw.dropFirst() {
            if let last = out.last, hypot(p.x - last.x, p.y - last.y) < epsilon {
                continue
            }
            out.append(p)
        }
        if let end = raw.last, let tail = out.last, hypot(tail.x - end.x, tail.y - end.y) > 0.2 {
            out.append(end)
        }
        return out
    }

    private static func movingAverageSmooth(_ points: [CGPoint], passes: Int, windowRadius: Int) -> [CGPoint] {
        guard points.count >= 4, passes > 0, windowRadius > 0 else { return points }
        var current = points
        let n = points.count
        for _ in 0..<passes {
            var next = current
            for i in 1..<(n - 1) {
                let lo = max(0, i - windowRadius)
                let hi = min(n - 1, i + windowRadius)
                let count = CGFloat(hi - lo + 1)
                guard count > 0 else { continue }
                var sx: CGFloat = 0
                var sy: CGFloat = 0
                for j in lo...hi {
                    sx += current[j].x
                    sy += current[j].y
                }
                next[i] = CGPoint(x: sx / count, y: sy / count)
            }
            current = next
        }
        return current
    }
}
