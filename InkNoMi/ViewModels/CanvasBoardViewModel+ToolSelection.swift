import Foundation

extension CanvasBoardViewModel {
    /// Switches active canvas tool and closes floating context panels.
    func applyCanvasToolSelection(_ mode: CanvasToolMode, fromKeyboard: Bool, rectanglePlacementShape: Bool = false) {
        if mode == .smartInk {
            // Smart Ink is intentionally disabled for now; keep the canvas in a predictable manual workflow.
            return
        }
        cancelConnectorDrag()
        cancelConnectorEndpointAdjust()
        stopAllInlineEditing()
        if mode == .shape, rectanglePlacementShape {
            placeShapeKind = .rectangle
        }
        withAnimation(FlowDeskMotion.smoothEaseOut) {
            canvasTool = mode
        }
        canvasContextPanel = nil
    }
}
