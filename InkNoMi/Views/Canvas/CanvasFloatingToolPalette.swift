import SwiftUI

/// Blank-first, labeled vertical tool sidebar for explicit mode control.
struct InkNoMiCanvasChromeColumn: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appearanceManager: AppearanceManager

    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    var compactMode: Bool = false
    var screenshotPolishMode: Bool = false
    @State private var hoveredTool: CanvasToolMode?
    @State private var hoveredActionSymbol: String?

    private let rowHeight: CGFloat = 36
    private var shouldReduceMotion: Bool {
        reduceMotion || appearanceManager.settings.motionLevel != .full
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FlowDeskLayout.spaceM) {
            if !compactMode {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary.opacity(0.72))
                    Text("Tools")
                        .font(DS.Typography.label.weight(.medium))
                        .tracking(0.5)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                toolGroup("Selection", items: [.select])
                toolGroup("Drawing", items: [.pen, .pencil])
                toolGroup("Content", items: [.text, .stickyNote])
                toolGroup("Shapes", items: [.shape])
                toolGroup("Connections", items: [.connect])
                toolGroup("Extras", items: [.chart])
            }

            if !compactMode, boardViewModel.canvasTool == .shape {
                VStack(alignment: .leading, spacing: FlowDeskLayout.spaceXS) {
                    Text("Shape")
                        .font(DS.Typography.label.weight(.medium))
                        .foregroundStyle(DS.Color.textSecondary)
                    ForEach(shapeOptions, id: \.kind) { option in
                        shapeOptionButton(option)
                    }
                }
                .padding(.top, 2)
            }

            if !compactMode {
                Divider().opacity(0.18)

                HStack(spacing: FlowDeskLayout.spaceS) {
                    compactActionButton(symbol: "arrow.uturn.backward", enabled: boardViewModel.canUndoBoard) {
                        NotificationCenter.default.post(name: .flowDeskBoardUndo, object: nil)
                    }
                    compactActionButton(symbol: "arrow.uturn.forward", enabled: boardViewModel.canRedoBoard) {
                        NotificationCenter.default.post(name: .flowDeskBoardRedo, object: nil)
                    }
                }

                ZStack(alignment: .leading) {
                    Text(activeToolHint)
                        .id(activeToolHint)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(FlowDeskMotion.standardEaseOut, value: activeToolHint)

            Text("Shortcuts: V Select  ·  H Pan  ·  P Pen  ·  N Note  ·  T Text  ·  R/L/A Shapes")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.md)
        .frame(width: compactMode ? 190 : 216, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Canvas tools")
        .flowDeskFloatingPanelChrome(
            cornerRadius: DS.Radius.large,
            shadowStyle: .toolPalette,
            lightTintOpacity: 0.08,
            darkTintOpacity: 0.07
        )
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
            .init(mode: .chart, label: "Chart", symbol: "chart.bar")
        ]
    }

    @ViewBuilder
    private func toolGroup(_ title: String, items: [CanvasToolMode]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DS.Typography.label.weight(.medium))
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)
                .tracking(0.72)
                .padding(.leading, 8)
            ForEach(items, id: \.self) { mode in
                if let item = toolItems.first(where: { $0.mode == mode }) {
                    labeledToolButton(item)
                }
            }
        }
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
                    .font(.system(size: active ? 20 : 18, weight: active ? .semibold : .medium))
                Text(item.label)
                    .font(DS.Typography.body.weight(active ? .semibold : .regular))
                if !item.enabled && !screenshotPolishMode {
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
            .frame(height: rowHeight)
            .padding(.horizontal, DS.Spacing.md - 2)
            .foregroundStyle(active ? tokens.selectionStrokeColor.opacity(0.98) : DS.Color.textPrimary.opacity(0.68))
            .scaleEffect(shouldReduceMotion ? 1 : (active ? 1.01 : (hovered ? DS.Interaction.hoverScale : 1.0)))
            .brightness(hovered ? 0.016 : 0)
            .offset(x: active ? 1 : 0)
            .offset(y: shouldReduceMotion ? 0 : (hovered ? -0.5 : 0))
            .background {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                    .fill(active ? DS.Color.accent.opacity(0.22) : (hovered ? DS.Color.hover.opacity(0.95) : Color.clear))
                    .overlay {
                        RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                            .strokeBorder(active ? tokens.selectionStrokeColor.opacity(0.56) : DS.Color.border.opacity(1.15), lineWidth: active ? 1.0 : 0.8)
                    }
            }
            .shadow(
                color: active ? Color.black.opacity(0.12) : Color.clear,
                radius: active ? 20 : 0,
                x: 0,
                y: active ? 10 : 0
            )
        }
        .buttonStyle(CanvasToolButtonStyle(isActive: active, isHovered: hovered))
        .help(tooltip(for: item))
        .frame(minHeight: 40)
        .focusable(true)
        .accessibilityLabel("\(item.label) tool")
        .onHover { inside in
            withAnimation(FlowDeskMotion.quickEaseOut) {
                hoveredTool = inside ? item.mode : nil
            }
        }
        .animation(shouldReduceMotion ? nil : FlowDeskMotion.smoothEaseOut, value: active)
        .animation(shouldReduceMotion ? nil : FlowDeskMotion.standardEaseOut, value: hovered)
        .opacity(item.enabled ? 1 : (screenshotPolishMode ? 0.88 : 0.55))
        .disabled(!item.enabled)
    }

    private func compactActionButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let hovered = hoveredActionSymbol == symbol
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(hovered ? DS.Color.hover.opacity(0.86) : .clear)
                )
                .brightness(hovered ? 0.015 : 0)
                .offset(y: shouldReduceMotion ? 0 : (hovered ? -0.5 : 0))
                .scaleEffect(shouldReduceMotion ? 1 : (hovered ? DS.Interaction.hoverScale : 1))
        }
        .buttonStyle(.plain)
        .help(symbol == "arrow.uturn.backward" ? "Undo (Cmd+Z)" : "Redo (Cmd+Shift+Z)")
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.45))
        .focusable(true)
        .accessibilityLabel(symbol == "arrow.uturn.backward" ? "Undo" : "Redo")
        .disabled(!enabled)
        .onHover { inside in
            withAnimation(FlowDeskMotion.quickEaseOut) {
                hoveredActionSymbol = inside ? symbol : nil
            }
        }
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
                    .font(DS.Typography.caption)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .scaleEffect(shouldReduceMotion ? 1 : (active ? 1.01 : 1))
            .background {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeCompactCornerRadius, style: .continuous)
                    .fill(active ? tokens.selectionStrokeColor.opacity(0.12) : Color.primary.opacity(0.04))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? tokens.selectionStrokeColor : Color.primary.opacity(0.85))
        .frame(minHeight: 36)
        .focusable(true)
        .accessibilityLabel("\(option.label) shape")
        .scaleEffect(shouldReduceMotion ? 1 : (active ? 1.01 : 1))
        .animation(shouldReduceMotion ? nil : FlowDeskMotion.standardEaseOut, value: active)
    }

    private var activeToolHint: String {
        switch boardViewModel.canvasTool {
        case .select: return "Select: move, resize, and edit elements"
        case .connect: return "Connect: drag between objects to link"
        case .pen: return "Pen: free drawing with smooth stroke"
        case .pencil: return "Pencil: softer sketching stroke"
        case .text: return "Text: click canvas to insert a text block"
        case .stickyNote: return "Note: click canvas to place a sticky"
        case .shape: return "Shape: click or drag to create clean shapes"
        case .chart: return "Chart: insert and edit chart elements"
        case .smartInk: return "Smart Ink: explicit convert actions only"
        }
    }

    private func tooltip(for mode: CanvasToolMode) -> String {
        tooltip(for: ToolItem(mode: mode, label: "", symbol: ""))
    }

    private func tooltip(for item: ToolItem) -> String {
        guard item.enabled else {
            return screenshotPolishMode ? item.label : "Coming soon"
        }
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
        case .smartInk: return "Smart Ink"
        }
    }
}

private struct CanvasToolButtonStyle: ButtonStyle {
    let isActive: Bool
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : (isHovered ? DS.Interaction.hoverScale : (isActive ? 1.01 : 1.0)))
            .animation(FlowDeskMotion.quickEaseOut, value: configuration.isPressed)
            .animation(FlowDeskMotion.standardEaseOut, value: isHovered)
            .animation(FlowDeskMotion.smoothEaseOut, value: isActive)
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
