import Foundation

/// How a board was first created. Persisted in `CanvasBoardState.boardTemplate` (JSON).
///
/// **Product:** Ink no Mi is a **smart canvas** app for solo thinking. Only ``smartCanvas`` and ``blankBoard`` appear in the
/// creation UI. Cases ``document``, ``whiteboard``, and ``flowDiagram`` remain for decoding existing data.
enum FlowDeskBoardTemplate: String, Codable, Sendable, CaseIterable, Identifiable {
    case document
    case whiteboard
    case smartCanvas
    case flowDiagram
    case blankBoard

    var id: String { rawValue }

    /// Templates offered on Home and as the default “new board” action (sidebar).
    static let creationFlowTemplates: [FlowDeskBoardTemplate] = [.smartCanvas, .blankBoard]

    /// Title for a new board; `ordinal` is 1-based count among all boards at creation time.
    func suggestedTitle(ordinal: Int) -> String {
        let n = max(1, ordinal)
        switch self {
        case .blankBoard:
            return n == 1 ? "Untitled Board" : "Untitled Board \(n)"
        case .smartCanvas:
            return n == 1 ? "Untitled Canvas" : "Untitled Canvas \(n)"
        case .document:
            return n == 1 ? "Untitled Document" : "Untitled Document \(n)"
        case .whiteboard:
            return n == 1 ? "Untitled Whiteboard" : "Untitled Whiteboard \(n)"
        case .flowDiagram:
            return n == 1 ? "Untitled Flow Diagram" : "Untitled Flow Diagram \(n)"
        }
    }
}

enum BoardType: String, CaseIterable, Codable, Sendable, Identifiable {
    case whiteboard
    case diagram
    case notes
    case mindMap
    case flowchart
    case roadmap
    case kanban

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whiteboard: return "Whiteboard"
        case .diagram: return "Diagram"
        case .notes: return "Notes"
        case .mindMap: return "Mind Map"
        case .flowchart: return "Flowchart"
        case .roadmap: return "Roadmap"
        case .kanban: return "Kanban"
        }
    }
}

struct WorkspaceTemplate: Identifiable, Hashable, Sendable {
    enum Category: String, CaseIterable, Identifiable, Sendable {
        case brainstorming
        case flowcharts
        case productPlanning
        case meetingNotes
        case mindMaps
        case dataCharts
        case studyNotes
        case roadmaps

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .brainstorming: return "Brainstorming"
            case .flowcharts: return "Flowcharts"
            case .productPlanning: return "Product Planning"
            case .meetingNotes: return "Meeting Notes"
            case .mindMaps: return "Mind Maps"
            case .dataCharts: return "Data / Charts"
            case .studyNotes: return "Study Notes"
            case .roadmaps: return "Roadmaps"
            }
        }
    }

    let id: String
    let title: String
    let description: String
    let category: Category
    let boardType: BoardType
    let icon: String
    let baseTemplate: FlowDeskBoardTemplate
    let isProTemplate: Bool
}

extension WorkspaceTemplate {
    static let gallery: [WorkspaceTemplate] = [
        .init(id: "brainstorm-board", title: "Brainstorm Board", description: "Quick note clusters for free ideation.", category: .brainstorming, boardType: .whiteboard, icon: "bolt", baseTemplate: .smartCanvas, isProTemplate: false),
        .init(id: "flowchart", title: "Flowchart", description: "Map process steps and decisions.", category: .flowcharts, boardType: .flowchart, icon: "point.3.connected.trianglepath.dotted", baseTemplate: .flowDiagram, isProTemplate: false),
        .init(id: "product-roadmap", title: "Product Roadmap", description: "Plan milestones and releases clearly.", category: .roadmaps, boardType: .roadmap, icon: "calendar", baseTemplate: .smartCanvas, isProTemplate: false),
        .init(id: "meeting-notes", title: "Meeting Notes", description: "Capture agenda, notes, and next actions.", category: .meetingNotes, boardType: .notes, icon: "note.text", baseTemplate: .document, isProTemplate: false),
        .init(id: "mind-map", title: "Mind Map", description: "Branch ideas into connected thought trees.", category: .mindMaps, boardType: .mindMap, icon: "circle.hexagongrid", baseTemplate: .smartCanvas, isProTemplate: true),
        .init(id: "kanban-board", title: "Kanban Board", description: "Track To Do, Doing, and Done lanes.", category: .productPlanning, boardType: .kanban, icon: "square.grid.3x1.folder.fill.badge.plus", baseTemplate: .smartCanvas, isProTemplate: true),
        .init(id: "app-wireframe", title: "App Wireframe", description: "Structure screens and interaction flow.", category: .productPlanning, boardType: .diagram, icon: "iphone.gen3", baseTemplate: .blankBoard, isProTemplate: true),
        .init(id: "swot-analysis", title: "SWOT Analysis", description: "Map strengths, weaknesses, opportunities, and threats.", category: .productPlanning, boardType: .diagram, icon: "square.grid.2x2", baseTemplate: .smartCanvas, isProTemplate: true),
    ]
}
