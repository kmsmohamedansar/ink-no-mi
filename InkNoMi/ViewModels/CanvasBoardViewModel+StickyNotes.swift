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
}

enum CanvasStickyNoteLayout {
    static let minWidth: Double = 100
    static let minHeight: Double = 80
    static let cornerRadius: CGFloat = FlowDeskLayout.cardCornerRadius
    static let contentPadding = FlowDeskLayout.canvasCardContentPadding
}
