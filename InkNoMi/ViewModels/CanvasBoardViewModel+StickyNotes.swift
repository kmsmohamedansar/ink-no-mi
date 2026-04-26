import CoreGraphics
import Foundation
import SwiftUI

extension CanvasBoardViewModel {
    private static let stickyDefaultWidth: Double = 220
    private static let stickyDefaultHeight: Double = 200

    @discardableResult
    func insertStickyNote(
        selection: CanvasSelectionModel,
        beginEditing: Bool = true
    ) -> UUID {
        canvasTool = .select
        dismissCanvasContextPanel()
        let id = UUID()
        let parentShapeID = parentShapeForNewElement()
        var payload = StickyNotePayload.default
        payload.text = ""
        let origin = insertionOriginForNewElement(width: Self.stickyDefaultWidth, height: Self.stickyDefaultHeight)
        let constrainedOrigin = constrainRectToActiveContainer(
            CGRect(x: origin.x, y: origin.y, width: Self.stickyDefaultWidth, height: Self.stickyDefaultHeight)
        ).origin
        let record = CanvasElementRecord(
            id: id,
            kind: .stickyNote,
            x: constrainedOrigin.x,
            y: constrainedOrigin.y,
            width: Self.stickyDefaultWidth,
            height: Self.stickyDefaultHeight,
            zIndex: nextZIndex(),
            parentShapeID: parentShapeID,
            stickyNote: payload
        )

        applyBoardMutation { state in
            state.elements.append(record)
        }

        selection.selectOnly(id)
        if beginEditing {
            editingTextElementID = nil
            editingConnectorLabelElementID = nil
            editingStickyNoteElementID = id
        }
        return id
    }

    /// Click-to-place while `canvasTool == .stickyNote`; does not change the active tool.
    @discardableResult
    func insertStickyNoteAtCanvasPoint(
        _ point: CGPoint,
        selection: CanvasSelectionModel,
        beginEditing: Bool = true
    ) -> UUID {
        stopAllInlineEditing()
        let w = Self.stickyDefaultWidth
        let h = Self.stickyDefaultHeight
        let origin = CanvasInsertionPlacement.topLeftFromCenter(
            centerX: Double(point.x),
            centerY: Double(point.y),
            elementWidth: w,
            elementHeight: h,
            canvasLogicalSize: 4000
        )
        let id = UUID()
        let parentShapeID = parentShapeForNewElement()
        var payload = StickyNotePayload.default
        payload.text = ""
        let constrainedOrigin = constrainRectToActiveContainer(
            CGRect(x: origin.x, y: origin.y, width: w, height: h)
        ).origin
        let record = CanvasElementRecord(
            id: id,
            kind: .stickyNote,
            x: constrainedOrigin.x,
            y: constrainedOrigin.y,
            width: w,
            height: h,
            zIndex: nextZIndex(),
            parentShapeID: parentShapeID,
            stickyNote: payload
        )
        applyBoardMutation { state in
            state.elements.append(record)
        }
        selection.selectOnly(id)
        if beginEditing {
            editingTextElementID = nil
            editingConnectorLabelElementID = nil
            editingStickyNoteElementID = id
        }
        return id
    }

    /// Drag-to-define area while `canvasTool == .stickyNote`.
    @discardableResult
    func insertStickyNoteInCanvasRect(
        _ rect: CGRect,
        selection: CanvasSelectionModel,
        beginEditing: Bool = true
    ) -> UUID {
        stopAllInlineEditing()
        let std = rect.standardized
        let minW = Double(CanvasStickyNoteLayout.minWidth)
        let minH = Double(CanvasStickyNoteLayout.minHeight)
        let canvasMax: Double = 4000
        var x = Double(std.minX)
        var y = Double(std.minY)
        var w = Double(std.width)
        var h = Double(std.height)
        x = max(0, min(x, canvasMax - minW))
        y = max(0, min(y, canvasMax - minH))
        w = max(minW, min(w, canvasMax - x))
        h = max(minH, min(h, canvasMax - y))
        let id = UUID()
        let parentShapeID = parentShapeForNewElement()
        var payload = StickyNotePayload.default
        payload.text = ""
        let constrainedRect = constrainRectToActiveContainer(CGRect(x: x, y: y, width: w, height: h))
        let record = CanvasElementRecord(
            id: id,
            kind: .stickyNote,
            x: constrainedRect.minX,
            y: constrainedRect.minY,
            width: constrainedRect.width,
            height: constrainedRect.height,
            zIndex: nextZIndex(),
            parentShapeID: parentShapeID,
            stickyNote: payload
        )
        applyBoardMutation { state in
            state.elements.append(record)
        }
        selection.selectOnly(id)
        if beginEditing {
            editingTextElementID = nil
            editingConnectorLabelElementID = nil
            editingStickyNoteElementID = id
        }
        return id
    }

    func stopEditingStickyNote() {
        editingStickyNoteElementID = nil
    }

    /// Clears any inline editor (text block, sticky, or connector label).
    func stopAllInlineEditing() {
        editingTextElementID = nil
        editingStickyNoteElementID = nil
        editingConnectorLabelElementID = nil
    }

    func beginEditingStickyNote(id: UUID) {
        guard boardState.elements.contains(where: { $0.id == id && $0.kind == .stickyNote }) else { return }
        editingTextElementID = nil
        editingConnectorLabelElementID = nil
        editingStickyNoteElementID = id
    }

    func updateStickyNotePayload(id: UUID, _ body: (inout StickyNotePayload) -> Void) {
        updateElement(id: id) { element in
            guard element.kind == .stickyNote else { return }
            var payload = element.resolvedStickyNotePayload()
            body(&payload)
            element.stickyNote = payload
        }
    }

    func setStickyNoteFrame(id: UUID, x: Double, y: Double, width: Double, height: Double) {
        updateElement(id: id) { element in
            guard element.kind == .stickyNote else { return }
            element.x = x
            element.y = y
            element.width = max(width, CanvasStickyNoteLayout.minWidth)
            element.height = max(height, CanvasStickyNoteLayout.minHeight)
        }
    }

    func organizeSelectedStickyNotesAsTree(selection: CanvasSelectionModel) {
        let notes = boardState.elements
            .filter { selection.selectedElementIDs.contains($0.id) && $0.kind == .stickyNote }
            .sorted {
                if $0.y != $1.y { return $0.y < $1.y }
                return $0.x < $1.x
            }
        guard notes.count >= 2 else { return }
        let base = notes[0]
        let levelYStep: Double = 180
        let siblingXStep: Double = 260
        applyBoardMutation { state in
            for (index, note) in notes.enumerated() {
                guard let i = state.elements.firstIndex(where: { $0.id == note.id }) else { continue }
                let level = Int(floor(log2(Double(index + 1))))
                let rowStart = (1 << level) - 1
                let col = index - rowStart
                let itemsInRow = max(1, 1 << level)
                let rowWidth = Double(itemsInRow - 1) * siblingXStep
                let x = base.x + Double(col) * siblingXStep - rowWidth * 0.5
                let y = base.y + Double(level) * levelYStep
                state.elements[i].x = round(x / 8) * 8
                state.elements[i].y = round(y / 8) * 8
            }
        }
    }

    func organizeSelectedStickyNotesRadially(selection: CanvasSelectionModel) {
        let notes = boardState.elements
            .filter { selection.selectedElementIDs.contains($0.id) && $0.kind == .stickyNote }
            .sorted { $0.id.uuidString < $1.id.uuidString }
        guard notes.count >= 2 else { return }
        let anchor = notes[0]
        let center = CGPoint(x: anchor.x + anchor.width * 0.5, y: anchor.y + anchor.height * 0.5)
        let radius: Double = max(220, 90 + Double(notes.count) * 12)
        applyBoardMutation { state in
            for (index, note) in notes.enumerated() {
                guard let i = state.elements.firstIndex(where: { $0.id == note.id }) else { continue }
                if index == 0 {
                    state.elements[i].x = round((center.x - note.width * 0.5) / 8) * 8
                    state.elements[i].y = round((center.y - note.height * 0.5) / 8) * 8
                    continue
                }
                let t = Double(index - 1) / Double(max(1, notes.count - 1))
                let angle = (Double.pi * 2 * t) - Double.pi / 2
                let x = center.x + cos(angle) * radius - note.width * 0.5
                let y = center.y + sin(angle) * radius - note.height * 0.5
                state.elements[i].x = round(x / 8) * 8
                state.elements[i].y = round(y / 8) * 8
            }
        }
    }

    func clusterSelectedStickyNotes(selection: CanvasSelectionModel) {
        let notes = boardState.elements.filter { selection.selectedElementIDs.contains($0.id) && $0.kind == .stickyNote }
        guard notes.count >= 2 else { return }
        let anchor = notes.min(by: { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }) ?? notes[0]
        let centerX = anchor.x + anchor.width * 0.5
        let centerY = anchor.y + anchor.height * 0.5
        let columns = Int(ceil(sqrt(Double(notes.count))))
        let gapX: Double = 28
        let gapY: Double = 22
        applyBoardMutation { state in
            for (index, note) in notes.enumerated() {
                guard let i = state.elements.firstIndex(where: { $0.id == note.id }) else { continue }
                let row = index / columns
                let col = index % columns
                let x = centerX + Double(col) * (note.width + gapX) - Double(columns - 1) * (note.width + gapX) * 0.5 - note.width * 0.5
                let y = centerY + Double(row) * (note.height + gapY) - note.height * 0.5
                state.elements[i].x = round(x / 8) * 8
                state.elements[i].y = round(y / 8) * 8
            }
        }
    }
}

enum CanvasStickyNoteLayout {
    static let minWidth: Double = 100
    static let minHeight: Double = 80
    static let cornerRadius: CGFloat = FlowDeskLayout.cardCornerRadius
    static let contentPadding = FlowDeskLayout.canvasCardContentPadding
}
