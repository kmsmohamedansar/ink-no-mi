import SwiftUI

/// Blank-first, labeled vertical tool sidebar for explicit mode control.
struct InkNoMiCanvasChromeColumn: View {
    @Environment(\.flowDeskTokens) private var tokens

    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    @State private var hoveredTool: CanvasToolMode?

    var body: some View {
        VStack(alignment: .leading, spacing: FlowDeskLayout.spaceM) {
            VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                ForEach(toolItems, id: \.mode) { item in
                    labeledToolButton(item)
                }
            }

            if boardViewModel.canvasTool == .shape {
                VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                    Text("Shape")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(shapeOptions, id: \.kind) { option in
                        shapeOptionButton(option)
                    }
                }
                .padding(.top, 2)
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
                .font(.caption.weight(.medium))
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
            .init(mode: .connect, label: "Connect", symbol: "point.3.connected.trianglepath.dotted"),
            .init(mode: .pen, label: "Pen", symbol: "pencil.tip"),
            .init(mode: .pencil, label: "Pencil", symbol: "pencil"),
            .init(mode: .text, label: "Text", symbol: "textformat"),
            .init(mode: .stickyNote, label: "Note", symbol: "note.text"),
            .init(mode: .shape, label: "Shapes", symbol: "square.on.circle"),
            .init(mode: .chart, label: "Chart", symbol: "chart.bar"),
            .init(mode: .smartInk, label: "Smart Ink", symbol: "sparkles", enabled: false)
        ]
    }

    private func labeledToolButton(_ item: ToolItem) -> some View {
        let active = boardViewModel.canvasTool == item.mode
        let hovered = hoveredTool == item.mode
        return Button {
            guard item.enabled else { return }
            boardViewModel.applyCanvasToolSelection(item.mode, fromKeyboard: false)
        } label: {
            HStack(spacing: FlowDeskLayout.spaceS) {
                Image(systemName: item.symbol)
                    .frame(width: 18)
                Text(item.label)
                    .font(.subheadline.weight(active ? .semibold : .regular))
                if !item.enabled {
                    Text("Soon")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(active ? tokens.selectionStrokeColor : Color.primary.opacity(0.84))
            .background {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                    .fill(active ? tokens.selectionStrokeColor.opacity(0.12) : (hovered ? Color.primary.opacity(0.045) : Color.clear))
                    .overlay {
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .strokeBorder(active ? tokens.selectionStrokeColor.opacity(0.28) : Color.primary.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
        .help(tooltip(for: item))
        .onHover { inside in
            hoveredTool = inside ? item.mode : nil
        }
        .animation(.easeOut(duration: 0.10), value: active)
        .animation(.easeOut(duration: 0.10), value: hovered)
        .opacity(item.enabled ? 1 : 0.55)
        .disabled(!item.enabled)
    }

    private func compactActionButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .help(symbol == "arrow.uturn.backward" ? "Undo (Cmd+Z)" : "Redo (Cmd+Shift+Z)")
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.45))
        .disabled(!enabled)
    }

    private var shapeOptions: [ShapeOption] {
        [
            .init(kind: .rectangle, label: "Rectangle", symbol: "square"),
            .init(kind: .roundedRectangle, label: "Rounded", symbol: "square.roundedbottom"),
            .init(kind: .ellipse, label: "Oval", symbol: "circle"),
            .init(kind: .line, label: "Line", symbol: "line.diagonal"),
            .init(kind: .arrow, label: "Arrow", symbol: "arrow.right")
        ]
    }

    private func shapeOptionButton(_ option: ShapeOption) -> some View {
        let active = boardViewModel.placeShapeKind == option.kind
        return Button {
            boardViewModel.placeShapeKind = option.kind
        } label: {
            HStack(spacing: FlowDeskLayout.spaceS) {
                Image(systemName: option.symbol)
                    .frame(width: 16)
                Text(option.label)
                    .font(.caption)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                    .fill(active ? tokens.selectionStrokeColor.opacity(0.12) : Color.primary.opacity(0.03))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? tokens.selectionStrokeColor : Color.primary.opacity(0.85))
    }

    private var activeToolHint: String {
        switch boardViewModel.canvasTool {
        case .select: return "Select: move and edit elements"
        case .connect: return "Connect: drag from one note to another"
        case .pen: return "Pen: draw freely"
        case .pencil: return "Pencil: draw lighter strokes"
        case .text: return "Text: click anywhere to type"
        case .stickyNote: return "Note: click to place a blank note"
        case .shape: return "Shapes: click or drag to place shapes"
        case .chart: return "Chart: click to create a chart block"
        case .smartInk: return "Smart Ink: coming soon"
        }
    }

    private func tooltip(for mode: CanvasToolMode) -> String {
        tooltip(for: ToolItem(mode: mode, label: "", symbol: ""))
    }

    private func tooltip(for item: ToolItem) -> String {
        guard item.enabled else { return "Coming soon" }
        let mode = item.mode
        switch mode {
        case .select: return "Select (V)"
        case .connect: return "Connect sticky notes"
        case .pen: return "Pen (P)"
        case .pencil: return "Pencil (B)"
        case .text: return "Text (T)"
        case .stickyNote: return "Sticky Note (N)"
        case .shape: return "Shapes (R)"
        case .chart: return "Chart"
        case .smartInk: return "Smart Ink (Coming Soon)"
        }
    }
}

private struct ToolItem {
    let mode: CanvasToolMode
    let label: String
    let symbol: String
    var enabled: Bool = true
}

private struct ShapeOption {
    let kind: FlowDeskShapeKind
    let label: String
    let symbol: String
}
