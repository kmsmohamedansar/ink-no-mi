import Foundation

/// Primary canvas interaction mode (session UI only; not persisted on `CanvasBoardState`).
enum CanvasToolMode: String, Codable, Sendable, Hashable {
    case select
    case pen
    case pencil
    case text
    case stickyNote
    case shape
    case chart
    case smartInk

    var isPlacementMode: Bool {
        switch self {
        case .text, .stickyNote, .shape, .chart: return true
        case .select, .pen, .pencil, .smartInk: return false
        }
    }
}

/// Lightweight context UI beside the primary tool rail (progressive disclosure).
enum CanvasContextPanel: String, Equatable {
    case templates
    case shapes
    case drawStroke
}
