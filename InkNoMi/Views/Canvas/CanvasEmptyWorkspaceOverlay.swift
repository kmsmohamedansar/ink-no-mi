import SwiftUI

/// When the board has no elements: example ghost layout + central hint card + subtle ambient motion (non-interactive).
struct CanvasEmptyWorkspaceOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.flowDeskTokens) private var tokens

    @State private var entrance = false
    @State private var breathePhase = false

    private var isDark: Bool { colorScheme == .dark }

    private var ghostStroke: Color {
        Color.primary.opacity(isDark ? 0.095 : 0.055)
    }

    private var ghostFill: Color {
        tokens.accent.opacity(isDark ? 0.065 : 0.045)
    }

    var body: some View {
        ZStack {
            ghostComposition
                .opacity(entrance ? 1 : 0)
                .scaleEffect(entrance ? 1 : 0.97)
                .animation(FlowDeskMotion.slowEaseOut.delay(0.06), value: entrance)

            hintCard
                .opacity(entrance ? 1 : 0)
                .scaleEffect(entrance ? 1 : 0.93)
                .offset(y: entrance ? 0 : 8)
                .animation(FlowDeskMotion.slowEaseOut, value: entrance)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Empty canvas. Pick a tool to add content, drag to pan, pinch to zoom.")
        .onAppear {
            entrance = true
        }
        .onReceive(Timer.publish(every: 4.2, on: .main, in: .common).autoconnect()) { _ in
            breathePhase.toggle()
        }
    }

    private var ghostComposition: some View {
        let drift: CGFloat = breathePhase ? 2 : -2
        let driftAlt: CGFloat = breathePhase ? -1.5 : 1.5

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ghostStroke, lineWidth: 1)
                .frame(width: 122, height: 86)
                .rotationEffect(.degrees(-5))
                .offset(x: -178, y: -52 + drift)

            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(ghostFill.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(ghostStroke, lineWidth: 1)
                }
                .frame(width: 142, height: 94)
                .offset(x: 176, y: -46 + driftAlt)

            penSquiggle
                .stroke(
                    ghostStroke.opacity(0.9),
                    style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 168, height: 56)
                .offset(x: -28, y: 102 + drift * 0.5)

            Ellipse()
                .stroke(ghostStroke, lineWidth: 1)
                .frame(width: 76, height: 52)
                .offset(x: 158, y: 78 + driftAlt)

            connectorGhost
                .offset(y: -78 + drift * 0.35)
        }
        .frame(width: 560, height: 340)
        .animation(FlowDeskMotion.slowEaseInOut, value: breathePhase)
    }

    private var penSquiggle: Path {
        Path { path in
            path.move(to: CGPoint(x: 12, y: 38))
            path.addQuadCurve(to: CGPoint(x: 88, y: 14), control: CGPoint(x: 44, y: 58))
            path.addQuadCurve(to: CGPoint(x: 156, y: 36), control: CGPoint(x: 122, y: -6))
        }
    }

    private var connectorGhost: some View {
        ZStack {
            Circle()
                .stroke(ghostStroke, lineWidth: 1)
                .frame(width: 9, height: 9)
                .offset(x: -42, y: 0)
            Path { path in
                path.move(to: CGPoint(x: -36, y: 0))
                path.addQuadCurve(to: CGPoint(x: 48, y: 6), control: CGPoint(x: 6, y: 28))
            }
            .stroke(ghostStroke.opacity(0.8), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            Circle()
                .stroke(ghostStroke, lineWidth: 1)
                .frame(width: 9, height: 9)
                .offset(x: 52, y: 10)
        }
        .offset(x: -8, y: -110)
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "square.stack.3d.forward.dotted.line")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tokens.accentGradientStart, tokens.accentGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)

                Text("Start on this surface")
                    .font(FlowDeskFont.display(size: FlowDeskTypeScale.body + 2, weight: .semibold))
                    .tracking(FlowDeskTypeTracking.displayTight)
                    .foregroundStyle(Color.primary.opacity(isDark ? 0.92 : 0.88))
            }

            Text("Pan across infinite space, zoom to focus, then sketch, drop notes, or wire ideas together—the faint shapes behind this card are just inspiration.")
                .font(FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .regular))
                .tracking(FlowDeskTypeTracking.body)
                .foregroundStyle(Color.primary.opacity(isDark ? 0.52 : 0.42))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 312)

            HStack(spacing: 10) {
                hintChip(icon: "pencil.tip.crop.circle", title: "Ink")
                hintChip(icon: "note.text", title: "Notes")
                hintChip(icon: "arrow.triangle.branch", title: "Link")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    tokens.accent.opacity(isDark ? 0.35 : 0.22),
                                    tokens.accent.opacity(isDark ? 0.12 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(
            color: Color.black.opacity(isDark ? 0.38 : 0.09),
            radius: breathePhase ? 19 : 14,
            x: 0,
            y: breathePhase ? 9 : 6
        )
        .animation(FlowDeskMotion.slowEaseInOut, value: breathePhase)
    }

    private func hintChip(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.primary.opacity(isDark ? 0.48 : 0.4))
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background {
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(isDark ? 0.1 : 0.06))
        }
    }
}
