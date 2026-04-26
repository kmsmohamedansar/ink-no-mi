import SwiftUI

struct InspectorPanelView: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(PurchaseManager.self) private var purchaseManager

    @Bindable var document: FlowDocument
    @Bindable var canvasViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Zoom") {
                    Text(String(format: "%.0f%%", canvasViewModel.boardState.viewport.scale * 100))
                        .monospacedDigit()
                }
                Toggle("Show grid", isOn: gridBinding)
                    .tint(tokens.selectionStrokeColor)
            } header: {
                FlowDeskInspectorSectionHeader("Canvas")
            } footer: {
                if !selection.hasSelection {
                    Text("Select any element to edit contextual properties.")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            if selection.hasSelection || selection.isMultiSelection {
                Section {
                if let id = selection.primarySelectedID,
                   let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }) {
                    LabeledContent("Kind") {
                        Text(elementKindLabel(element.kind))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    LabeledContent("Frame") {
                        Text("\(Int(element.x)), \(Int(element.y)) · \(Int(element.width))×\(Int(element.height))")
                            .font(DS.Typography.caption.monospacedDigit())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    LabeledContent("Stack") {
                        Text("\(element.zIndex)")
                            .foregroundStyle(DS.Color.textSecondary)
                            .monospacedDigit()
                    }
                } else if selection.isMultiSelection {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(selection.selectedElementIDs.count) items selected")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Text("Shift-click to add or remove. Drag any selected framed item to move the group together.")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                } header: {
                    FlowDeskInspectorSectionHeader("Selection")
                }
            }

            if selection.hasSelection {
                CanvasEditorInspectorSection(canvasViewModel: canvasViewModel, selection: selection)
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nothing selected")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Use Select to pick an element, or choose a tool on the left to create new content.")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    FlowDeskInspectorSectionHeader("Inspector")
                }
            }

            if selectedStrokeCount > 0 {
                Section {
                    Menu("Convert") {
                        Button("Convert to Diagram") {
                            guard purchaseManager.requirePro(for: .convertDiagram) else { return }
                            canvasViewModel.convertSelectedStrokesToDiagram(selection: selection)
                        }
                        Button("Convert to Shape") {
                            guard purchaseManager.requirePro(for: .smartConvert) else { return }
                            canvasViewModel.convertSelectedStrokesToShape(selection: selection)
                        }
                        Button("Convert to Text") {
                            guard purchaseManager.requirePro(for: .smartConvert) else { return }
                            canvasViewModel.convertSelectedStrokesToText(selection: selection)
                        }
                    }
                } header: {
                    FlowDeskInspectorSectionHeader("Smart Convert")
                }
            }

            if selectedStickyCount >= 2 {
                Section {
                    Button("Switch to Connect Tool") {
                        canvasViewModel.applyCanvasToolSelection(.connect, fromKeyboard: false)
                    }
                    Menu("Organize") {
                        Button("Tree Layout") {
                            guard purchaseManager.requirePro(for: .mindMapAutoLayout) else { return }
                            canvasViewModel.organizeSelectedStickyNotesAsTree(selection: selection)
                        }
                        Button("Radial Layout") {
                            guard purchaseManager.requirePro(for: .mindMapAutoLayout) else { return }
                            canvasViewModel.organizeSelectedStickyNotesRadially(selection: selection)
                        }
                    }
                    Button("Group into Cluster") {
                        canvasViewModel.clusterSelectedStickyNotes(selection: selection)
                    }
                } header: {
                    FlowDeskInspectorSectionHeader("Mind Map")
                }
            }

            if let id = selection.primarySelectedID,
               let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }),
               element.kind == .textBlock {
                TextBlockInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
            }

            if let id = selection.primarySelectedID,
               let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }),
               element.kind == .stickyNote {
                StickyNoteInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
            }

            if let id = selection.primarySelectedID,
               let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }),
               element.kind == .shape {
                ShapeInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
            }

            if canvasViewModel.canvasTool == .pen || canvasViewModel.canvasTool == .pencil {
                DrawingToolInspectorSection(canvasViewModel: canvasViewModel)
            }

            if let id = selection.primarySelectedID,
               let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }),
               element.kind == .stroke {
                StrokeInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
            }

            if let id = selection.primarySelectedID,
               let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }),
               element.kind == .chart {
                ChartInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        tokens.inspectorChromeBackground.opacity(colorScheme == .dark ? 0.96 : 0.98),
                        DS.Color.surfaceFloatingBottom.opacity(colorScheme == .dark ? 0.2 : 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                FlowDeskTheme.homeAtmosphereWash(colorScheme: colorScheme)
                    .opacity(colorScheme == .dark ? 0.35 : 0.22)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.088 : 0.032))
                .frame(width: 1)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, FlowDeskLayout.inspectorHorizontalPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func elementKindLabel(_ kind: CanvasElementKind) -> String {
        switch kind {
        case .textBlock: return "Text"
        case .stickyNote: return "Sticky note"
        case .shape: return "Shape"
        case .stroke: return "Drawing"
        case .chart: return "Chart"
        case .connector: return "Connector"
        @unknown default: return "Element"
        }
    }

    private var gridBinding: Binding<Bool> {
        Binding(
            get: { canvasViewModel.boardState.viewport.showGrid },
            set: { newValue in
                var viewport = canvasViewModel.boardState.viewport
                viewport.showGrid = newValue
                canvasViewModel.setViewport(viewport)
            }
        )
    }

    private var selectedStrokeCount: Int {
        canvasViewModel.boardState.elements.filter {
            selection.selectedElementIDs.contains($0.id) && $0.kind == .stroke
        }.count
    }

    private var selectedStickyCount: Int {
        canvasViewModel.boardState.elements.filter {
            selection.selectedElementIDs.contains($0.id) && $0.kind == .stickyNote
        }.count
    }
}
