import SwiftUI

/// Blank-first, labeled vertical tool sidebar for explicit mode control.
struct InkNoMiCanvasChromeColumn: View {
    @Environment(\.flowDeskTokens) private var tokens

    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    var body: some View {
        VStack(alignment: .leading, spacing: FlowDeskLayout.spaceM) {
            VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                ForEach(toolItems, id: \.mode) { item in
                    labeledToolButton(item)
                }
            }

            Divider().opacity(0.18)

            HStack(spacing: FlowDeskLayout.spaceS) {
                compactActionButton(symbol: "arrow.uturn.backward", enabled: boardViewModel.canUndoBoard) {
                    NotificationCenter.default.post(name: .flowDeskBoardUndo, object: nil)
                }
                compactActionButton(symbol: "arrow.uturn.forward", enabled: boardViewModel.canRedoBoard) {
                    NotificationCenter.default.post(name: .flowDeskBoardRedo, object: nil)
                }
            }

            Text(activeToolHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, FlowDeskLayout.canvasChromeLeadingPadding)
        .frame(maxHeight: .infinity, alignment: .center)
        .frame(width: 188, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Canvas tools")
        .flowDeskFloatingPanelChrome(shadowStyle: .toolPalette)
    }

    private var toolItems: [ToolItem] {
        [
            .init(mode: .select, label: "Select", symbol: "cursorarrow"),
            .init(mode: .pen, label: "Pen", symbol: "pencil.tip"),
            .init(mode: .pencil, label: "Pencil", symbol: "pencil"),
            .init(mode: .text, label: "Text", symbol: "textformat"),
            .init(mode: .stickyNote, label: "Note", symbol: "note.text"),
            .init(mode: .shape, label: "Shapes", symbol: "square.on.circle"),
            .init(mode: .chart, label: "Chart", symbol: "chart.bar"),
            .init(mode: .smartInk, label: "Smart Ink", symbol: "sparkles")
        ]
    }

    private func labeledToolButton(_ item: ToolItem) -> some View {
        let active = boardViewModel.canvasTool == item.mode
        return Button {
            boardViewModel.applyCanvasToolSelection(item.mode, fromKeyboard: false)
        } label: {
            HStack(spacing: FlowDeskLayout.spaceS) {
                Image(systemName: item.symbol)
                    .frame(width: 18)
                Text(item.label)
                    .font(.subheadline.weight(active ? .semibold : .regular))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(active ? tokens.selectionStrokeColor : Color.primary.opacity(0.9))
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? tokens.selectionStrokeColor.opacity(0.14) : Color.primary.opacity(0.03))
            }
        }
        .buttonStyle(.plain)
    }

    private func compactActionButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.45))
        .disabled(!enabled)
    }

    private var activeToolHint: String {
        switch boardViewModel.canvasTool {
        case .select: return "Select: move and edit elements"
        case .pen: return "Pen: draw freely"
        case .pencil: return "Pencil: draw lighter strokes"
        case .text: return "Text: click anywhere to type"
        case .stickyNote: return "Note: click to place a blank note"
        case .shape: return "Shapes: click or drag to place shapes"
        case .chart: return "Chart: click to create a chart block"
        case .smartInk: return "Smart Ink: draw handwriting or shapes to convert"
        }
    }
}

private struct ToolItem {
    let mode: CanvasToolMode
    let label: String
    let symbol: String
}
