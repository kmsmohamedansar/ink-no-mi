import SwiftUI

/// macOS canvas screen: canvas-first tools + lightweight window toolbar (Edit / View / Export).
struct CanvasScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Bindable var document: FlowDocument
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    var isFocusModeEnabled: Bool = false
    var screenshotPolishMode: Bool = false
    var onBackHome: (() -> Void)? = nil
    @State private var didEnterWorkspace = false
    @State private var didFadeBackground = false
    @State private var showCommandPalette = false
    @State private var showShortcutHelp = false
    @State private var exportSheetViewModel: CanvasExportSheetViewModel?
    @State private var titleAutosaveTask: Task<Void, Never>?
    @FocusState private var isBoardTitleFocused: Bool
    @State private var isBoardTitleHovered = false
    @State private var toolPanelOffset: CGSize = .zero
    @State private var toolPanelDragOffset: CGSize = .zero
    @State private var toolPanelSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                FlowDeskTheme.premiumBackgroundBase()
                    .ignoresSafeArea()
                    .opacity(didFadeBackground ? 1 : 0.9)
                    .animation(FlowDeskMotion.canvasEnter, value: didFadeBackground)

                CanvasBoardView(
                    boardViewModel: boardViewModel,
                    selection: selection
                )
                .flowDeskDepthShadows(FlowDeskDepth.canvasWorkspace)
                .brightness(isImmersiveEditingActive ? 0.01 : 0)
                .contrast(isImmersiveEditingActive ? 1.01 : 1)
                .animation(FlowDeskMotion.mediumEaseOut, value: isImmersiveEditingActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                InkNoMiCanvasChromeColumn(
                    boardViewModel: boardViewModel,
                    selection: selection,
                    compactMode: isFocusModeEnabled,
                    screenshotPolishMode: screenshotPolishMode
                )
                .opacity(immersivePanelOpacity)
                .background(
                    GeometryReader { panelGeo in
                        Color.clear
                            .onAppear {
                                toolPanelSize = panelGeo.size
                            }
                            .onChange(of: panelGeo.size) { _, newSize in
                                toolPanelSize = newSize
                                toolPanelOffset = clampedToolPanelOffset(toolPanelOffset, in: geo.size)
                            }
                    }
                )
                .offset(
                    x: DS.Spacing.lg + toolPanelOffset.width + toolPanelDragOffset.width,
                    y: DS.Spacing.lg + toolPanelOffset.height + toolPanelDragOffset.height
                )
                .gesture(toolPanelDragGesture(in: geo.size))
                .transition(.move(edge: .leading).combined(with: .opacity))

                if showCommandPalette {
                    CommandPaletteView(
                        isPresented: $showCommandPalette,
                        commands: commandPaletteCommands
                    )
                    .zIndex(1_000_000)
                }

                if showShortcutHelp {
                    KeyboardShortcutsOverlayView(isPresented: $showShortcutHelp)
                        .zIndex(1_000_001)
                }

                if isFocusModeEnabled {
                    VStack {
                        Spacer()
                        Text("Press Esc to exit Focus Mode")
                            .font(DS.Typography.caption.weight(.medium))
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme), lineWidth: 0.8)
                                    )
                            )
                            .padding(.bottom, DS.Spacing.lg)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(didEnterWorkspace ? 1 : 0.93)
        .scaleEffect(didEnterWorkspace ? 1 : 0.982)
        .animation(FlowDeskMotion.canvasEnter, value: didEnterWorkspace)
        .onAppear {
            didEnterWorkspace = true
            didFadeBackground = true
        }
        .onDisappear {
            titleAutosaveTask?.cancel()
        }
        .onChange(of: document.title) { _, _ in
            scheduleTitleAutosave()
        }
        .navigationTitle(boardTitleForWindowChrome)
        #if os(macOS)
        .navigationSubtitle("Last edited \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        #endif
        .overlay(alignment: .top) {
            if boardViewModel.saveErrorBannerVisible {
                saveErrorBanner
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            if !isFocusModeEnabled && !screenshotPolishMode {
                minimalStatusBar
                    .opacity(immersivePanelOpacity)
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(FlowDeskMotion.mediumEaseInOut, value: isFocusModeEnabled)
        .canvasScreenKeyCommands(
            boardViewModel: boardViewModel,
            selection: selection,
            isFocusModeEnabled: isFocusModeEnabled
        )
        .onDeleteCommand {
            boardViewModel.deleteSelectedElements(selection: selection)
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskOpenCommandPalette)) { _ in
            showShortcutHelp = false
            showCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskOpenShortcutHelp)) { _ in
            showCommandPalette = false
            showShortcutHelp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskExportBoard)) { _ in
            performQuickExport()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack(spacing: FlowDeskLayout.windowToolbarLeadingClusterSpacing) {
                    if let onBackHome {
                        Button(action: onBackHome) {
                            Label("Home", systemImage: "chevron.left")
                        }
                        .help("Back to Home dashboard")
                    }

                    canvasBoardInlineTitle

                    if !screenshotPolishMode {
                        saveStatusMetaChip
                    }
                }
                .opacity(immersivePanelOpacity)
            }

            ToolbarItemGroup(placement: .automatic) {
                canvasPrimaryActionsToolbarCluster
                    .opacity(immersivePanelOpacity)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Keyboard Shortcuts") {
                        showCommandPalette = false
                        showShortcutHelp = true
                    }
                    .keyboardShortcut("/", modifiers: [.shift])
                } label: {
                    Image(systemName: "questionmark.circle")
                        .flowDeskStandardIcon()
                        .foregroundStyle(DS.Color.accent.opacity(0.66))
                        .frame(width: 34, height: 30)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help("Help — keyboard shortcuts")
                .accessibilityLabel("Help")
                .opacity(immersivePanelOpacity)
            }
        }
        .sheet(item: $exportSheetViewModel) { viewModel in
            CanvasExportSheet(viewModel: viewModel)
                .presentationDetents([.height(640), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var boardTitleForWindowChrome: String {
        let trimmed = document.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled board" : trimmed
    }

    private var isImmersiveEditingActive: Bool {
        boardViewModel.editingTextElementID != nil
            || boardViewModel.editingStickyNoteElementID != nil
            || boardViewModel.editingConnectorLabelElementID != nil
    }

    private var immersivePanelOpacity: Double {
        isImmersiveEditingActive ? 0.9 : 1
    }

    private var boardTitleDisplayString: String {
        let trimmed = document.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled board" : trimmed
    }

    private var boardTitleForegroundColor: Color {
        document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? DS.Color.textTertiary
            : DS.Color.textPrimary
    }

    private var boardTitleUnderlineOpacity: Double {
        if isBoardTitleFocused { return 0.52 }
        if isBoardTitleHovered { return 0.34 }
        return 0
    }

    /// Document-style title: large display type, tap to edit, plain field when focused, underline on hover/focus.
    private var canvasBoardInlineTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                if isBoardTitleFocused {
                    TextField(
                        "",
                        text: $document.title,
                        prompt: Text("Untitled board").foregroundStyle(DS.Color.textTertiary)
                    )
                    .textFieldStyle(.plain)
                    .font(DS.Typography.boardTitle)
                    .tracking(DS.Typography.boardTitleTracking)
                    .foregroundStyle(DS.Color.textPrimary)
                    .focused($isBoardTitleFocused)
                    .onSubmit {
                        isBoardTitleFocused = false
                        persistTitleNow()
                    }
                } else {
                    Text(boardTitleDisplayString)
                        .font(DS.Typography.boardTitle)
                        .tracking(DS.Typography.boardTitleTracking)
                        .foregroundStyle(boardTitleForegroundColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isBoardTitleFocused = true
                        }
                }
            }
            .frame(
                minWidth: FlowDeskLayout.windowToolbarBoardTitleMinWidth,
                idealWidth: FlowDeskLayout.windowToolbarBoardTitleIdealWidth,
                maxWidth: FlowDeskLayout.windowToolbarBoardTitleMaxWidth,
                alignment: .leading
            )
            .frame(minHeight: 28, alignment: .leading)

            Rectangle()
                .fill(DS.Color.textPrimary.opacity(0.88))
                .frame(height: isBoardTitleFocused ? 1.35 : 1.15)
                .opacity(boardTitleUnderlineOpacity)
                .animation(FlowDeskMotion.mediumEaseInOut, value: boardTitleUnderlineOpacity)
                .animation(FlowDeskMotion.fastEaseInOut, value: isBoardTitleFocused)
        }
        .frame(
            maxWidth: FlowDeskLayout.windowToolbarBoardTitleMaxWidth,
            alignment: .leading
        )
        .onHover { isBoardTitleHovered = $0 }
        .onChange(of: isBoardTitleFocused) { _, focused in
            if !focused {
                persistTitleNow()
            }
        }
        .onExitCommand {
            isBoardTitleFocused = false
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Board title")
        .accessibilityValue(boardTitleDisplayString)
        .accessibilityHint("Tap to edit this board’s name")
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

    /// Unified **Edit | View | Export** control — one surface, clear segments (product toolbar, not ad-hoc pills).
    private var canvasPrimaryActionsToolbarCluster: some View {
        HStack(spacing: 0) {
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
                canvasToolbarNamedSegmentLabel(icon: "slider.horizontal.3", title: "Edit")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Undo, clipboard, layering, delete")
            .accessibilityLabel("Edit")

            canvasToolbarSegmentDivider

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
                canvasToolbarNamedSegmentLabel(icon: "rectangle.split.2x1", title: "View")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Grid, zoom, and how the canvas is framed")
            .accessibilityLabel("View")

            canvasToolbarSegmentDivider

            Menu {
                Button("Export board…") {
                    exportSheetViewModel = CanvasExportSheetViewModel(
                        boardState: boardViewModel.boardState,
                        documentTitle: document.title,
                        selectedElementIDs: selection.selectedElementIDs,
                        viewportSnapshot: boardViewModel.insertionViewportSnapshot
                    )
                }
                .help("PNG, PDF, and options")
            } label: {
                canvasToolbarNamedSegmentLabel(icon: "square.and.arrow.up", title: "Export")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Export or share this board")
            .accessibilityLabel("Export")
        }
        .padding(.horizontal, FlowDeskLayout.windowToolbarPrimaryClusterPaddingH)
        .padding(.vertical, FlowDeskLayout.windowToolbarPrimaryClusterPaddingV)
        .background(
            RoundedRectangle(cornerRadius: FlowDeskLayout.windowToolbarPrimaryClusterCornerRadius, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: FlowDeskLayout.windowToolbarPrimaryClusterCornerRadius, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.85)
                )
        )
        .frame(minHeight: 34)
    }

    private var canvasToolbarSegmentDivider: some View {
        Rectangle()
            .fill(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme).opacity(0.42))
            .frame(width: 1, height: FlowDeskLayout.windowToolbarSegmentDividerHeight)
            .padding(.vertical, 2)
    }

    private func canvasToolbarNamedSegmentLabel(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .flowDeskStandardIcon()
                .foregroundStyle(DS.Color.accent.opacity(0.64))
                .frame(width: 15, alignment: .center)
            Text(title)
                .font(DS.Typography.toolLabel)
                .foregroundStyle(DS.Color.textPrimary)
            Image(systemName: "chevron.down")
                .flowDeskStandardIcon(size: 10)
                .foregroundStyle(DS.Color.textTertiary.opacity(0.92))
                .padding(.leading, 1)
        }
        .padding(.horizontal, FlowDeskLayout.windowToolbarSegmentPaddingH)
        .padding(.vertical, FlowDeskLayout.windowToolbarSegmentPaddingV)
        .contentShape(Rectangle())
    }

    private func performQuickExport() {
        exportSheetViewModel = CanvasExportSheetViewModel(
            boardState: boardViewModel.boardState,
            documentTitle: document.title,
            selectedElementIDs: selection.selectedElementIDs,
            viewportSnapshot: boardViewModel.insertionViewportSnapshot
        )
    }

    private var commandPaletteCommands: [CommandPaletteCommand] {
        [
            CommandPaletteCommand(id: "tool.select", title: "Select Tool", icon: "cursorarrow", shortcut: "V", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.select, fromKeyboard: true)
            },
            CommandPaletteCommand(id: "tool.pan", title: "Hand / Pan Tool", icon: "hand.draw", shortcut: "H", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.select, fromKeyboard: true)
            },
            CommandPaletteCommand(id: "tool.pen", title: "Pen Tool", icon: "pencil.tip", shortcut: "P", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.pen, fromKeyboard: true)
            },
            CommandPaletteCommand(id: "tool.note", title: "Note Tool", icon: "note.text", shortcut: "N", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.stickyNote, fromKeyboard: true)
            },
            CommandPaletteCommand(id: "tool.text", title: "Text Tool", icon: "textformat", shortcut: "T", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.text, fromKeyboard: true)
            },
            CommandPaletteCommand(id: "tool.rectangle", title: "Rectangle Tool", icon: "square", shortcut: "R", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true, rectanglePlacementShape: true)
            },
            CommandPaletteCommand(id: "tool.line", title: "Line Tool", icon: "line.diagonal", shortcut: "L", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true)
                boardViewModel.placeShapeKind = .line
            },
            CommandPaletteCommand(id: "tool.arrow", title: "Arrow Tool", icon: "arrow.right", shortcut: "A", category: "Tools") {
                boardViewModel.applyCanvasToolSelection(.shape, fromKeyboard: true)
                boardViewModel.placeShapeKind = .arrow
            },
            CommandPaletteCommand(id: "edit.undo", title: "Undo", icon: "arrow.uturn.backward", shortcut: "Cmd+Z", category: "Editing") {
                boardViewModel.undoBoard()
            },
            CommandPaletteCommand(id: "edit.redo", title: "Redo", icon: "arrow.uturn.forward", shortcut: "Cmd+Shift+Z", category: "Editing") {
                boardViewModel.redoBoard()
            },
            CommandPaletteCommand(
                id: "view.focus_mode",
                title: isFocusModeEnabled ? "Exit Focus Mode" : "Enter Focus Mode",
                icon: isFocusModeEnabled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                shortcut: "Cmd+Shift+F",
                category: "View"
            ) {
                NotificationCenter.default.post(name: .flowDeskToggleFocusMode, object: nil)
            },
            CommandPaletteCommand(id: "app.export", title: "Export", icon: "square.and.arrow.up", shortcut: "Cmd+E", category: "Navigation") {
                performQuickExport()
            },
            CommandPaletteCommand(id: "app.shortcuts", title: "Keyboard Shortcuts", icon: "keyboard", shortcut: "?", category: "Navigation") {
                showShortcutHelp = true
            }
        ]
    }

    private var zoomPercent: Int {
        Int((boardViewModel.boardState.viewport.scale * 100).rounded())
    }

    private var canvasSizeLabel: String {
        let size = Int(CanvasBoardView.logicalCanvasSize.rounded())
        return "\(size)×\(size)"
    }

    private var saveStatusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: saveBadgeIconName)
                .flowDeskStandardIcon(size: DS.Icon.accessorySize)
                .foregroundStyle(saveBadgeColor)

            Text(saveBadgeTitle)
                .font(DS.Typography.caption.weight(.medium))
                .foregroundStyle(saveBadgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [saveBadgeColor.opacity(0.1), DS.Color.surfaceFloatingBottom.opacity(colorScheme == .dark ? 0.2 : 0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme).opacity(0.7), lineWidth: 0.6)
                )
        )
    }

    private var saveStatusMetaChip: some View {
        HStack(spacing: 8) {
            saveStatusBadge
            Rectangle()
                .fill(DS.Color.textTertiary.opacity(0.3))
                .frame(width: 1, height: 12)
            Text(lastEditedText.replacingOccurrences(of: "Last edited ", with: ""))
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }

    private var saveBadgeTitle: String {
        switch boardViewModel.saveStatus {
        case .saving:
            return "Saving..."
        case .saved:
            return "Saved"
        case .localOnly:
            return "Local only"
        }
    }

    private var saveBadgeIconName: String {
        switch boardViewModel.saveStatus {
        case .saving:
            return "arrow.triangle.2.circlepath"
        case .saved:
            return "checkmark.circle.fill"
        case .localOnly:
            return "externaldrive.badge.exclamationmark"
        }
    }

    private var saveBadgeColor: Color {
        switch boardViewModel.saveStatus {
        case .saving:
            return DS.Color.textSecondary
        case .saved:
            return DS.Color.textSecondary
        case .localOnly:
            return .orange
        }
    }

    private var lastEditedText: String {
        let editedAt = max(boardViewModel.lastSavedAt ?? .distantPast, document.updatedAt)
        guard editedAt != .distantPast else { return "Last edited just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Last edited \(formatter.localizedString(for: editedAt, relativeTo: .now))"
    }

    private var saveErrorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Couldn't save changes locally. Try again.")
                .font(DS.Typography.caption.weight(.medium))
            Spacer(minLength: 8)
            Button("Dismiss") {
                boardViewModel.dismissSaveErrorBanner()
            }
            .buttonStyle(.plain)
            .font(DS.Typography.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: 480)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.orange.opacity(0.25), lineWidth: 0.8)
                )
        )
    }

    private func editorStatChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .flowDeskStandardIcon(size: DS.Icon.accessorySize)
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
                .strokeBorder(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme).opacity(0.65), lineWidth: 0.55)
        )
    }

    private var toolContextChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "cursorarrow.motionlines")
                .flowDeskStandardIcon(size: DS.Icon.accessorySize)
            Text("Tool: \(currentToolName) (\(currentToolShortcut))")
                .font(DS.Typography.caption.weight(.medium))
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
                .strokeBorder(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme).opacity(0.65), lineWidth: 0.55)
        )
    }

    private var minimalStatusBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Text(document.title.isEmpty ? "Untitled Board" : document.title)
                    .font(DS.Typography.caption.weight(.medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)

                editorStatChip(icon: "plus.magnifyingglass", text: "\(zoomPercent)%")
                editorStatChip(icon: "rectangle.dashed", text: canvasSizeLabel)
                editorStatChip(icon: "square.on.square", text: "\(boardViewModel.boardState.elements.count)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    gridBinding.wrappedValue.toggle()
                } label: {
                    Label(gridBinding.wrappedValue ? "Grid On" : "Grid Off", systemImage: "grid")
                        .font(DS.Typography.caption.weight(.medium))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textSecondary)

                Text("\(zoomPercent)%")
                    .font(DS.Typography.caption.weight(.medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme), lineWidth: 0.8)
                )
        )
    }

    private var currentToolName: String {
        switch boardViewModel.canvasTool {
        case .select: return "Select"
        case .connect: return "Connect"
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .text: return "Text"
        case .stickyNote: return "Note"
        case .shape: return shapeToolName
        case .chart: return "Chart"
        case .smartInk: return "Smart Ink"
        }
    }

    private var currentToolShortcut: String {
        switch boardViewModel.canvasTool {
        case .select: return "V"
        case .connect: return "K"
        case .pen: return "P"
        case .pencil: return "B"
        case .text: return "T"
        case .stickyNote: return "N"
        case .shape: return "R/L/A"
        case .chart: return "-"
        case .smartInk: return "-"
        }
    }

    private var shapeToolName: String {
        switch boardViewModel.placeShapeKind {
        case .rectangle: return "Rectangle"
        case .roundedRectangle: return "Rounded Rectangle"
        case .ellipse: return "Oval"
        case .line: return "Line"
        case .arrow: return "Arrow"
        }
    }

    private func toolPanelDragGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                toolPanelDragOffset = value.translation
            }
            .onEnded { value in
                let proposed = CGSize(
                    width: toolPanelOffset.width + value.translation.width,
                    height: toolPanelOffset.height + value.translation.height
                )
                toolPanelDragOffset = .zero
                withAnimation(FlowDeskMotion.fastEaseOut) {
                    toolPanelOffset = snappedToolPanelOffset(
                        clampedToolPanelOffset(proposed, in: availableSize),
                        in: availableSize
                    )
                }
            }
    }

    private func clampedToolPanelOffset(_ offset: CGSize, in availableSize: CGSize) -> CGSize {
        let horizontalLimit = max(0, availableSize.width - toolPanelSize.width - (DS.Spacing.lg * 2))
        let verticalLimit = max(0, availableSize.height - toolPanelSize.height - (DS.Spacing.lg * 2))
        return CGSize(
            width: min(max(offset.width, 0), horizontalLimit),
            height: min(max(offset.height, 0), verticalLimit)
        )
    }

    private func snappedToolPanelOffset(_ offset: CGSize, in availableSize: CGSize) -> CGSize {
        let horizontalLimit = max(0, availableSize.width - toolPanelSize.width - (DS.Spacing.lg * 2))
        let verticalLimit = max(0, availableSize.height - toolPanelSize.height - (DS.Spacing.lg * 2))
        let snapDistance: CGFloat = 42
        var x = offset.width
        var y = offset.height
        if x < snapDistance { x = 0 }
        if (horizontalLimit - x) < snapDistance { x = horizontalLimit }
        if y < snapDistance { y = 0 }
        if (verticalLimit - y) < snapDistance { y = verticalLimit }
        return CGSize(width: x, height: y)
    }

    private func scheduleTitleAutosave() {
        titleAutosaveTask?.cancel()
        titleAutosaveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 650_000_000)
            } catch {
                return
            }
            persistTitleNow()
        }
    }

    private func persistTitleNow() {
        titleAutosaveTask?.cancel()
        document.markUpdated()
        try? modelContext.save()
    }
}
