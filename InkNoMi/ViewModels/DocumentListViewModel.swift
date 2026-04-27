import Foundation
import Observation
import SwiftData

/// Sidebar + document CRUD. Uses `ModelContext` from the environment; keeps views thin.
@MainActor
@Observable
final class DocumentListViewModel {
    private var modelContext: ModelContext?
    var boardCreationRequiresPro = false

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createUntitledBoard(isProUser: Bool) -> FlowDocument? {
        createBoard(from: .blankBoard, isProUser: isProUser)
    }

    /// Creates a board from a home-screen template with encoded initial canvas + template metadata.
    func createBoard(from template: FlowDeskBoardTemplate, isProUser: Bool) -> FlowDocument? {
        createBoard(from: template, customTitle: nil, isProUser: isProUser)
    }

    /// Creates a board from a base template and optional explicit title.
    func createBoard(
        from template: FlowDeskBoardTemplate,
        customTitle: String?,
        isProUser: Bool
    ) -> FlowDocument? {
        guard let modelContext else { return nil }
        guard let existingCount = canCreateBoard(isProUser: isProUser, modelContext: modelContext) else {
            return nil
        }
        let ordinal = existingCount + 1
        let title = resolvedTitle(customTitle, fallback: template.suggestedTitle(ordinal: ordinal))
        let state = template.makeInitialCanvasState()
        return persistBoard(title: title, state: state, modelContext: modelContext)
    }

    /// Creates a board from a workspace template card with template-specific seeded elements.
    func createBoard(from workspaceTemplate: WorkspaceTemplate, isProUser: Bool) -> FlowDocument? {
        createBoard(from: workspaceTemplate, customTitle: nil, isProUser: isProUser)
    }

    /// Creates a board from a workspace template and optional explicit title.
    func createBoard(
        from workspaceTemplate: WorkspaceTemplate,
        customTitle: String?,
        isProUser: Bool
    ) -> FlowDocument? {
        guard let modelContext else { return nil }
        guard let existingCount = canCreateBoard(isProUser: isProUser, modelContext: modelContext) else {
            return nil
        }
        let ordinal = existingCount + 1
        let title = resolvedTitle(customTitle, fallback: workspaceTemplate.baseTemplate.suggestedTitle(ordinal: ordinal))
        let state = workspaceTemplate.makeInitialCanvasState()
        return persistBoard(title: title, state: state, modelContext: modelContext)
    }

    func duplicate(_ document: FlowDocument, isProUser: Bool) -> FlowDocument? {
        guard let modelContext else { return nil }
        boardCreationRequiresPro = false
        let descriptor = FetchDescriptor<FlowDocument>()
        let count = (try? modelContext.fetch(descriptor).count) ?? 0
        if !isProUser, count >= PurchaseManager.freeBoardLimit {
            boardCreationRequiresPro = true
            return nil
        }
        let dup = FlowDocument(
            title: "\(document.title) Copy",
            thumbnailData: document.thumbnailData,
            canvasPayload: document.canvasPayload
        )
        if dup.thumbnailData == nil {
            let state = CanvasBoardCoding.decode(from: dup.canvasPayload)
            dup.thumbnailData = makeThumbnailData(for: state)
        }
        modelContext.insert(dup)
        try? modelContext.save()
        return dup
    }

    func delete(_ document: FlowDocument) {
        guard let modelContext else { return }
        modelContext.delete(document)
        try? modelContext.save()
    }

    func rename(_ document: FlowDocument, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        document.title = trimmed
        document.markUpdated()
        try? modelContext?.save()
    }

    func toggleFavorite(_ document: FlowDocument) {
        document.isFavorite.toggle()
        document.markUpdated()
        try? modelContext?.save()
    }

    private func canCreateBoard(isProUser: Bool, modelContext: ModelContext) -> Int? {
        boardCreationRequiresPro = false
        let descriptor = FetchDescriptor<FlowDocument>()
        let count = (try? modelContext.fetch(descriptor).count) ?? 0
        if !isProUser, count >= PurchaseManager.freeBoardLimit {
            boardCreationRequiresPro = true
            return nil
        }
        return count
    }

    private func resolvedTitle(_ customTitle: String?, fallback: String) -> String {
        let trimmed = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func persistBoard(title: String, state: CanvasBoardState, modelContext: ModelContext) -> FlowDocument {
        let payload = CanvasBoardCoding.encode(state)
        let doc = FlowDocument(
            title: title,
            thumbnailData: makeThumbnailData(for: state),
            canvasPayload: payload
        )
        modelContext.insert(doc)
        try? modelContext.save()
        return doc
    }

    private func makeThumbnailData(for state: CanvasBoardState) -> Data? {
        guard let image = CanvasExportService.renderExportImage(boardState: state, renderScale: 1) else {
            return nil
        }
        return CanvasExportService.pngData(from: image)
    }
}
