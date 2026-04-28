import AppKit
import SwiftUI

struct TextBlockInspectorSection: View {
    let elementID: UUID
    @Bindable var canvasViewModel: CanvasBoardViewModel
    
    private let textColorPresets: [CanvasRGBAColor] = [
        CanvasRGBAColor(red: 0.12, green: 0.13, blue: 0.15, opacity: 1),
        CanvasRGBAColor(red: 0.2, green: 0.35, blue: 0.78, opacity: 1),
        CanvasRGBAColor(red: 0.15, green: 0.52, blue: 0.39, opacity: 1),
        CanvasRGBAColor(red: 0.66, green: 0.28, blue: 0.18, opacity: 1),
        CanvasRGBAColor(red: 0.48, green: 0.24, blue: 0.65, opacity: 1)
    ]

    private var textPayload: TextBlockPayload? {
        guard let el = canvasViewModel.boardState.elements.first(where: { $0.id == elementID }),
              el.kind == .textBlock
        else { return nil }
        return el.resolvedTextPayload()
    }

    var body: some View {
        if let textPayload {
            VStack(alignment: .leading, spacing: 14) {
                Text("Text")
                    .font(FlowDeskTypography.inspectorEyebrow)
                    .tracking(0.85)
                    .foregroundStyle(DS.Color.textTertiary)

                InspectorLabeledSlider(
                    title: "Size",
                    value: fontSizeBinding(fallback: textPayload.fontSize),
                    range: 10 ... 72,
                    step: 1,
                    valueLabel: "\(Int(textPayload.fontSize)) pt"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Font")
                        .font(inspectorLabelFont)
                        .tracking(0.65)
                        .textCase(.uppercase)
                        .foregroundStyle(inspectorLabelColor)
                    Picker("", selection: fontFamilyBinding(fallback: textPayload.fontFamily)) {
                        ForEach(TextBlockFontFamily.allCases, id: \.self) { family in
                            Text(family.displayName).tag(family)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(inspectorLabelFont)
                        .tracking(0.65)
                        .textCase(.uppercase)
                        .foregroundStyle(inspectorLabelColor)
                    Picker("", selection: fontWeightBinding(fallback: textPayload.fontWeight)) {
                        Text("Regular").tag(TextBlockFontWeight.regular)
                        Text("Medium").tag(TextBlockFontWeight.medium)
                        Text("Semibold").tag(TextBlockFontWeight.semibold)
                        Text("Bold").tag(TextBlockFontWeight.bold)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                InspectorColorPreviewRow(title: "Color", color: colorBinding(fallback: textPayload.color), supportsOpacity: true)
                HStack(spacing: 8) {
                    ForEach(Array(textColorPresets.enumerated()), id: \.offset) { _, preset in
                        Button {
                            canvasViewModel.updateTextPayload(id: elementID) { $0.color = preset }
                        } label: {
                            Circle()
                                .fill(preset.swiftUIColor)
                                .frame(width: 18, height: 18)
                                .overlay {
                                    Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Apply text palette color")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alignment")
                        .font(inspectorLabelFont)
                        .tracking(0.65)
                        .textCase(.uppercase)
                        .foregroundStyle(inspectorLabelColor)
                    Picker("", selection: alignmentBinding(fallback: textPayload.alignment)) {
                        Text("Left").tag(TextBlockAlignment.leading)
                        Text("Center").tag(TextBlockAlignment.center)
                        Text("Right").tag(TextBlockAlignment.trailing)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
        }
    }

    private func fontSizeBinding(fallback: Double) -> Binding<Double> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedTextPayload().fontSize
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateTextPayload(id: elementID) { $0.fontSize = newValue }
            }
        )
    }

    private func fontWeightBinding(fallback: TextBlockFontWeight) -> Binding<TextBlockFontWeight> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedTextPayload().fontWeight
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateTextPayload(id: elementID) {
                    $0.fontWeight = newValue
                    $0.isBold = (newValue == .semibold || newValue == .bold)
                }
            }
        )
    }

    private func fontFamilyBinding(fallback: TextBlockFontFamily) -> Binding<TextBlockFontFamily> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedTextPayload().fontFamily
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateTextPayload(id: elementID) { $0.fontFamily = newValue }
            }
        )
    }

    private func colorBinding(fallback: CanvasRGBAColor) -> Binding<Color> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedTextPayload().color
                    .swiftUIColor ?? fallback.swiftUIColor
            },
            set: { newColor in
                let rgba = Self.rgba(from: newColor)
                canvasViewModel.updateTextPayload(id: elementID) { $0.color = rgba }
            }
        )
    }

    private func alignmentBinding(fallback: TextBlockAlignment) -> Binding<TextBlockAlignment> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedTextPayload().alignment
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateTextPayload(id: elementID) { $0.alignment = newValue }
            }
        )
    }

    private static func rgba(from color: Color) -> CanvasRGBAColor {
        guard let cg = color.cgColor, let ns = NSColor(cgColor: cg) else {
            return .defaultText
        }
        return CanvasRGBAColor(nsColor: ns)
    }

    private var inspectorLabelFont: Font {
        .system(size: 10, weight: .semibold)
    }

    private var inspectorLabelColor: Color {
        DS.Color.textTertiary.opacity(0.92)
    }
}
