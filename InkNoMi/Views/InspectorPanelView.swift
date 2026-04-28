import SwiftUI

struct InspectorPanelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(PurchaseManager.self) private var purchaseManager

    /// Retained so the inspector stays scoped to the open board (identity / future hooks).
    let document: FlowDocument
    @Bindable var canvasViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    private var featureGate: FeatureGate {
        FeatureGate(purchaseManager: purchaseManager)
    }

    /// Tool / stroke / visual properties — canvas chrome + drawing tool.
    private var appearanceSectionVisible: Bool {
        if canvasViewModel.canvasTool == .pen || canvasViewModel.canvasTool == .pencil {
            return true
        }
        guard selection.hasSelection || selection.isMultiSelection else { return false }
        return primarySelectedKindSupportsAppearanceInspector
    }

    private var primarySelectedKindSupportsAppearanceInspector: Bool {
        guard let id = selection.primarySelectedID,
              let element = canvasViewModel.boardState.elements.first(where: { $0.id == id })
        else { return false }
        switch element.kind {
        case .textBlock, .stickyNote, .shape, .stroke, .chart:
            return true
        case .connector:
            return false
        @unknown default:
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InspectorSectionCard(title: "Canvas") {
                    VStack(alignment: .leading, spacing: 16) {
                        InspectorLabeledSlider(
                            title: "Zoom",
                            value: zoomBinding,
                            range: 0.25 ... 4,
                            step: 0.01,
                            valueLabel: "\(Int(canvasViewModel.boardState.viewport.scale * 100))%"
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grid")
                                .font(FlowDeskTypography.inspectorLabel)
                                .foregroundStyle(DS.Color.textSecondary)
                            Picker("", selection: gridBinding) {
                                Text("Hidden").tag(false)
                                Text("Visible").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }
                .transition(panelSectionTransition)

                InspectorSectionCard(title: "Selection") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !selection.hasSelection && !selection.isMultiSelection {
                            InspectorEmptySelectionPlaceholder()
                        } else if let id = selection.primarySelectedID,
                                  let element = canvasViewModel.boardState.elements.first(where: { $0.id == id }) {
                            inspectorMetricRow(label: "Type", value: elementKindLabel(element.kind))
                            inspectorMetricRow(
                                label: "Position & size",
                                value: "\(Int(element.x)), \(Int(element.y)) · \(Int(element.width))×\(Int(element.height))"
                            )
                            inspectorMetricRow(label: "Layer", value: "\(element.zIndex)")

                            InspectorSubsectionCard {
                                CanvasEditorInspectorSection(canvasViewModel: canvasViewModel, selection: selection)
                            }

                            if selectedStrokeCount > 0 {
                                InspectorSubsectionCard {
                                    Menu {
                                        Button("Convert to Diagram") {
                                            guard featureGate.requirePro(.smartConvert, source: "inspector_convert_diagram") else { return }
                                            canvasViewModel.convertSelectedStrokesToDiagram(selection: selection)
                                        }
                                        Button("Convert to Shape") {
                                            guard featureGate.requirePro(.smartConvert, source: "inspector_convert_shape") else { return }
                                            canvasViewModel.convertSelectedStrokesToShape(selection: selection)
                                        }
                                        Button("Convert to Text") {
                                            guard featureGate.requirePro(.smartConvert, source: "inspector_convert_text") else { return }
                                            canvasViewModel.convertSelectedStrokesToText(selection: selection)
                                        }
                                    } label: {
                                        Label("Smart Convert", systemImage: "wand.and.stars")
                                            .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .menuStyle(.borderlessButton)
                                }
                            }

                            if selectedStickyCount >= 2 {
                                InspectorSubsectionCard {
                                    stickyOrganizeActions
                                }
                            }
                        } else if selection.isMultiSelection {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(selection.selectedElementIDs.count) items selected")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Shift-click to add or remove. Drag any framed item to move the group.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.Color.textSecondary)

                                InspectorSubsectionCard {
                                    CanvasEditorInspectorSection(canvasViewModel: canvasViewModel, selection: selection)
                                }

                                if selectedStrokeCount > 0 {
                                    InspectorSubsectionCard {
                                        Menu {
                                            Button("Convert to Diagram") {
                                                guard featureGate.requirePro(.smartConvert, source: "inspector_convert_diagram") else { return }
                                                canvasViewModel.convertSelectedStrokesToDiagram(selection: selection)
                                            }
                                            Button("Convert to Shape") {
                                                guard featureGate.requirePro(.smartConvert, source: "inspector_convert_shape") else { return }
                                                canvasViewModel.convertSelectedStrokesToShape(selection: selection)
                                            }
                                            Button("Convert to Text") {
                                                guard featureGate.requirePro(.smartConvert, source: "inspector_convert_text") else { return }
                                                canvasViewModel.convertSelectedStrokesToText(selection: selection)
                                            }
                                        } label: {
                                            Label("Smart Convert", systemImage: "wand.and.stars")
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                if selectedStickyCount >= 2 {
                                    InspectorSubsectionCard {
                                        stickyOrganizeActions
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(panelSectionTransition)

                if appearanceSectionVisible {
                    InspectorSectionCard(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            if canvasViewModel.canvasTool == .pen || canvasViewModel.canvasTool == .pencil {
                                InspectorSubsectionCard {
                                    DrawingToolInspectorSection(canvasViewModel: canvasViewModel)
                                }
                            }

                            if let id = selection.primarySelectedID,
                               canvasViewModel.boardState.elements.first(where: { $0.id == id })?.kind == .textBlock {
                                InspectorSubsectionCard {
                                    TextBlockInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
                                }
                            }

                            if let id = selection.primarySelectedID,
                               canvasViewModel.boardState.elements.first(where: { $0.id == id })?.kind == .stickyNote {
                                InspectorSubsectionCard {
                                    StickyNoteInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
                                }
                            }

                            if let id = selection.primarySelectedID,
                               canvasViewModel.boardState.elements.first(where: { $0.id == id })?.kind == .shape {
                                InspectorSubsectionCard {
                                    ShapeInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
                                }
                            }

                            if let id = selection.primarySelectedID,
                               canvasViewModel.boardState.elements.first(where: { $0.id == id })?.kind == .stroke {
                                InspectorSubsectionCard {
                                    StrokeInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
                                }
                            }

                            if let id = selection.primarySelectedID,
                               canvasViewModel.boardState.elements.first(where: { $0.id == id })?.kind == .chart {
                                InspectorSubsectionCard {
                                    ChartInspectorSection(elementID: id, canvasViewModel: canvasViewModel)
                                }
                            }
                        }
                    }
                    .transition(panelSectionTransition)
                }
            }
            .padding(.bottom, 12)
            .animation(
                FlowDeskMotion.fastEaseOut,
                value: appearanceSectionVisible
            )
            .animation(
                FlowDeskMotion.fastEaseOut,
                value: selection.primarySelectedID
            )
            .animation(
                FlowDeskMotion.fastEaseOut,
                value: selection.selectedElementIDs
            )
            .animation(
                FlowDeskMotion.fastEaseOut,
                value: canvasViewModel.canvasTool
            )
        }
        .scrollIndicators(.hidden)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.45),
                                    Color.black.opacity(colorScheme == .dark ? 0.4 : 0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                        .blendMode(.overlay)
                )
                .flowDeskDepthShadows(FlowDeskDepth.floatingChrome)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 1)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, FlowDeskLayout.inspectorHorizontalPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var stickyOrganizeActions: some View {
        Button {
            canvasViewModel.applyCanvasToolSelection(.connect, fromKeyboard: false)
        } label: {
            Label("Connect tool", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)

        Menu {
            Button("Tree layout") {
                guard featureGate.requirePro(.smartConvert, source: "inspector_mindmap_tree_layout") else { return }
                canvasViewModel.organizeSelectedStickyNotesAsTree(selection: selection)
            }
            Button("Radial layout") {
                guard featureGate.requirePro(.smartConvert, source: "inspector_mindmap_radial_layout") else { return }
                canvasViewModel.organizeSelectedStickyNotesRadially(selection: selection)
            }
        } label: {
            Label("Organize notes", systemImage: "arrow.triangle.branch")
                    .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.borderedButton)

        Button {
            canvasViewModel.clusterSelectedStickyNotes(selection: selection)
        } label: {
            Label("Group into cluster", systemImage: "square.grid.3x3.square.badge.ellipsis")
                    .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }

    private func inspectorMetricRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(FlowDeskTypography.inspectorLabel)
                    .foregroundStyle(DS.Color.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                    .font(FlowDeskTypography.inspectorMetric)
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
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

    private var zoomBinding: Binding<Double> {
        Binding(
            get: { canvasViewModel.boardState.viewport.scale },
            set: { newValue in
                var viewport = canvasViewModel.boardState.viewport
                viewport.scale = min(4, max(0.25, newValue))
                canvasViewModel.setViewport(viewport)
            }
        )
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

    private var panelSectionTransition: AnyTransition {
        .opacity.combined(with: .offset(y: 8))
    }
}
