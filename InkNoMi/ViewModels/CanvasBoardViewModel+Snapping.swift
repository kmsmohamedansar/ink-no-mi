import CoreGraphics
import Foundation
import SwiftUI

extension CanvasBoardViewModel {
    /// Clears alignment guides (call when drag/resize ends or context changes).
    func clearAlignmentGuides() {
        activeAlignmentGuides = []
    }

    func clearAlignmentGuides(after delay: TimeInterval) {
        _ = delay
        withAnimation(.easeOut(duration: 0.16)) {
            activeAlignmentGuides = []
        }
    }

    func updateAlignmentGuides(_ guides: [CanvasAlignmentGuide]) {
        activeAlignmentGuides = guides
    }

    func snapMoveFrame(
        rawOrigin: CGPoint,
        size: CGSize,
        excludingElementIds: Set<UUID>,
        movingElementId: UUID? = nil,
        enableSnapping: Bool = true
    ) -> (origin: CGPoint, guides: [CanvasAlignmentGuide]) {
        guard enableSnapping else {
            let clamped = CGPoint(
                x: max(0, min(rawOrigin.x, CanvasSnapEngine.defaultCanvasLogicalSize - size.width)),
                y: max(0, min(rawOrigin.y, CanvasSnapEngine.defaultCanvasLogicalSize - size.height))
            )
            return (clamped, [])
        }
        let proposed = CGRect(origin: rawOrigin, size: size)
        let (snapped, guides) = CanvasSnapEngine.snapMove(
            proposed: proposed,
            excludingElementIds: excludingElementIds,
            elements: boardState.elements,
            gridEnabled: boardState.viewport.showGrid,
            canvasSize: CanvasSnapEngine.defaultCanvasLogicalSize,
            threshold: CanvasSnapEngine.defaultThreshold
        )
        var r = CGRect(origin: snapped.origin, size: proposed.size)
        var merged = guides
        if let mid = movingElementId {
            let (rh, gh) = CanvasSnapEngine.refineEqualHorizontalMargins(
                rect: r,
                movingElementId: mid,
                excludingElementIds: excludingElementIds,
                elements: boardState.elements,
                canvasSize: CanvasSnapEngine.defaultCanvasLogicalSize,
                threshold: CanvasSnapEngine.defaultThreshold
            )
            r = rh
            for g in gh where !merged.contains(g) { merged.append(g) }
            let (rv, gv) = CanvasSnapEngine.refineEqualVerticalMargins(
                rect: r,
                movingElementId: mid,
                excludingElementIds: excludingElementIds,
                elements: boardState.elements,
                canvasSize: CanvasSnapEngine.defaultCanvasLogicalSize,
                threshold: CanvasSnapEngine.defaultThreshold
            )
            r = rv
            for g in gv where !merged.contains(g) { merged.append(g) }
        }
        return (r.origin, merged)
    }

    func snapResizeBottomRightFrame(
        origin: CGPoint,
        rawSize: CGSize,
        elementId: UUID,
        minWidth: CGFloat,
        minHeight: CGFloat,
        enableSnapping: Bool = true
    ) -> (size: CGSize, guides: [CanvasAlignmentGuide]) {
        guard enableSnapping else {
            let size = CGSize(
                width: max(minWidth, min(rawSize.width, CanvasSnapEngine.defaultCanvasLogicalSize - origin.x)),
                height: max(minHeight, min(rawSize.height, CanvasSnapEngine.defaultCanvasLogicalSize - origin.y))
            )
            return (size, [])
        }
        let proposed = CGRect(origin: origin, size: rawSize)
        let (snapped, guides) = CanvasSnapEngine.snapResizeBottomRight(
            proposed: proposed,
            resizingElementId: elementId,
            elements: boardState.elements,
            minWidth: minWidth,
            minHeight: minHeight,
            gridEnabled: boardState.viewport.showGrid,
            canvasSize: CanvasSnapEngine.defaultCanvasLogicalSize,
            threshold: CanvasSnapEngine.defaultThreshold
        )
        return (snapped.size, guides)
    }

    func snapPlacementDraftRect(
        rawRect: CGRect,
        minWidth: CGFloat,
        minHeight: CGFloat,
        enableSnapping: Bool = true
    ) -> (rect: CGRect, guides: [CanvasAlignmentGuide]) {
        guard enableSnapping else {
            return (rawRect.standardized, [])
        }
        return CanvasSnapEngine.snapPlacementDraft(
            proposed: rawRect,
            elements: boardState.elements,
            minWidth: minWidth,
            minHeight: minHeight,
            gridEnabled: boardState.viewport.showGrid,
            canvasSize: CanvasSnapEngine.defaultCanvasLogicalSize,
            threshold: CanvasSnapEngine.defaultThreshold
        )
    }
}
