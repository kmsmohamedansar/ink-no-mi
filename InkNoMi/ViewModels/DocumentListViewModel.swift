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
        guard let modelContext else { return nil }
        boardCreationRequiresPro = false
        let descriptor = FetchDescriptor<FlowDocument>()
        let count = (try? modelContext.fetch(descriptor).count) ?? 0
        if !isProUser, count >= PurchaseManager.freeBoardLimit {
            boardCreationRequiresPro = true
            return nil
        }
        let ordinal = count + 1
        let title = template.suggestedTitle(ordinal: ordinal)
        let state = template.makeInitialCanvasState()
        let payload = CanvasBoardCoding.encode(state)
        let doc = FlowDocument(title: title, canvasPayload: payload)
        modelContext.insert(doc)
        try? modelContext.save()
        return doc
    }

    /// Creates a board from a workspace template card with template-specific seeded elements.
    func createBoard(from workspaceTemplate: WorkspaceTemplate, isProUser: Bool) -> FlowDocument? {
        guard let modelContext else { return nil }
        boardCreationRequiresPro = false
        let descriptor = FetchDescriptor<FlowDocument>()
        let count = (try? modelContext.fetch(descriptor).count) ?? 0
        if !isProUser, count >= PurchaseManager.freeBoardLimit {
            boardCreationRequiresPro = true
            return nil
        }
        let ordinal = count + 1
        let title = workspaceTemplate.baseTemplate.suggestedTitle(ordinal: ordinal)
        let state = workspaceTemplate.makeInitialCanvasState()
        let payload = CanvasBoardCoding.encode(state)
        let doc = FlowDocument(title: title, canvasPayload: payload)
        modelContext.insert(doc)
        try? modelContext.save()
        return doc
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
            canvasPayload: document.canvasPayload
        )
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
}
