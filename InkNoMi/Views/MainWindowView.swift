import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MainWindowView: View {
    enum AppRoute: Equatable {
        case home
        case editor
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appearanceStore: AppearanceManager
    @Environment(PurchaseManager.self) private var purchaseManager

    @Query(sort: \FlowDocument.updatedAt, order: .reverse)
    private var documents: [FlowDocument]

    @State private var selection: FlowDocument?
    @State private var route: AppRoute = .home
    @State private var documentListViewModel = DocumentListViewModel()
    @State private var canvasBoardViewModel = CanvasBoardViewModel()
    @State private var canvasSelection = CanvasSelectionModel()

    @State private var renameSession: RenameSession?
    @State private var renameDraft: String = ""
    @State private var isNewBoardSheetPresented = false
    @State private var isCommandPalettePresented = false
    @State private var isFocusModeEnabled = false
    @State private var creationSuccessMessage: String?
    @State private var creationSuccessTask: Task<Void, Never>?
    #if DEBUG
    @State private var screenshotModeLoaded = false
    @State private var screenshotFocusDocumentID: PersistentIdentifier?
    @State private var screenshotScene: ScreenshotModeService.Scene = .homeTemplates
    #endif

    private var appearanceTokens: DynamicTheme {
        DynamicTheme.resolve(colorScheme: colorScheme, settings: appearanceStore.settings)
    }

    private var featureGate: FeatureGate {
        FeatureGate(purchaseManager: purchaseManager)
    }

    private var isScreenshotModeActive: Bool {
        #if DEBUG
        screenshotModeLoaded
        #else
        false
        #endif
    }

    var body: some View {
        ZStack {
            Group {
                if route == .home {
                    #if DEBUG
                    HomeView(
                        documents: documents,
                        onOpenDocument: openDocument,
                        onCreateTemplate: createBoard(from:),
                        onCreateTemplateWithTitle: createBoard(from:title:),
                        onCreateBlankBoardWithTitle: createBlankBoard(title:),
                        onNewWorkspace: presentNewBoardSheet,
                        onDuplicate: duplicateBoard,
                        onRename: beginRename,
                        onDelete: deleteBoard,
                        onToggleFavorite: toggleFavorite,
                        onExport: exportBoard,
                        onLoadScreenshotDemoData: { loadScreenshotDemoData(scene: screenshotScene) },
                        onSelectScreenshotScene: { screenshotScene = $0 },
                        selectedScreenshotScene: screenshotScene,
                        showScreenshotControls: !screenshotModeLoaded,
                        suppressMonetizationUpsell: screenshotModeLoaded
                    )
                    #else
                    HomeView(
                        documents: documents,
                        onOpenDocument: openDocument,
                        onCreateTemplate: createBoard(from:),
                        onCreateTemplateWithTitle: createBoard(from:title:),
                        onCreateBlankBoardWithTitle: createBlankBoard(title:),
                        onNewWorkspace: presentNewBoardSheet,
                        onDuplicate: duplicateBoard,
                        onRename: beginRename,
                        onDelete: deleteBoard,
                        onToggleFavorite: toggleFavorite,
                        onExport: exportBoard
                    )
                    #endif
                } else if isFocusModeEnabled {
                    detailContent
                        .transition(.opacity.combined(with: .scale(scale: 0.996)))
                } else {
                    NavigationSplitView {
                        DocumentSidebarView(
                            documents: documents,
                            selection: $selection,
                            onNewBoard: presentNewBoardSheet,
                            onOpenTemplates: { route = .home },
                            onDelete: deleteBoards,
                            onRenameRequest: beginRename
                        )
                        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
                    } detail: {
                        detailContent
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.996)))
                }
            }
            if isCommandPalettePresented {
                CommandPaletteView(
                    isPresented: $isCommandPalettePresented,
                    commands: commandPaletteCommands
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(20)
            }

            if let creationSuccessMessage {
                creationSuccessBanner(message: creationSuccessMessage)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(40)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.992)))
        .animation(FlowDeskMotion.canvasEnter, value: route)
        .animation(FlowDeskMotion.quickEaseOut, value: isCommandPalettePresented)
        .animation(.easeInOut(duration: 0.2), value: isFocusModeEnabled)
        .toolbarBackground(.visible, for: .windowToolbar)
        .toolbar(isFocusModeEnabled ? .hidden : .visible, for: .windowToolbar)
        .flowDeskToolbarChrome(appearanceTokens)
        .environment(\.flowDeskTokens, appearanceTokens)
        .onAppear {
            documentListViewModel.attach(modelContext: modelContext)
            syncCanvasAttachment()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskBoardUndo)) { _ in
            canvasBoardViewModel.undoBoard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskBoardRedo)) { _ in
            canvasBoardViewModel.redoBoard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskOpenCommandPalette)) { _ in
            isCommandPalettePresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskToggleFocusMode)) { _ in
            guard route == .editor else { return }
            isFocusModeEnabled.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskExitFocusMode)) { _ in
            isFocusModeEnabled = false
        }
        .onChange(of: selection?.persistentModelID) { _, _ in
            canvasSelection.clear()
            syncCanvasAttachment()
            if selection == nil { route = .home }
            #if DEBUG
            applyScreenshotEditorPresentationIfNeeded()
            #endif
        }
        // SwiftData refresh can replace model instances; keep the sidebar binding and canvas on the same live object.
        .onChange(of: documents) { _, newDocuments in
            guard let current = selection else { return }
            guard let fresh = newDocuments.first(where: { $0.persistentModelID == current.persistentModelID }) else {
                selection = nil
                canvasSelection.clear()
                syncCanvasAttachment()
                route = .home
                return
            }
            if fresh !== current {
                selection = fresh
                syncCanvasAttachment()
            }
        }
        .sheet(item: $renameSession) { session in
            RenameDocumentSheet(
                title: $renameDraft,
                onCancel: { renameSession = nil },
                onSave: {
                    documentListViewModel.rename(session.document, to: renameDraft)
                    renameSession = nil
                }
            )
            .flowDeskModalEntrance()
        }
        .sheet(isPresented: $isNewBoardSheetPresented) {
            NewBoardSheetView(
                onCancel: { isNewBoardSheetPresented = false },
                onCreate: createBoard(from:)
            )
            .flowDeskModalEntrance()
        }
        .sheet(isPresented: paywallPresentedBinding) {
            ProPaywallSheet(purchaseManager: purchaseManager)
                .flowDeskModalEntrance()
        }
        .alert("InkNoMi Pro", isPresented: purchaseMessageBinding) {
            Button("OK", role: .cancel) {
                purchaseManager.purchaseMessage = nil
            }
        } message: {
            Text(purchaseManager.purchaseMessage ?? "")
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let doc = selection {
            HSplitView {
                CanvasScreenView(
                    document: doc,
                    boardViewModel: canvasBoardViewModel,
                    selection: canvasSelection,
                    isFocusModeEnabled: isFocusModeEnabled,
                    screenshotPolishMode: isScreenshotModeActive,
                    onBackHome: { route = .home }
                )
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                if shouldShowInspector && !isFocusModeEnabled {
                    InspectorPanelView(
                        document: doc,
                        canvasViewModel: canvasBoardViewModel,
                        selection: canvasSelection
                    )
                    .frame(minWidth: 176, idealWidth: 236, maxWidth: 304)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: shouldShowInspector && !isFocusModeEnabled)
            // Fresh SwiftUI identity per document so canvas/inspector never show stale content.
            .id(doc.persistentModelID)
            .onAppear {
                syncCanvasAttachment()
            }
        } else {
            ContentUnavailableView("No Canvas Selected", systemImage: "square.dashed")
        }
    }

    private func createBoard() {
        let isFirstBoard = documents.isEmpty
        guard let doc = documentListViewModel.createBoard(from: .blankBoard, isProUser: purchaseManager.isProUser) else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_create_blank")
            }
            return
        }
        openDocument(doc)
        if isFirstBoard {
            showCreationSuccess("First board ready")
        }
    }

    private func presentNewBoardSheet() {
        isNewBoardSheetPresented = true
    }

    private func createBoard(from template: WorkspaceTemplate) {
        let isFirstBoard = documents.isEmpty
        if template.isProTemplate, !isScreenshotModeActive, !featureGate.requirePro(.advancedTemplates, source: "template_\(template.id)") {
            return
        }
        guard let doc = documentListViewModel.createBoard(from: template, isProUser: purchaseManager.isProUser) else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_create_template")
            }
            return
        }
        openDocument(doc)
        showCreationSuccess(isFirstBoard ? "First board ready" : "Board created")
    }

    private func createBoard(from template: WorkspaceTemplate, title: String) {
        let isFirstBoard = documents.isEmpty
        if template.isProTemplate, !isScreenshotModeActive, !featureGate.requirePro(.advancedTemplates, source: "template_\(template.id)") {
            return
        }
        guard let doc = documentListViewModel.createBoard(
            from: template,
            customTitle: title,
            isProUser: purchaseManager.isProUser
        ) else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_create_template")
            }
            return
        }
        openDocument(doc)
        showCreationSuccess(isFirstBoard ? "First board ready" : "Board created")
    }

    private func createBlankBoard(title: String) {
        let isFirstBoard = documents.isEmpty
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let doc = documentListViewModel.createBoard(
            from: .blankBoard,
            customTitle: trimmedTitle,
            isProUser: purchaseManager.isProUser
        ) else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_create_blank")
            }
            return
        }
        openDocument(doc)
        showCreationSuccess(isFirstBoard ? "First board ready" : "Board created")
    }

    private func createBoard(from draft: NewBoardDraft) {
        let isFirstBoard = documents.isEmpty
        let customTitle = draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled \(draft.boardType.displayName)"
            : draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        let created: FlowDocument?
        if draft.startMode == .template,
           let templateID = draft.selectedTemplateID,
           let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
            if template.isProTemplate, !isScreenshotModeActive, !featureGate.requirePro(.advancedTemplates, source: "new_board_sheet_template_\(template.id)") {
                return
            }
            created = documentListViewModel.createBoard(
                from: template,
                customTitle: customTitle,
                isProUser: purchaseManager.isProUser
            )
        } else {
            let baseTemplate = baseTemplate(for: draft.boardType)
            created = documentListViewModel.createBoard(
                from: baseTemplate,
                customTitle: customTitle,
                isProUser: purchaseManager.isProUser
            )
        }

        guard let doc = created else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_create_sheet")
            }
            return
        }

        applyBackgroundStyle(draft.backgroundStyle, to: doc)
        isNewBoardSheetPresented = false
        openDocument(doc)
        showCreationSuccess(isFirstBoard ? "First board ready" : "Board created")
    }

    private func openDocument(_ document: FlowDocument) {
        withAnimation(FlowDeskMotion.canvasEnter) {
            selection = document
            route = .editor
        }
    }

    private func duplicateBoard(_ document: FlowDocument) {
        guard let dup = documentListViewModel.duplicate(document, isProUser: purchaseManager.isProUser) else {
            if documentListViewModel.boardCreationRequiresPro && !isScreenshotModeActive {
                _ = featureGate.requirePro(.unlimitedBoards, source: "board_duplicate")
            }
            return
        }
        openDocument(dup)
    }

    private func deleteBoard(_ document: FlowDocument) {
        if selection?.persistentModelID == document.persistentModelID {
            selection = nil
            route = .home
        }
        documentListViewModel.delete(document)
    }

    private func toggleFavorite(_ document: FlowDocument) {
        documentListViewModel.toggleFavorite(document)
    }

    private func exportBoard(_ document: FlowDocument) {
        let boardState = CanvasBoardCoding.decode(from: document.canvasPayload)
        CanvasExportService.presentExportPanel(
            boardState: boardState,
            documentTitle: document.title,
            format: .png
        )
    }

    private func deleteBoards(at offsets: IndexSet) {
        for index in offsets {
            let doc = documents[index]
            if selection?.persistentModelID == doc.persistentModelID {
                selection = nil
            }
            documentListViewModel.delete(doc)
        }
    }

    private func beginRename(_ document: FlowDocument) {
        renameDraft = document.title
        renameSession = RenameSession(document: document)
    }

    private func syncCanvasAttachment() {
        if let doc = selection {
            canvasBoardViewModel.attach(document: doc, modelContext: modelContext)
        } else {
            canvasBoardViewModel.detach()
        }
    }

    private func baseTemplate(for boardType: BoardType) -> FlowDeskBoardTemplate {
        switch boardType {
        case .flowchart:
            return .flowDiagram
        case .notes:
            return .document
        case .whiteboard, .roadmap, .mindMap, .kanban, .diagram:
            return .blankBoard
        }
    }

    private func applyBackgroundStyle(_ style: NewBoardDraft.BackgroundStyle, to document: FlowDocument) {
        var state = CanvasBoardCoding.decode(from: document.canvasPayload)
        switch style {
        case .classicGrid:
            state.viewport.showGrid = true
            state.viewport.scale = 1
        case .minimal:
            state.viewport.showGrid = false
            state.viewport.scale = 1
        case .focus:
            state.viewport.showGrid = false
            state.viewport.scale = 1.08
        }
        document.canvasPayload = CanvasBoardCoding.encode(state)
        document.markUpdated()
        try? modelContext.save()
    }

    private var shouldShowInspector: Bool {
        #if DEBUG
        if screenshotModeLoaded { return false }
        #endif
        canvasSelection.hasSelection || canvasBoardViewModel.canvasTool == .pen || canvasBoardViewModel.canvasTool == .pencil
    }

    private var commandPaletteCommands: [CommandPaletteCommand] {
        [
            CommandPaletteCommand(
                id: "new_blank_canvas",
                title: "New Blank Canvas",
                icon: "plus.square.on.square",
                shortcut: "Cmd N",
                category: "Board",
                handler: createBoard
            ),
            CommandPaletteCommand(
                id: "open_templates",
                title: "Open Templates",
                icon: "square.grid.2x2",
                shortcut: "",
                category: "Board",
                handler: { route = .home }
            ),
            CommandPaletteCommand(
                id: "search_boards",
                title: "Search Boards",
                icon: "magnifyingglass",
                shortcut: "",
                category: "Board",
                handler: { route = .home }
            ),
            CommandPaletteCommand(
                id: "toggle_grid",
                title: "Toggle Grid",
                icon: "grid",
                shortcut: "G",
                category: "View",
                handler: {
                    guard route == .editor else { return }
                    canvasBoardViewModel.toggleViewportShowGrid()
                }
            ),
            CommandPaletteCommand(
                id: "toggle_focus_mode",
                title: isFocusModeEnabled ? "Exit Focus Mode" : "Enter Focus Mode",
                icon: isFocusModeEnabled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                shortcut: "Cmd Shift F",
                category: "View",
                handler: {
                    guard route == .editor else { return }
                    isFocusModeEnabled.toggle()
                }
            ),
            CommandPaletteCommand(
                id: "export_png",
                title: "Export PNG",
                icon: "photo",
                shortcut: "",
                category: "Export",
                handler: { exportCurrentBoard(as: .png) }
            ),
            CommandPaletteCommand(
                id: "export_pdf",
                title: "Export PDF",
                icon: "doc.richtext",
                shortcut: "",
                category: "Export",
                handler: { exportCurrentBoard(as: .pdf) }
            ),
            CommandPaletteCommand(
                id: "appearance_settings",
                title: "Open Appearance Settings",
                icon: "paintbrush",
                shortcut: "Cmd ,",
                category: "Appearance",
                handler: openAppearanceSettings
            ),
            CommandPaletteCommand(
                id: "theme_miro",
                title: "Switch Theme: Miro Bright",
                icon: "sun.max",
                shortcut: "",
                category: "Appearance",
                handler: {
                    appearanceStore.settings.visualTheme = .miroBright
                }
            ),
            CommandPaletteCommand(
                id: "theme_graphite",
                title: "Switch Theme: Graphite",
                icon: "moon.stars",
                shortcut: "",
                category: "Appearance",
                handler: {
                    appearanceStore.settings.visualTheme = .linearGraphite
                }
            ),
            CommandPaletteCommand(
                id: "tool_select",
                title: "Select Tool",
                icon: "cursorarrow",
                shortcut: "V",
                category: "Tools",
                handler: {
                    applyToolIfEditor(.select)
                }
            ),
            CommandPaletteCommand(
                id: "tool_pen",
                title: "Pen Tool",
                icon: "pencil.tip",
                shortcut: "P",
                category: "Tools",
                handler: {
                    applyToolIfEditor(.pen)
                }
            ),
            CommandPaletteCommand(
                id: "tool_text",
                title: "Text Tool",
                icon: "textformat",
                shortcut: "T",
                category: "Tools",
                handler: {
                    applyToolIfEditor(.text)
                }
            ),
            CommandPaletteCommand(
                id: "tool_shape",
                title: "Shape Tool",
                icon: "square.on.circle",
                shortcut: "R",
                category: "Tools",
                handler: {
                    applyToolIfEditor(.shape)
                }
            )
        ]
    }

    private func applyToolIfEditor(_ tool: CanvasToolMode) {
        guard route == .editor else { return }
        canvasBoardViewModel.applyCanvasToolSelection(tool, fromKeyboard: true, rectanglePlacementShape: tool == .shape)
    }

    private func exportCurrentBoard(as format: CanvasExportService.ExportFormat) {
        guard route == .editor, let document = selection else { return }
        let renderScale: CGFloat
        if featureGate.canUse(.highResExport) {
            renderScale = PurchaseManager.proExportScale
        } else {
            _ = featureGate.requirePro(.highResExport, source: "home_export")
            renderScale = PurchaseManager.freeExportScale
        }
        CanvasExportService.presentExportPanel(
            boardState: canvasBoardViewModel.boardState,
            documentTitle: document.title,
            format: format,
            renderScale: renderScale
        )
    }

    private func openAppearanceSettings() {
        #if os(macOS)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        #endif
    }

    private var paywallPresentedBinding: Binding<Bool> {
        Binding(
            get: {
                #if DEBUG
                if screenshotModeLoaded { return false }
                #endif
                return purchaseManager.isPaywallPresented
            },
            set: { newValue in
                #if DEBUG
                if screenshotModeLoaded {
                    purchaseManager.isPaywallPresented = false
                    return
                }
                #endif
                purchaseManager.isPaywallPresented = newValue
            }
        )
    }

    private var purchaseMessageBinding: Binding<Bool> {
        Binding(
            get: {
                #if DEBUG
                if screenshotModeLoaded { return false }
                #endif
                return purchaseManager.purchaseMessage != nil
            },
            set: { newValue in
                if !newValue { purchaseManager.purchaseMessage = nil }
            }
        )
    }

    private func showCreationSuccess(_ message: String) {
        creationSuccessTask?.cancel()
        withAnimation(FlowDeskMotion.quickEaseOut) {
            creationSuccessMessage = message
        }

        creationSuccessTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(FlowDeskMotion.quickEaseOut) {
                creationSuccessMessage = nil
            }
        }
    }

    private func creationSuccessBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.green.opacity(0.9))
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    #if DEBUG
    private func loadScreenshotDemoData(scene: ScreenshotModeService.Scene) {
        let service = ScreenshotModeService(modelContext: modelContext)
        let result = service.loadDemoData(scene: scene, appAppearance: appearanceStore)
        screenshotModeLoaded = true
        purchaseManager.isPaywallPresented = false
        purchaseManager.requestedFeature = nil
        purchaseManager.paywallSource = nil
        if scene == .homeTemplates {
            selection = nil
            route = .home
            return
        }
        if let primary = result.primaryDocument {
            screenshotFocusDocumentID = primary.persistentModelID
            openDocument(primary)
        } else {
            route = .home
        }
    }

    private func applyScreenshotEditorPresentationIfNeeded() {
        guard screenshotModeLoaded else { return }
        guard let selected = selection else { return }
        guard screenshotFocusDocumentID == selected.persistentModelID else { return }

        // Keep the editor ready for polished screenshots: centered content and tool palette visible.
        boardViewModelPrepareForScreenshot()
        screenshotFocusDocumentID = nil
    }

    private func boardViewModelPrepareForScreenshot() {
        canvasBoardViewModel.selectCanvasTool(.select)
        canvasBoardViewModel.fitViewportToBoardContent(canvasMargin: 140)
        canvasBoardViewModel.centerViewportOnBoardContent(canvasMargin: 120)
    }
    #endif
}

/// Stable sheet identity without relying on `FlowDocument` `Identifiable` synthesis details.
struct RenameSession: Identifiable {
    let id: UUID
    let document: FlowDocument

    init(document: FlowDocument) {
        self.id = document.id
        self.document = document
    }
}
