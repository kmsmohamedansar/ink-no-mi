import Foundation

// MARK: - Initial persisted state (centralized; JSON-only, backward compatible)
//
// User-facing creation uses `.smartCanvas` and `.blankBoard` only. Other cases stay for decode + older boards.

extension FlowDeskBoardTemplate {
    /// Full board snapshot for a new document from this template.
    func makeInitialCanvasState() -> CanvasBoardState {
        var state = CanvasBoardState()
        state.boardTemplate = self
        state.viewport = Self.viewport(for: self)
        state.elements = Self.elements(for: self)
        return state
    }

    /// Tool to activate when the editor opens this board. Session-only UI state lives in the view model, not JSON.
    var preferredInitialCanvasTool: CanvasToolMode {
        .select
    }

    private static func viewport(for template: FlowDeskBoardTemplate) -> ViewportState {
        switch template {
        case .document:
            // Slight zoom reads as a focused writing surface; grid off keeps noise low.
            return ViewportState(scale: 1.06, offsetX: 0, offsetY: 0, showGrid: false)
        case .whiteboard:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: true)
        case .smartCanvas:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: true)
        case .flowDiagram:
            // Pull back slightly so the starter diagram reads at a glance.
            return ViewportState(scale: 0.92, offsetX: 0, offsetY: 0, showGrid: true)
        case .blankBoard:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: false)
        }
    }

    private static func elements(for template: FlowDeskBoardTemplate) -> [CanvasElementRecord] {
        []
    }
}
