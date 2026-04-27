#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only helper for App Store screenshot preparation.
@MainActor
struct ScreenshotModeService {
    enum Scene: String, CaseIterable, Identifiable {
        case homeTemplates
        case editorBrainstorm
        case flowchartBoard
        case kanbanBoard

        var id: String { rawValue }

        var title: String {
            switch self {
            case .homeTemplates: return "Home with Templates"
            case .editorBrainstorm: return "Editor - Brainstorm"
            case .flowchartBoard: return "Flowchart Board"
            case .kanbanBoard: return "Kanban Board"
            }
        }

        var preferredTemplateID: String? {
            switch self {
            case .homeTemplates: return nil
            case .editorBrainstorm: return "brainstorm-board"
            case .flowchartBoard: return "flowchart"
            case .kanbanBoard: return "kanban-board"
            }
        }
    }

    private static let demoTitles: Set<String> = [
        "Launch Brainstorm",
        "Mobile Onboarding Flow",
        "Product Sprint Kanban",
        "Template Gallery Starter"
    ]

    struct Result {
        let createdDocuments: [FlowDocument]
        let primaryDocument: FlowDocument?
        let appliedTheme: VisualTheme
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadDemoData(scene: Scene, appAppearance: AppearanceManager) -> Result {
        removeExistingDemoDocuments()

        let selectedTheme = recommendedTheme()
        var settings = appAppearance.settings
        settings.visualTheme = selectedTheme
        settings.appearanceMode = .light
        appAppearance.settings = settings

        let requestedBoards: [(title: String, templateID: String)] = [
            ("Launch Brainstorm", "brainstorm-board"),
            ("Mobile Onboarding Flow", "flowchart"),
            ("Product Sprint Kanban", "kanban-board"),
            ("Template Gallery Starter", "product-roadmap"),
        ]

        var created: [FlowDocument] = []
        for board in requestedBoards {
            guard let template = WorkspaceTemplate.gallery.first(where: { $0.id == board.templateID }) else { continue }
            let state = template.makeInitialCanvasState()
            let payload = CanvasBoardCoding.encode(state)
            let thumbnailData: Data?
            if let image = CanvasExportService.renderExportImage(boardState: state, renderScale: 1) {
                thumbnailData = CanvasExportService.pngData(from: image)
            } else {
                thumbnailData = nil
            }
            let document = FlowDocument(title: board.title, thumbnailData: thumbnailData, canvasPayload: payload)
            modelContext.insert(document)
            created.append(document)
        }
        try? modelContext.save()

        let preferredDocument = created.first(where: { doc in
            guard let preferredTemplateID = scene.preferredTemplateID else { return false }
            return documentTemplateID(for: doc) == preferredTemplateID
        })

        return Result(
            createdDocuments: created,
            primaryDocument: preferredDocument ?? created.first,
            appliedTheme: selectedTheme
        )
    }

    private func removeExistingDemoDocuments() {
        let descriptor = FetchDescriptor<FlowDocument>()
        guard let existing = try? modelContext.fetch(descriptor) else { return }
        for doc in existing where Self.demoTitles.contains(doc.title) {
            modelContext.delete(doc)
        }
        try? modelContext.save()
    }

    private func documentTemplateID(for document: FlowDocument) -> String {
        if let template = document.resolvedBoardTemplate {
            switch template {
            case .flowDiagram:
                return "flowchart"
            case .document:
                return "meeting-notes"
            case .whiteboard:
                return "brainstorm-board"
            case .smartCanvas, .blankBoard:
                break
            }
        }
        switch document.boardType {
        case .flowchart:
            return "flowchart"
        case .notes:
            return "meeting-notes"
        case .mindMap:
            return "mind-map"
        case .roadmap:
            return "product-roadmap"
        case .diagram:
            return "app-wireframe"
        case .whiteboard:
            return "brainstorm-board"
        }
    }

    private func recommendedTheme() -> VisualTheme {
        // Alternate to quickly get variety across screenshot sessions.
        Calendar.current.component(.second, from: .now).isMultiple(of: 2) ? .miroBright : .studioNeutral
    }
}
#endif
