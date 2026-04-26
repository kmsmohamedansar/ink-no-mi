import Foundation

extension CanvasBoardViewModel {
    /// Switches active canvas tool and closes floating context panels.
    func applyCanvasToolSelection(_ mode: CanvasToolMode, fromKeyboard: Bool, rectanglePlacementShape: Bool = false) {
        cancelConnectorDrag()
        cancelConnectorEndpointAdjust()
        stopAllInlineEditing()
        if mode == .shape, rectanglePlacementShape {
            placeShapeKind = .rectangle
        }
        canvasTool = mode
        canvasContextPanel = nil
    }
}
