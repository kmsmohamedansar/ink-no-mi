import Foundation
import Observation
import SwiftData

/// In-memory canvas state for the selected document. Persists back to `FlowDocument.canvasPayload`
/// on meaningful changes (viewport, elements, text payloads).
@MainActor
@Observable
final class CanvasBoardViewModel {
    enum SaveStatus: Equatable {
        case saving(lastSavedAt: Date?)
        case saved(lastSavedAt: Date?)
        case localOnly(lastSavedAt: Date?)
    }

    private struct RecoverySnapshot: Codable {
        let payload: Data
        let capturedAt: Date
    }

    private weak var document: FlowDocument?
    private var modelContext: ModelContext?
    private var autosaveTask: Task<Void, Never>?
    private var thumbnailTask: Task<Void, Never>?
    private var queuedThumbnailPayloadHash: Int?
    private var hasDirtyChanges = false
    private let autosaveDebounceNanoseconds: UInt64 = 700_000_000
    private let thumbnailDebounceNanoseconds: UInt64 = 450_000_000

    private(set) var boardState: CanvasBoardState = .empty()
    private(set) var saveStatus: SaveStatus = .saved(lastSavedAt: nil)
    private(set) var lastSavedAt: Date?
    private(set) var saveErrorBannerVisible = false

    /// When set, the canvas shows an inline editor for this text block id.
    var editingTextElementID: UUID?
    /// When set, the canvas shows an inline editor for this sticky note id.
    var editingStickyNoteElementID: UUID?
    /// When set, shows a one-line label field on this connector id.
    var editingConnectorLabelElementID: UUID?

    /// Active canvas tool mode.
    var canvasTool: CanvasToolMode = .select
    /// Active shape container while user is drawing/typing inside a selected shape.
    var activeContainerShapeID: UUID?
    /// Transition flags used for conversion animations.
    var convertingStrokeIDs: Set<UUID> = []
    var convertingShapeIDs: Set<UUID> = []
    var convertingTextIDs: Set<UUID> = []

    /// Optional context panel beside the tool rail; currently unused by default.
    var canvasContextPanel: CanvasContextPanel?

    /// Shape kind used when `canvasTool == .shape` (click or drag on the canvas).
    var placeShapeKind: FlowDeskShapeKind = .rectangle

    /// Active drawing style for new strokes (toolbar / inspector).
    var drawingStrokeColor: CanvasRGBAColor = CanvasRGBAColor(red: 0.12, green: 0.12, blue: 0.14, opacity: 1)
    var drawingLineWidth: Double = 3
    var drawingStrokeOpacity: Double = 1
    /// Updated by `CanvasBoardView` from the visible geometry + current pan/zoom (not persisted).
    var insertionViewportSnapshot: CanvasInsertionViewportSnapshot?
    /// Increments on each insert for a slight cascade offset (resets per document session).
    var insertionStaggerCounter: Int = 0

    /// Live alignment guides during move/resize (not persisted).
    var activeAlignmentGuides: [CanvasAlignmentGuide] = []

    /// Multi-select framed drag: leader view drives snap; followers mirror `groupMovePreviewTranslation`.
    var groupMoveLeaderID: UUID?
    var groupMovePreviewTranslation: CGSize = .zero
    /// Same as the leader’s live drag delta while a framed group move is active (connectors use this; cleared in `resetGroupMoveState`).
    var groupMoveLiveCanvasTranslation: CGSize = .zero
    /// Subset of `selectedElementIDs` that are framed (text, sticky, shape, chart).
    var groupMoveParticipantIDs: Set<UUID> = []

    /// ⌥-drag duplicate: gesture started on source id; live frame updates target id (the copy).
    var optionDuplicateSourceElementID: UUID?
    var optionDuplicateTargetElementID: UUID?
    var optionDuplicateUndoCoalescingActive = false

    /// In-progress connector from a shape edge (not persisted until completed).
    var connectorDragDraft: ConnectorDragDraft?

    /// Dragging a connector endpoint to reconnect (not persisted until completed).
    var connectorEndpointAdjustDraft: ConnectorEndpointAdjustDraft?

    /// Cascading offset steps for repeated paste from the internal clipboard (canvas points). Reset on copy and document attach/detach.
    var clipboardPasteGeneration: Int = 0

    /// Bumped when the internal canvas pasteboard write succeeds so SwiftUI refreshes Paste affordances.
    var clipboardRevision: Int = 0

    /// Shared offset for duplicate, multi-duplicate, and clipboard paste (canvas space, points).
    static let boardCascadeOffset: Double = 28

    // MARK: - Undo / redo (snapshot-based; see CanvasBoardViewModel+Undo.swift)

    /// States to restore on Undo. Not persisted across app relaunch or document switches.
    var canvasUndoStack: [CanvasBoardState] = []
    var canvasRedoStack: [CanvasBoardState] = []
    var canvasUndoApplying = false
    /// Nesting depth for coalescing rapid mutations (e.g. live resize) into one undo step.
    var canvasUndoCoalescingDepth = 0
    /// Baseline board snapshot when the outermost coalescing session started; consumed after first recorded change.
    var canvasUndoCoalesceBaseline: CanvasBoardState?
    private(set) var canUndoBoard = false
    private(set) var canRedoBoard = false
    let canvasUndoStackLimit = 100

    func attach(document: FlowDocument, modelContext: ModelContext) {
        self.document = document
        self.modelContext = modelContext
        autosaveTask?.cancel()
        autosaveTask = nil
        thumbnailTask?.cancel()
        thumbnailTask = nil
        queuedThumbnailPayloadHash = nil
        hasDirtyChanges = false
        lastSavedAt = document.updatedAt
        saveErrorBannerVisible = false
        editingTextElementID = nil
        editingStickyNoteElementID = nil
        editingConnectorLabelElementID = nil
        canvasTool = .select
        activeContainerShapeID = nil
        convertingStrokeIDs = []
        convertingShapeIDs = []
        convertingTextIDs = []
        canvasContextPanel = nil
        insertionViewportSnapshot = nil
        insertionStaggerCounter = 0
        clipboardPasteGeneration = 0
        activeAlignmentGuides = []
        resetGroupMoveState()
        optionDuplicateUndoCoalescingActive = false
        optionDuplicateSourceElementID = nil
        optionDuplicateTargetElementID = nil
        connectorDragDraft = nil
        connectorEndpointAdjustDraft = nil
        placeShapeKind = .rectangle
        boardState = CanvasBoardCoding.decode(from: document.canvasPayload)
        restoreUnsavedRecoveryIfNeeded(from: document)
        // Initial tool is session UI state and always starts in select for a predictable blank-first canvas.
        canvasTool = boardState.boardTemplate?.preferredInitialCanvasTool ?? .select
        canvasContextPanel = nil
        resetCanvasUndoHistory()
        saveStatus = hasDirtyChanges ? .saving(lastSavedAt: lastSavedAt) : .saved(lastSavedAt: lastSavedAt)
        if document.thumbnailData == nil {
            scheduleThumbnailRefresh(payload: document.canvasPayload, snapshot: boardState)
        }
    }

    /// Closes the progressive rail panel when focus returns to the canvas (e.g. View-menu inserts).
    func dismissCanvasContextPanel() {
        canvasContextPanel = nil
    }

    func detach() {
        autosaveTask?.cancel()
        autosaveTask = nil
        thumbnailTask?.cancel()
        thumbnailTask = nil
        queuedThumbnailPayloadHash = nil
        hasDirtyChanges = false
        document = nil
        modelContext = nil
        editingTextElementID = nil
        editingStickyNoteElementID = nil
        editingConnectorLabelElementID = nil
        canvasTool = .select
        activeContainerShapeID = nil
        convertingStrokeIDs = []
        convertingShapeIDs = []
        convertingTextIDs = []
        canvasContextPanel = nil
        insertionViewportSnapshot = nil
        insertionStaggerCounter = 0
        clipboardPasteGeneration = 0
        activeAlignmentGuides = []
        resetGroupMoveState()
        optionDuplicateUndoCoalescingActive = false
        optionDuplicateSourceElementID = nil
        optionDuplicateTargetElementID = nil
        connectorDragDraft = nil
        connectorEndpointAdjustDraft = nil
        placeShapeKind = .rectangle
        boardState = .empty()
        resetCanvasUndoHistory()
        saveStatus = .saved(lastSavedAt: nil)
        lastSavedAt = nil
        saveErrorBannerVisible = false
    }

    func persist() {
        markBoardDirty()
    }

    func dismissSaveErrorBanner() {
        saveErrorBannerVisible = false
    }

    private func markBoardDirty() {
        guard document != nil, modelContext != nil else { return }
        hasDirtyChanges = true
        saveStatus = .saving(lastSavedAt: lastSavedAt)
        writeRecoverySnapshot()
        scheduleAutosave()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: autosaveDebounceNanoseconds)
            } catch {
                return
            }
            await self?.performAutosaveIfNeeded()
        }
    }

    private func performAutosaveIfNeeded() async {
        guard hasDirtyChanges else { return }
        guard document != nil, modelContext != nil else { return }
        do {
            try persistNow()
            hasDirtyChanges = false
            saveErrorBannerVisible = false
            clearRecoverySnapshot()
            saveStatus = .saved(lastSavedAt: lastSavedAt)
        } catch {
            // Keep unsaved recovery payload so data can be restored on next launch.
            saveErrorBannerVisible = true
            saveStatus = .localOnly(lastSavedAt: lastSavedAt)
            scheduleAutosave()
        }
    }

    private func persistNow() throws {
        guard let document, let modelContext else { return }
        let payload = CanvasBoardCoding.encode(boardState)
        document.canvasPayload = payload
        document.markUpdated()
        try modelContext.save()
        lastSavedAt = document.updatedAt
        scheduleThumbnailRefresh(payload: payload, snapshot: boardState)
    }

    private func scheduleThumbnailRefresh(payload: Data, snapshot: CanvasBoardState) {
        let payloadHash = payload.hashValue
        if queuedThumbnailPayloadHash == payloadHash {
            return
        }
        queuedThumbnailPayloadHash = payloadHash
        thumbnailTask?.cancel()
        thumbnailTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: thumbnailDebounceNanoseconds)
            } catch {
                return
            }
            await self?.writeThumbnailIfNeeded(for: snapshot, payloadHash: payloadHash)
        }
    }

    private func writeThumbnailIfNeeded(for snapshot: CanvasBoardState, payloadHash: Int) async {
        guard let document, let modelContext else { return }
        guard queuedThumbnailPayloadHash == payloadHash else { return }
        guard let rendered = CanvasExportService.renderExportImage(boardState: snapshot, renderScale: 1),
              let pngData = CanvasExportService.pngData(from: rendered)
        else {
            queuedThumbnailPayloadHash = nil
            return
        }
        if document.thumbnailData != pngData {
            document.thumbnailData = pngData
            try? modelContext.save()
        }
        queuedThumbnailPayloadHash = nil
    }

    private var recoverySnapshotKey: String? {
        guard let document else { return nil }
        return "inknomi.canvas.recovery.\(document.id.uuidString)"
    }

    private func writeRecoverySnapshot() {
        guard let key = recoverySnapshotKey else { return }
        let snapshot = RecoverySnapshot(payload: CanvasBoardCoding.encode(boardState), capturedAt: .now)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func clearRecoverySnapshot() {
        guard let key = recoverySnapshotKey else { return }
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func restoreUnsavedRecoveryIfNeeded(from document: FlowDocument) {
        guard let key = recoverySnapshotKey else { return }
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        guard let snapshot = try? JSONDecoder().decode(RecoverySnapshot.self, from: data) else { return }
        guard snapshot.payload != document.canvasPayload else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        boardState = CanvasBoardCoding.decode(from: snapshot.payload)
        hasDirtyChanges = true
        saveStatus = .saving(lastSavedAt: lastSavedAt)
        scheduleAutosave()
    }

    // MARK: - Undo helpers (mutation entry points for `CanvasBoardViewModel+Undo`)

    func mutateBoardState(_ body: (inout CanvasBoardState) -> Void) {
        body(&boardState)
    }

    func replaceEntireBoardState(_ state: CanvasBoardState) {
        boardState = state
    }

    func refreshBoardUndoAvailability() {
        canUndoBoard = !canvasUndoStack.isEmpty
        canRedoBoard = !canvasRedoStack.isEmpty
    }
}

extension CanvasBoardViewModel {
    func setActiveContainer(shapeID: UUID?) {
        guard let shapeID else {
            activeContainerShapeID = nil
            return
        }
        guard boardState.elements.contains(where: { $0.id == shapeID && $0.kind == .shape }) else {
            activeContainerShapeID = nil
            return
        }
        activeContainerShapeID = shapeID
    }

    func activeContainerRect() -> CGRect? {
        guard let id = activeContainerShapeID,
              let shape = boardState.elements.first(where: { $0.id == id && $0.kind == .shape }) else {
            return nil
        }
        return CGRect(x: shape.x, y: shape.y, width: shape.width, height: shape.height).standardized
    }

    func parentShapeForNewElement() -> UUID? {
        guard let rect = activeContainerRect(), rect.width > 0, rect.height > 0 else { return nil }
        return activeContainerShapeID
    }

    func constrainPointToActiveContainer(_ point: CGPoint) -> CGPoint {
        guard let rect = activeContainerRect() else { return point }
        return CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }

    func constrainRectToActiveContainer(_ rect: CGRect) -> CGRect {
        guard let container = activeContainerRect() else { return rect }
        var r = rect.standardized
        if r.minX < container.minX { r.origin.x = container.minX }
        if r.minY < container.minY { r.origin.y = container.minY }
        if r.maxX > container.maxX { r.origin.x = max(container.minX, container.maxX - r.width) }
        if r.maxY > container.maxY { r.origin.y = max(container.minY, container.maxY - r.height) }
        r.size.width = min(r.width, container.width)
        r.size.height = min(r.height, container.height)
        return r
    }

    func beginStrokeConversion(for ids: [UUID]) {
        convertingStrokeIDs.formUnion(ids)
    }

    func endStrokeConversion(for ids: [UUID]) {
        ids.forEach { convertingStrokeIDs.remove($0) }
    }

    func beginShapeConversion(for id: UUID) {
        convertingShapeIDs.insert(id)
    }

    func endShapeConversion(for id: UUID) {
        convertingShapeIDs.remove(id)
    }

    func beginTextConversion(for id: UUID) {
        convertingTextIDs.insert(id)
    }

    func endTextConversion(for id: UUID) {
        convertingTextIDs.remove(id)
    }

}

/// Canonical canvas view model surface for new canvas systems.
typealias CanvasViewModel = CanvasBoardViewModel
