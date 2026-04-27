import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Canvas shortcuts: edit commands, single-key tools, and ⌘⌥1–3 viewport framing.
struct CanvasScreenKeyCommands: ViewModifier {
    var boardViewModel: CanvasBoardViewModel
    var selection: CanvasSelectionModel
    var isFocusModeEnabled: Bool

    func body(content: Content) -> some View {
        content
            .onKeyPress(.escape) {
                if isFocusModeEnabled {
                    NotificationCenter.default.post(name: .flowDeskExitFocusMode, object: nil)
                    return .handled
                }
                if boardViewModel.editingConnectorLabelElementID != nil {
                    boardViewModel.stopEditingConnectorLabel()
                    return .handled
                }
                if boardViewModel.connectorEndpointAdjustDraft != nil {
                    boardViewModel.cancelConnectorEndpointAdjust()
                    return .handled
                }
                if boardViewModel.connectorDragDraft != nil {
                    boardViewModel.cancelConnectorDrag()
                    return .handled
                }
                if boardViewModel.canvasTool != .select {
                    boardViewModel.applyCanvasToolSelection(.select, fromKeyboard: true)
                    boardViewModel.setActiveContainer(shapeID: nil)
                    return .handled
                }
                if boardViewModel.activeContainerShapeID != nil {
                    boardViewModel.setActiveContainer(shapeID: nil)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(keys: ["c"]) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                if editingInputActive { return .ignored }
                guard selection.hasSelection else { return .ignored }
                boardViewModel.copySelectedElementsToPasteboard(selection: selection)
                return .handled
            }
            .onKeyPress(keys: ["v"]) { press in
                if press.modifiers.contains(.command) {
                    if editingInputActive { return .ignored }
                    guard boardViewModel.canPasteFromClipboard else { return .ignored }
                    boardViewModel.pasteClipboardElements(selection: selection)
                    return .handled
                }
                guard !press.modifiers.contains(.option), !press.modifiers.contains(.control) else { return .ignored }
                if editingInputActive { return .ignored }
                boardViewModel.applyCanvasToolSelection(.select, fromKeyboard: true)
                return .handled
            }
            .onKeyPress(keys: ["d"]) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                if editingInputActive { return .ignored }
                guard selection.hasSelection else { return .ignored }
                boardViewModel.duplicateAllSelectedElements(selection: selection)
                return .handled
            }
            .onKeyPress(keys: ["z"]) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                if editingInputActive { return .ignored }
                if press.modifiers.contains(.shift) {
                    guard boardViewModel.canRedoBoard else { return .ignored }
                    boardViewModel.redoBoard()
                } else {
                    guard boardViewModel.canUndoBoard else { return .ignored }
                    boardViewModel.undoBoard()
                }
                return .handled
            }
            .onKeyPress(keys: ["1", "2", "3"]) { press in
                guard press.modifiers.contains(.command), press.modifiers.contains(.option) else { return .ignored }
                if editingInputActive { return .ignored }
                switch press.characters {
                case "1":
                    boardViewModel.fitViewportToBoardContent()
                case "2":
                    boardViewModel.centerViewportOnBoardContent(canvasMargin: 48)
                case "3":
                    guard selection.hasSelection else { return .ignored }
                    boardViewModel.fitViewportToSelection(selection: selection)
                default:
                    return .ignored
                }
                return .handled
            }
            .onKeyPress(keys: ["=", "+"]) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                if editingInputActive { return .ignored }
                boardViewModel.nudgeViewportZoomIn()
                return .handled
            }
            .onKeyPress(keys: ["-"]) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                if editingInputActive { return .ignored }
                boardViewModel.nudgeViewportZoomOut()
                return .handled
            }
            .onKeyPress(keys: ["t"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.text, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["h"]) { press in
                singleKeyToolPress(press) {
                    // This canvas pans in Select mode, so Hand/Pan maps to Select.
                    boardViewModel.applyCanvasToolSelection(.select, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["n"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.stickyNote, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["r"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true, rectanglePlacementShape: true)
                }
            }
            .onKeyPress(keys: ["l"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true)
                    boardViewModel.placeShapeKind = .line
                }
            }
            .onKeyPress(keys: ["a"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true)
                    boardViewModel.placeShapeKind = .arrow
                }
            }
            .onKeyPress(keys: ["s"]) { press in
                _ = press
                return .ignored
            }
            .onKeyPress(keys: ["p"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.pen, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["b"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.pencil, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["g"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.toggleViewportShowGrid()
                }
            }
            .onKeyPress(keys: ["k"]) { press in
                singleKeyToolPress(press) {
                    boardViewModel.applyCanvasToolSelection(.connect, fromKeyboard: true)
                }
            }
            .onKeyPress(keys: ["?", "/"]) { press in
                guard !press.modifiers.contains(.command),
                      !press.modifiers.contains(.option),
                      !press.modifiers.contains(.control)
                else { return .ignored }
                if press.characters == "/" && !press.modifiers.contains(.shift) {
                    return .ignored
                }
                if editingInputActive {
                    return .ignored
                }
                NotificationCenter.default.post(name: .flowDeskOpenShortcutHelp, object: nil)
                return .handled
            }
    }

    private var inlineEditingActive: Bool {
        boardViewModel.editingTextElementID != nil
            || boardViewModel.editingStickyNoteElementID != nil
            || boardViewModel.editingConnectorLabelElementID != nil
    }

    private var editingInputActive: Bool {
        inlineEditingActive || textInputFocused
    }

    private var textInputFocused: Bool {
#if os(macOS)
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        if responder is NSTextView {
            return true
        }
        if let view = responder as? NSView {
            return view is NSTextField || view.enclosingScrollView?.documentView is NSTextView
        }
#endif
        return false
    }

    private func singleKeyToolPress(_ press: KeyPress, activate: () -> Void) -> KeyPress.Result {
        if press.modifiers.contains(.command) || press.modifiers.contains(.option) || press.modifiers.contains(.control) {
            return .ignored
        }
        if editingInputActive {
            return .ignored
        }
        activate()
        return .handled
    }
}

extension View {
    func canvasScreenKeyCommands(
        boardViewModel: CanvasBoardViewModel,
        selection: CanvasSelectionModel,
        isFocusModeEnabled: Bool = false
    ) -> some View {
        modifier(
            CanvasScreenKeyCommands(
                boardViewModel: boardViewModel,
                selection: selection,
                isFocusModeEnabled: isFocusModeEnabled
            )
        )
    }
}
