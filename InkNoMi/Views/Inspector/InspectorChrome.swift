import SwiftUI

// MARK: - Section shell (design-tool inspector, not plain Form)

/// Grouped block with uppercase eyebrow and card surface (Figma / design-inspector rhythm).
struct InspectorSectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    @ViewBuilder var content: () -> Content

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FlowDeskLayout.cardCornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(FlowDeskTypography.inspectorEyebrow)
                .tracking(FlowDeskTypeTracking.labelUppercase)
                .foregroundStyle(DS.Color.textTertiary)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            cardShape
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
        }
        .overlay {
            cardShape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.55),
                            Color.black.opacity(colorScheme == .dark ? 0.35 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                .blendMode(.overlay)
                .opacity(0.75)
        }
        .overlay {
            cardShape
                .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.07), lineWidth: 0.5)
        }
        .shadow(
            color: DS.Shadow.soft.color.opacity(colorScheme == .dark ? 1.18 : 1.0),
            radius: DS.Shadow.soft.radius,
            x: 0,
            y: DS.Shadow.soft.y
        )
    }
}

/// Secondary chunk card for content inside a primary inspector section.
struct InspectorSubsectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder var content: () -> Content

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FlowDeskLayout.cardCornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                cardShape
                    .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.025))
            }
            .overlay {
                cardShape
                    .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0.3 : 0.055), lineWidth: 0.5)
            }
            .shadow(
                color: DS.Shadow.soft.color.opacity(colorScheme == .dark ? 1.05 : 0.9),
                radius: DS.Shadow.soft.radius,
                x: 0,
                y: DS.Shadow.soft.y
            )
    }
}

/// Empty selection: illustration + guidance (replaces plain “Nothing selected” copy).
struct InspectorEmptySelectionPlaceholder: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DS.Color.accent.opacity(0.14),
                                DS.Color.accent.opacity(0.04)
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 44
                        )
                    )
                    .frame(width: 76, height: 76)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 54, height: 54)
                VStack(spacing: 3) {
                    Image(systemName: "cursorarrow.click.2")
                        .flowDeskStandardIcon(size: 22)
                        .foregroundStyle(DS.Color.accent.opacity(0.9))
                    Image(systemName: "selection.pin.in.out")
                        .flowDeskStandardIcon(size: 11)
                        .foregroundStyle(DS.Color.textSecondary.opacity(0.85))
                }
            }

            VStack(spacing: 6) {
                Text("Nothing selected")
                    .font(FlowDeskFont.display(size: FlowDeskTypeScale.bodyCompact, weight: .semibold))
                    .tracking(FlowDeskTypeTracking.displayTight)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Press V for Select, then click an object. Shift-click adds more items, and drag on empty canvas to box-select.")
                    .font(FlowDeskTypography.inspectorBody)
                    .tracking(FlowDeskTypeTracking.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                shortcutChip("V", label: "Select")
                shortcutChip("Shift+Click", label: "Add")
                shortcutChip("Drag", label: "Box")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func shortcutChip(_ key: String, label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary.opacity(0.82))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }
}

// MARK: - Control rows

struct InspectorLabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(FlowDeskTypography.inspectorLabel)
                    .foregroundStyle(DS.Color.textSecondary)
                Spacer()
                Text(valueLabel)
                    .font(FlowDeskTypography.inspectorValueMonospace)
                    .foregroundStyle(DS.Color.textTertiary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(DS.Color.accent)
        }
    }
}

/// Large swatch + color picker — reads as a design control, not a bare ColorPicker.
struct InspectorColorPreviewRow: View {
    let title: String
    @Binding var color: Color
    var supportsOpacity: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(FlowDeskTypography.inspectorLabel)
                .foregroundStyle(DS.Color.textSecondary)
            Spacer(minLength: 8)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.09), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            ColorPicker("", selection: $color, supportsOpacity: supportsOpacity)
                .labelsHidden()
                .frame(width: 28, height: 28)
        }
    }
}
