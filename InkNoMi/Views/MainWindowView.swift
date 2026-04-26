import SwiftData
import SwiftUI

struct MainWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(FlowDeskAppearanceStore.self) private var appearanceStore
    @Environment(PurchaseManager.self) private var purchaseManager

    @Query(sort: \FlowDocument.updatedAt, order: .reverse)
    private var documents: [FlowDocument]

    @State private var selection: FlowDocument?
    @State private var documentListViewModel = DocumentListViewModel()
    @State private var canvasBoardViewModel = CanvasBoardViewModel()
    @State private var canvasSelection = CanvasSelectionModel()

    @State private var renameSession: RenameSession?
    @State private var renameDraft: String = ""

    private var appearanceTokens: FlowDeskAppearanceTokens {
        FlowDeskAppearanceTokens.resolve(colorScheme: colorScheme, preset: appearanceStore.stylePreset)
    }

    var body: some View {
        NavigationSplitView {
            DocumentSidebarView(
                documents: documents,
                selection: $selection,
                onNewBoard: createBoard,
                onDelete: deleteBoards,
                onRenameRequest: beginRename
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            detailContent
        }
        .toolbarBackground(.visible, for: .windowToolbar)
        .flowDeskToolbarChrome(appearanceTokens)
        .environment(\.flowDeskTokens, appearanceTokens)
        .onAppear {
            documentListViewModel.attach(modelContext: modelContext)
            if selection == nil {
                selection = documents.first ?? documentListViewModel.createUntitledBoard(isProUser: purchaseManager.isProUser)
            }
            syncCanvasAttachment()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskBoardUndo)) { _ in
            canvasBoardViewModel.undoBoard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flowDeskBoardRedo)) { _ in
            canvasBoardViewModel.redoBoard()
        }
        .onChange(of: selection?.persistentModelID) { _, _ in
            canvasSelection.clear()
            syncCanvasAttachment()
        }
        // SwiftData refresh can replace model instances; keep the sidebar binding and canvas on the same live object.
        .onChange(of: documents) { _, newDocuments in
            guard let current = selection else { return }
            guard let fresh = newDocuments.first(where: { $0.persistentModelID == current.persistentModelID }) else {
                selection = nil
                canvasSelection.clear()
                syncCanvasAttachment()
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
        }
        .sheet(isPresented: paywallPresentedBinding) {
            ProPaywallSheet(purchaseManager: purchaseManager)
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
                    selection: canvasSelection
                )
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                if shouldShowInspector {
                    InspectorPanelView(
                        document: doc,
                        canvasViewModel: canvasBoardViewModel,
                        selection: canvasSelection
                    )
                    .frame(minWidth: 176, idealWidth: 236, maxWidth: 304)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        guard let doc = documentListViewModel.createUntitledBoard(isProUser: purchaseManager.isProUser) else {
            if documentListViewModel.boardCreationRequiresPro {
                _ = purchaseManager.requirePro(for: .unlimitedBoards)
            }
            return
        }
        selection = doc
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

    private var shouldShowInspector: Bool {
        canvasSelection.hasSelection || canvasBoardViewModel.canvasTool == .pen || canvasBoardViewModel.canvasTool == .pencil
    }

    private var paywallPresentedBinding: Binding<Bool> {
        Binding(
            get: { purchaseManager.isPaywallPresented },
            set: { purchaseManager.isPaywallPresented = $0 }
        )
    }

    private var purchaseMessageBinding: Binding<Bool> {
        Binding(
            get: { purchaseManager.purchaseMessage != nil },
            set: { newValue in
                if !newValue { purchaseManager.purchaseMessage = nil }
            }
        )
    }
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
