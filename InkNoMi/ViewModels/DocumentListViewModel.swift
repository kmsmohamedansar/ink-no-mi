import Foundation
import Observation
import SwiftData

/// Sidebar + document CRUD. Uses `ModelContext` from the environment; keeps views thin.
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
        let title = ordinal == 1 ? "Untitled Canvas" : "Untitled Canvas \(ordinal)"
        var state = CanvasBoardState()
        state.boardTemplate = .blankBoard
        state.elements = []
        let payload = CanvasBoardCoding.encode(state)
        let doc = FlowDocument(title: title, canvasPayload: payload)
        modelContext.insert(doc)
        try? modelContext.save()
        return doc
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
