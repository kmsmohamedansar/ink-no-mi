import SwiftUI

// MARK: - Framed item (text, sticky, chart, stroke box, shape)

/// Glow-first selection ring for rounded-rect canvas items. Replaces a single harsh `strokeBorder`.
struct CanvasFramedItemSelectionChrome: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulseActive = false

    let cornerRadius: CGFloat
    let isVisible: Bool

    var body: some View {
        Group {
            if isVisible {
                let pulseScale: CGFloat = pulseActive ? 1.01 : 1
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(tokens.selectionStrokeColor.opacity(pulseActive ? 0.35 : 0.3), lineWidth: 11)
                        .blur(radius: pulseActive ? 10 : 8)
                        .allowsHitTesting(false)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(tokens.selectionStrokeColor.opacity(pulseActive ? 0.3 : 0.26), lineWidth: 1.2)
                        .blur(radius: 0.6)
                        .shadow(color: tokens.selectionStrokeColor.opacity(pulseActive ? 0.42 : 0.34), radius: pulseActive ? 20 : 15, x: 0, y: 0)
                        .shadow(color: tokens.selectionStrokeColor.opacity(pulseActive ? 0.28 : 0.22), radius: pulseActive ? 32 : 26, x: 0, y: 0)
                        .allowsHitTesting(false)
                }
                .scaleEffect(pulseScale)
                .animation(FlowDeskMotion.selectionPulseOut, value: pulseActive)
                .onAppear {
                    triggerSelectionPulse()
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, visible in
            if visible {
                triggerSelectionPulse()
            } else {
                pulseActive = false
            }
        }
    }

    private func triggerSelectionPulse() {
        pulseActive = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            pulseActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pulseActive = false
            }
        }
    }
}

// MARK: - Primary selection mat (board-level halo)

/// Extra emphasis ring drawn in canvas space when a framed element is the primary selection.
struct CanvasPrimarySelectionMatte: View {
    @Environment(\.flowDeskTokens) private var tokens

    let width: CGFloat
    let height: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    let selectionPulse: Bool
    let selectionGlowVisible: Bool

    private let cornerRadius: CGFloat = 14

    var body: some View {
        let pad: CGFloat = selectionPulse ? 14 : 11
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(tokens.selectionStrokeColor.opacity(selectionPulse ? 0.34 : 0.24), lineWidth: 13)
                .blur(radius: selectionPulse ? 11 : 8)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(tokens.selectionStrokeColor.opacity(selectionPulse ? 0.24 : 0.18), lineWidth: 1.4)
                .blur(radius: 0.7)
                .shadow(
                    color: tokens.selectionStrokeColor.opacity(selectionGlowVisible ? (selectionPulse ? 0.34 : 0.22) : 0),
                    radius: selectionPulse ? 24 : 14,
                    x: 0,
                    y: 0
                )
        }
        .frame(width: width + pad, height: height + pad)
        .position(x: centerX, y: centerY)
        .scaleEffect(selectionPulse ? 1.01 : 1.0)
        .opacity(selectionGlowVisible ? (selectionPulse ? 0.98 : 0.9) : 0)
        .animation(FlowDeskMotion.selectionPulseOut, value: selectionPulse)
        .animation(FlowDeskMotion.selectionGlowIn, value: selectionGlowVisible)
        .allowsHitTesting(false)
    }
}
