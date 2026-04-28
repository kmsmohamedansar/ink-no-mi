import SwiftUI

/// Professional vertical tool palette: grouped like Figma’s toolbar — explicit modes, shortcut badges, accent selection.
struct InkNoMiCanvasChromeColumn: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appearanceManager: AppearanceManager

    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    var compactMode: Bool = false
    var screenshotPolishMode: Bool = false
    @State private var hoveredTool: CanvasToolMode?
    @State private var hoveredActionSymbol: String?

    private let rowHeight: CGFloat = 40
    private var shouldReduceMotion: Bool {
        reduceMotion || appearanceManager.settings.motionLevel != .full
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !compactMode {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .flowDeskStandardIcon(size: 15)
                        .foregroundStyle(DS.Color.accent.opacity(0.62))
                    Text("Tools")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                toolGroup("Selection", items: [.select])
                paletteGroupDivider()
                toolGroup("Drawing", items: [.pen, .pencil])
                paletteGroupDivider()
                toolGroup("Content", items: [.text, .stickyNote])
                paletteGroupDivider()
                toolGroup("Structure", items: [.shape, .connect, .chart])
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
                Divider()
                    .opacity(0.18)
                    .padding(.vertical, 2)

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

            Text("H pan · G grid · ? shortcuts")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.md)
        .frame(width: compactMode ? 200 : 236, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Canvas tools")
        .flowDeskFloatingPanelChrome(
            cornerRadius: DS.Radius.large,
            shadowStyle: .toolPalette,
            lightTintOpacity: 0.10,
            darkTintOpacity: 0.08
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.14 : 0.42),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.large - 1, style: .continuous)
                .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), lineWidth: 0.5)
                .padding(1)
                .allowsHitTesting(false)
        }
    }

    private func paletteGroupDivider() -> some View {
        Rectangle()
            .fill(DS.Color.border.opacity(colorScheme == .dark ? 0.35 : 0.22))
            .frame(height: 1)
            .padding(.vertical, 9)
            .padding(.leading, 4)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)
                .tracking(0.85)
                .padding(.leading, 6)
                .padding(.bottom, 3)
            ForEach(items, id: \.self) { mode in
                if let item = toolItems.first(where: { $0.mode == mode }) {
                    labeledToolButton(item)
                }
            }
        }
    }

    private func shortcutBadgeText(for mode: CanvasToolMode) -> String? {
        switch mode {
        case .select: return "V"
        case .pen: return "P"
        case .pencil: return "B"
        case .text: return "T"
        case .stickyNote: return "N"
        case .shape: return "R"
        case .connect: return "K"
        case .chart: return "—"
        case .smartInk: return nil
        }
    }

    private func labeledToolButton(_ item: ToolItem) -> some View {
        let active = boardViewModel.canvasTool == item.mode
        let hovered = hoveredTool == item.mode
        let badge = shortcutBadgeText(for: item.mode)
        let activeBackground = LinearGradient(
            colors: [
                DS.Color.accent.opacity(colorScheme == .dark ? 0.94 : 0.9),
                DS.Color.accent.opacity(colorScheme == .dark ? 0.82 : 0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return Button {
            guard item.enabled else { return }
            boardViewModel.applyCanvasToolSelection(item.mode, fromKeyboard: false)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .flowDeskStandardIcon(size: 17)
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(active ? Color.white.opacity(0.995) : DS.Color.textPrimary.opacity(0.88))

                Text(item.label)
                    .font(.system(size: 13, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? Color.white.opacity(0.99) : DS.Color.textPrimary.opacity(0.86))
                    .lineLimit(1)

                if !item.enabled && !screenshotPolishMode {
                    Text("Soon")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(active ? Color.white.opacity(0.7) : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(active ? Color.white.opacity(0.15) : Color.primary.opacity(0.08))
                        )
                }

                Spacer(minLength: 4)

                if let badge, item.enabled || screenshotPolishMode {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            active
                                ? Color.white.opacity(0.62)
                                : Color.secondary.opacity(colorScheme == .dark ? 0.82 : 0.78)
                        )
                        .frame(minWidth: 18, alignment: .trailing)
                }
            }
            .frame(height: rowHeight)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(active ? AnyShapeStyle(activeBackground) : AnyShapeStyle(hovered ? DS.Color.accent.opacity(colorScheme == .dark ? 0.14 : 0.09) : Color.clear))
            }
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.28 : 0.34), lineWidth: 0.65)
                        .blendMode(.overlay)
                }
            }
            .shadow(
                color: active
                    ? DS.Color.accent.opacity(colorScheme == .dark ? 0.5 : 0.4)
                    : (hovered ? Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10) : .clear),
                radius: active ? 14 : (hovered ? 6 : 0),
                x: 0,
                y: active ? 5 : (hovered ? 2 : 0)
            )
            .shadow(
                color: active ? Color.white.opacity(colorScheme == .dark ? 0.12 : 0.16) : .clear,
                radius: active ? 6 : 0,
                x: 0,
                y: -1
            )
            .scaleEffect(shouldReduceMotion ? 1 : (hovered && !active ? 1.02 : 1.0))
        }
        .buttonStyle(CanvasToolButtonStyle(isActive: active, isHovered: hovered))
        .help(tooltip(for: item))
        .frame(minHeight: 40)
        .focusable(true)
        .accessibilityLabel("\(item.label) tool")
        .onHover { inside in
            withAnimation(FlowDeskMotion.hoverEase) {
                hoveredTool = inside ? item.mode : nil
            }
        }
        .animation(shouldReduceMotion ? nil : FlowDeskMotion.fastEaseOut, value: active)
        .animation(shouldReduceMotion ? nil : FlowDeskMotion.hoverEase, value: hovered)
        .opacity(item.enabled ? 1 : (screenshotPolishMode ? 0.88 : 0.55))
        .disabled(!item.enabled)
    }

    private func compactActionButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let hovered = hoveredActionSymbol == symbol
        return Button(action: action) {
            Image(systemName: symbol)
                .flowDeskStandardIcon()
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(hovered ? DS.Color.hover.opacity(0.86) : .clear)
                )
                .brightness(hovered ? 0.015 : 0)
                .offset(y: shouldReduceMotion ? 0 : (hovered ? -0.5 : 0))
                .scaleEffect(shouldReduceMotion ? 1 : (hovered ? 1.02 : 1))
        }
        .buttonStyle(.plain)
        .help(symbol == "arrow.uturn.backward" ? "Undo (Cmd+Z)" : "Redo (Cmd+Shift+Z)")
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.45))
        .focusable(true)
        .accessibilityLabel(symbol == "arrow.uturn.backward" ? "Undo" : "Redo")
        .disabled(!enabled)
        .onHover { inside in
            withAnimation(FlowDeskMotion.hoverEase) {
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
                    .flowDeskStandardIcon()
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
        case .select: return "Click an item to select. Drag to move."
        case .connect: return "Drag from a connector handle to link objects."
        case .pen: return "Click and drag to draw."
        case .pencil: return "Click and drag to sketch softly."
        case .text: return "Click the canvas to place a text block."
        case .stickyNote: return "Click the canvas to place a sticky note."
        case .shape: return "Click or drag to create a shape."
        case .chart: return "Click the canvas to insert a chart."
        case .smartInk: return "Select ink, then convert from the toolbar."
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
            .scaleEffect(configuration.isPressed ? DS.Interaction.pressScale : (isHovered ? 1.02 : (isActive ? 1.002 : 1.0)))
            .animation(configuration.isPressed ? FlowDeskMotion.uiPressDown : FlowDeskMotion.uiPressRelease, value: configuration.isPressed)
            .animation(FlowDeskMotion.hoverEase, value: isHovered)
            .animation(FlowDeskMotion.fastEaseOut, value: isActive)
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
