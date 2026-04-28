import SwiftUI

/// Align / distribute for multi-selected framed elements (canvas overlay, view coordinates).
struct CanvasMultiSelectionToolbarView: View {
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: FlowDeskLayout.floatingPanelMultiSelectOuterStackSpacing) {
            Text("ALIGN & DISTRIBUTE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.primary.opacity(0.42))
                .padding(.leading, FlowDeskLayout.spaceXS / 2)

            VStack(alignment: .leading, spacing: FlowDeskLayout.spaceS) {
                actionSection("Align") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            chromeIcon("align.horizontal.left") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .left)
                            }
                            .help("Align left")

                            chromeIcon("align.horizontal.center") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .centerX)
                            }
                            .help("Align horizontal centers")

                            chromeIcon("align.horizontal.right") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .right)
                            }
                            .help("Align right")
                        }

                        HStack(spacing: 4) {
                            chromeIcon("align.vertical.top") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .top)
                            }
                            .help("Align top")

                            chromeIcon("align.vertical.center") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .centerY)
                            }
                            .help("Align vertical centers")

                            chromeIcon("align.vertical.bottom") {
                                boardViewModel.alignSelectedElements(selection: selection, kind: .bottom)
                            }
                            .help("Align bottom")
                        }
                    }
                }

                actionSection("Distribute") {
                    HStack(spacing: 4) {
                        chromeIcon("distribute.horizontal") {
                            boardViewModel.distributeSelectedElements(selection: selection, axis: .horizontal)
                        }
                        .help("Distribute horizontally (3+ items)")

                        chromeIcon("distribute.vertical") {
                            boardViewModel.distributeSelectedElements(selection: selection, axis: .vertical)
                        }
                        .help("Distribute vertically (3+ items)")
                    }
                }
            }
        }
        .padding(.horizontal, FlowDeskLayout.floatingPanelMultiSelectPaddingH)
        .padding(.vertical, FlowDeskLayout.floatingPanelMultiSelectPaddingV)
        .flowDeskFloatingPanelChrome(
            shadowStyle: .contextualToolbar,
            lightTintOpacity: 0.11,
            darkTintOpacity: 0.07
        )
        .fixedSize()
    }

    private func actionSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.45)
                .textCase(.uppercase)
                .foregroundStyle(Color.primary.opacity(0.5))
                .padding(.leading, 2)

            content()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: FlowDeskLayout.chromeInsetCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.035))
        )
    }

    private func chromeIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .flowDeskStandardIcon()
                .frame(width: 30, height: 28)
                .foregroundStyle(Color.primary.opacity(0.76))
                .contentShape(Rectangle())
        }
        .buttonStyle(MultiSelectionToolbarIconButtonStyle())
    }
}

private struct MultiSelectionToolbarIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MultiSelectionChrome(isPressed: configuration.isPressed, label: configuration.label)
    }
}

private struct MultiSelectionChrome<Label: View>: View {
    let isPressed: Bool
    let label: Label

    @Environment(\.flowDeskTokens) private var tokens
    @State private var hovered = false

    var body: some View {
        label
            .background {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeInsetCornerRadius, style: .continuous)
                    .fill(tokens.selectionStrokeColor.opacity(fillOpacity))
            }
            .overlay {
                RoundedRectangle(cornerRadius: FlowDeskLayout.chromeInsetCornerRadius, style: .continuous)
                    .strokeBorder(tokens.selectionStrokeColor.opacity(strokeOpacity), lineWidth: 1)
            }
            .onHover { hovered = $0 }
            .scaleEffect(isPressed ? DS.Interaction.pressScale : 1)
            .offset(y: offsetY)
            .shadow(color: Color.black.opacity(hovered && !isPressed ? 0.05 : 0), radius: hovered && !isPressed ? 8 : 0, x: 0, y: hovered && !isPressed ? 3 : 0)
            .animation(FlowDeskMotion.hoverEase, value: hovered)
            .animation(isPressed ? FlowDeskMotion.uiPressDown : FlowDeskMotion.uiPressRelease, value: isPressed)
    }

    private var fillOpacity: CGFloat {
        if isPressed { return 0.12 }
        return hovered ? 0.055 : 0
    }

    private var strokeOpacity: CGFloat {
        if isPressed { return 0.22 }
        return hovered ? 0.12 : 0
    }

    private var offsetY: CGFloat {
        if isPressed { return 0.35 }
        return hovered ? DS.Interaction.hoverLiftPoints : 0
    }
}
