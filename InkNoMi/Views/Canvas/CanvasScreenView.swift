import SwiftUI

/// macOS canvas screen: canvas-first tools + lightweight window toolbar (Edit / View / Export).
struct CanvasScreenView: View {
    @Bindable var document: FlowDocument
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    var body: some View {
        ZStack(alignment: .leading) {
            CanvasBoardView(
                boardViewModel: boardViewModel,
                selection: selection
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            InkNoMiCanvasChromeColumn(
                boardViewModel: boardViewModel,
                selection: selection
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(document.title)
        #if os(macOS)
        .navigationSubtitle("Last edited \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        #endif
        .canvasScreenKeyCommands(boardViewModel: boardViewModel, selection: selection)
        .onDeleteCommand {
            boardViewModel.deleteSelectedElements(selection: selection)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button("Undo") {
                        boardViewModel.undoBoard()
                    }
                    .disabled(!boardViewModel.canUndoBoard)
                    .keyboardShortcut("z", modifiers: [.command])
                    .help("Undo the last change on this board")

                    Button("Redo") {
                        boardViewModel.redoBoard()
                    }
                    .disabled(!boardViewModel.canRedoBoard)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .help("Redo a previously undone change")

                    Divider()

                    Button("Duplicate") {
                        boardViewModel.duplicateAllSelectedElements(selection: selection)
                    }
                    .disabled(!selection.hasSelection)
                    .keyboardShortcut("d", modifiers: [.command])
                    .help("Duplicate the selected items on this board")

                    Divider()

                    Button("Copy") {
                        boardViewModel.copySelectedElementsToPasteboard(selection: selection)
                    }
                    .disabled(!selection.hasSelection)
                    .keyboardShortcut("c", modifiers: [.command])
                    .help("Copy selected canvas items to paste elsewhere on this board")

                    Button("Paste") {
                        boardViewModel.pasteClipboardElements(selection: selection)
                    }
                    .disabled(!boardViewModel.canPasteFromClipboard)
                    .keyboardShortcut("v", modifiers: [.command])
                    .help("Paste items copied from this board in Ink no Mi (not plain text from other apps)")

                    Divider()

                    Menu("Arrange") {
                        Button("Bring to Front") {
                            boardViewModel.bringSelectionToFront(selection: selection)
                        }
                        Button("Bring Forward") {
                            boardViewModel.bringSelectionForward(selection: selection)
                        }
                        .disabled(!boardViewModel.canBringSelectionForward(selection: selection))
                        Button("Send Backward") {
                            boardViewModel.sendSelectionBackward(selection: selection)
                        }
                        .disabled(!boardViewModel.canSendSelectionBackward(selection: selection))
                        Button("Send to Back") {
                            boardViewModel.sendSelectionToBack(selection: selection)
                        }
                    }
                    .disabled(selection.primarySelectedID == nil)

                    Divider()

                    Button("Delete", role: .destructive) {
                        boardViewModel.deleteSelectedElements(selection: selection)
                    }
                    .disabled(!selection.hasSelection)
                    .help("Remove selected items from the board")
                } label: {
                    HStack(spacing: 5) {
                        Text("Edit")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
                .buttonStyle(FlowDeskToolbarButtonStyle())

                Menu {
                    Toggle("Show grid", isOn: gridBinding)
                    Divider()
                    Button("Fit board to content") {
                        boardViewModel.fitViewportToBoardContent()
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                    .help("Zoom and pan so everything on the board is visible (⌘⌥1)")
                    Button("Center on content") {
                        boardViewModel.centerViewportOnBoardContent(canvasMargin: 48)
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                    .help("Pan so exported content is centered at the current zoom (⌘⌥2)")
                    Button("Zoom to selection") {
                        boardViewModel.fitViewportToSelection(selection: selection)
                    }
                    .disabled(!selection.hasSelection)
                    .keyboardShortcut("3", modifiers: [.command, .option])
                    .help("Zoom and pan to fit the selected items (⌘⌥3)")
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 14, weight: .medium))
                        Text("View")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
                .help("Grid, canvas framing, insert items in view, and charts")
                .buttonStyle(FlowDeskToolbarButtonStyle())

                Menu {
                    Button("PNG…") {
                        CanvasExportService.presentExportPanel(
                            boardState: boardViewModel.boardState,
                            documentTitle: document.title,
                            format: .png
                        )
                    }
                    .help("Save the board as a PNG image")
                    Button("PDF…") {
                        CanvasExportService.presentExportPanel(
                            boardState: boardViewModel.boardState,
                            documentTitle: document.title,
                            format: .pdf
                        )
                    }
                    .help("Save the board as a one-page PDF")
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )
                }
                .help("Save this board as PNG or PDF")
                .buttonStyle(FlowDeskToolbarButtonStyle())
            }
        }
    }

    private var gridBinding: Binding<Bool> {
        Binding(
            get: { boardViewModel.boardState.viewport.showGrid },
            set: { newValue in
                var viewport = boardViewModel.boardState.viewport
                viewport.showGrid = newValue
                boardViewModel.setViewport(viewport)
            }
        )
    }
}
