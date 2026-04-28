import SwiftUI

/// Edit / arrange: duplicate/delete use full selection; stacking (Arrange) stays primary-only in v1.
struct CanvasEditorInspectorSection: View {
    @Bindable var canvasViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    
    private var canShowArrange: Bool {
        selection.primarySelectedID != nil && !selection.isMultiSelection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit")
                .font(FlowDeskTypography.inspectorEyebrow)
                .tracking(0.85)
                .foregroundStyle(DS.Color.textTertiary)

            HStack(spacing: 10) {
                Button("Duplicate") {
                    canvasViewModel.duplicateAllSelectedElements(selection: selection)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!selection.hasSelection)

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    canvasViewModel.deleteSelectedElements(selection: selection)
                } label: {
                    Text("Delete")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!selection.hasSelection)
            }

            if canShowArrange {
                Menu {
                    Button("Bring to Front") {
                        canvasViewModel.bringSelectionToFront(selection: selection)
                    }
                    Button("Bring Forward") {
                        canvasViewModel.bringSelectionForward(selection: selection)
                    }
                    .disabled(!canvasViewModel.canBringSelectionForward(selection: selection))
                    Button("Send Backward") {
                        canvasViewModel.sendSelectionBackward(selection: selection)
                    }
                    .disabled(!canvasViewModel.canSendSelectionBackward(selection: selection))
                    Button("Send to Back") {
                        canvasViewModel.sendSelectionToBack(selection: selection)
                    }
                } label: {
                    Label("Arrange stacking", systemImage: "square.3.layers.3d")
                }
            }

            if selection.isMultiSelection {
                Text("Use the multi-select toolbar for align/distribute actions.")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }
}
