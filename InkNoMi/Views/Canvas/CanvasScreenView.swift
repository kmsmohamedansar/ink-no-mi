import SwiftUI

/// macOS canvas screen: canvas-first tools + lightweight window toolbar (Edit / View / Export).
struct CanvasScreenView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var document: FlowDocument
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    var onBackHome: (() -> Void)? = nil
    @State private var didEnterWorkspace = false
    @State private var didFadeBackground = false
    @State private var autosavePulse = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            FlowDeskTheme.premiumBackgroundBase()
                .ignoresSafeArea()
                .opacity(didFadeBackground ? 1 : 0.9)
                .animation(FlowDeskMotion.canvasEnter, value: didFadeBackground)

            CanvasBoardView(
                boardViewModel: boardViewModel,
                selection: selection
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            InkNoMiCanvasChromeColumn(
                boardViewModel: boardViewModel,
                selection: selection
            )
            .padding(.leading, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(didEnterWorkspace ? 1 : 0.93)
        .scaleEffect(didEnterWorkspace ? 1 : 0.982)
        .animation(FlowDeskMotion.canvasEnter, value: didEnterWorkspace)
        .onAppear {
            didEnterWorkspace = true
            didFadeBackground = true
        }
        .navigationTitle(document.title)
        #if os(macOS)
        .navigationSubtitle("Last edited \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        #endif
        .canvasScreenKeyCommands(boardViewModel: boardViewModel, selection: selection)
        .onDeleteCommand {
            boardViewModel.deleteSelectedElements(selection: selection)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if let onBackHome {
                    Button(action: onBackHome) {
                        Label("Home", systemImage: "chevron.left")
                    }
                    .help("Back to Home dashboard")
                }

                TextField("Canvas title", text: $document.title)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180, idealWidth: 240, maxWidth: 320)
                    .onSubmit {
                        document.markUpdated()
                    }

                HStack(spacing: 10) {
                    savedStatusBadge

                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        Text("Last edited \(relativeLastEditedText)")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                HStack(spacing: 8) {
                    editorStatChip(
                        icon: "plus.magnifyingglass",
                        text: "\(zoomPercent)%"
                    )
                    editorStatChip(
                        icon: "rectangle.dashed",
                        text: "\(canvasSizeLabel)"
                    )
                    editorStatChip(
                        icon: "square.on.square",
                        text: "\(boardViewModel.boardState.elements.count)"
                    )
                }
            }

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
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .medium))
                        Text("Edit")
                            .font(DS.Typography.toolLabel)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                                    .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                            )
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
                            .font(DS.Typography.toolLabel)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                                    .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                            )
                    )
                }
                .help("Grid, canvas framing, insert items in view, and charts")
                .buttonStyle(FlowDeskToolbarButtonStyle())

                Menu {
                    Button("PNG…") {
                        let renderScale = resolvedExportScale()
                        CanvasExportService.presentExportPanel(
                            boardState: boardViewModel.boardState,
                            documentTitle: document.title,
                            format: .png,
                            renderScale: renderScale
                        )
                    }
                    .help("Save the board as a PNG image")
                    Button("PDF…") {
                        let renderScale = resolvedExportScale()
                        CanvasExportService.presentExportPanel(
                            boardState: boardViewModel.boardState,
                            documentTitle: document.title,
                            format: .pdf,
                            renderScale: renderScale
                        )
                    }
                    .help("Save the board as a one-page PDF")
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(DS.Typography.toolLabel)
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                                )
                        )
                }
                .help("Save this board as PNG or PDF")
                .buttonStyle(FlowDeskToolbarButtonStyle())

            }
        }
        .task {
            while !Task.isCancelled {
                withAnimation(FlowDeskMotion.smoothEaseOut) {
                    autosavePulse.toggle()
                }
                try? await Task.sleep(nanoseconds: 1_300_000_000)
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

    private func resolvedExportScale() -> CGFloat {
        if purchaseManager.isProUser {
            return PurchaseManager.proExportScale
        }
        _ = purchaseManager.requirePro(for: .highResolutionExport)
        return PurchaseManager.freeExportScale
    }

    private var zoomPercent: Int {
        Int((boardViewModel.boardState.viewport.scale * 100).rounded())
    }

    private var canvasSizeLabel: String {
        let size = Int(CanvasBoardView.logicalCanvasSize.rounded())
        return "\(size)×\(size)"
    }

    private var savedStatusBadge: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(DS.Color.accent.opacity(autosavePulse ? 0.14 : 0.06))
                    .frame(width: autosavePulse ? 15 : 11, height: autosavePulse ? 15 : 11)
                Circle()
                    .fill(DS.Color.accent.opacity(0.95))
                    .frame(width: 6, height: 6)
            }
            .animation(FlowDeskMotion.smoothEaseOut, value: autosavePulse)

            Label("Saved", systemImage: "checkmark.circle.fill")
                .font(DS.Typography.caption.weight(.medium))
                .foregroundStyle(DS.Color.textSecondary)
                .labelStyle(.titleAndIcon)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DS.Color.active.opacity(0.75), DS.Color.surfaceFloatingBottom.opacity(colorScheme == .dark ? 0.26 : 0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme), lineWidth: 0.8)
                )
        )
    }

    private var relativeLastEditedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: document.updatedAt, relativeTo: .now)
    }

    private func editorStatChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(DS.Typography.caption.weight(.medium))
                .monospacedDigit()
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .foregroundStyle(DS.Color.textSecondary)
        .background(
            Capsule(style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.7)
        )
    }
}
