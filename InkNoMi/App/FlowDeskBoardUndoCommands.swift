import Foundation

extension Notification.Name {
    /// Posted to request a canvas board undo (handled by `MainWindowView` when a document is open).
    static let flowDeskBoardUndo = Notification.Name("FlowDesk.boardUndo")
    /// Posted to request a canvas board redo.
    static let flowDeskBoardRedo = Notification.Name("FlowDesk.boardRedo")
    /// Posted to request showing the app command palette.
    static let flowDeskOpenCommandPalette = Notification.Name("FlowDesk.openCommandPalette")
    /// Posted to toggle editor focus mode.
    static let flowDeskToggleFocusMode = Notification.Name("FlowDesk.toggleFocusMode")
    /// Posted to exit editor focus mode.
    static let flowDeskExitFocusMode = Notification.Name("FlowDesk.exitFocusMode")
    /// Posted to request exporting the active board quickly.
    static let flowDeskExportBoard = Notification.Name("FlowDesk.exportBoard")
    /// Posted to request opening keyboard shortcut help.
    static let flowDeskOpenShortcutHelp = Notification.Name("FlowDesk.openShortcutHelp")
}
