import AppKit
import SwiftUI

struct ShapeInspectorSection: View {
    let elementID: UUID
    @Bindable var canvasViewModel: CanvasBoardViewModel
    
    private let strokePresets: [CanvasRGBAColor] = [
        CanvasRGBAColor(red: 0.18, green: 0.2, blue: 0.24, opacity: 1),
        CanvasRGBAColor(red: 0.22, green: 0.35, blue: 0.82, opacity: 1),
        CanvasRGBAColor(red: 0.16, green: 0.52, blue: 0.39, opacity: 1),
        CanvasRGBAColor(red: 0.72, green: 0.36, blue: 0.18, opacity: 1),
        CanvasRGBAColor(red: 0.56, green: 0.24, blue: 0.68, opacity: 1)
    ]

    private let fillPresets: [CanvasRGBAColor] = [
        CanvasRGBAColor(red: 0.82, green: 0.86, blue: 0.94, opacity: 0.9),
        CanvasRGBAColor(red: 0.78, green: 0.9, blue: 0.85, opacity: 0.9),
        CanvasRGBAColor(red: 0.95, green: 0.86, blue: 0.76, opacity: 0.9),
        CanvasRGBAColor(red: 0.9, green: 0.82, blue: 0.92, opacity: 0.9),
        CanvasRGBAColor(red: 0.95, green: 0.8, blue: 0.82, opacity: 0.9)
    ]

    private let gradientPresets: [(start: CanvasRGBAColor, end: CanvasRGBAColor)] = [
        (
            CanvasRGBAColor(red: 0.2, green: 0.35, blue: 0.78, opacity: 1),
            CanvasRGBAColor(red: 0.45, green: 0.67, blue: 0.98, opacity: 0.92)
        ),
        (
            CanvasRGBAColor(red: 0.17, green: 0.52, blue: 0.42, opacity: 1),
            CanvasRGBAColor(red: 0.47, green: 0.86, blue: 0.72, opacity: 0.9)
        ),
        (
            CanvasRGBAColor(red: 0.62, green: 0.29, blue: 0.2, opacity: 1),
            CanvasRGBAColor(red: 0.95, green: 0.62, blue: 0.45, opacity: 0.9)
        ),
        (
            CanvasRGBAColor(red: 0.46, green: 0.25, blue: 0.63, opacity: 1),
            CanvasRGBAColor(red: 0.86, green: 0.54, blue: 0.94, opacity: 0.9)
        )
    ]

    private var shapePayload: ShapePayload? {
        guard let el = canvasViewModel.boardState.elements.first(where: { $0.id == elementID }),
              el.kind == .shape
        else { return nil }
        return el.resolvedShapePayload()
    }

    var body: some View {
        if let shapePayload {
            VStack(alignment: .leading, spacing: 14) {
                Text("Shape")
                    .font(FlowDeskTypography.inspectorEyebrow)
                    .tracking(0.85)
                    .foregroundStyle(DS.Color.textTertiary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(FlowDeskTypography.inspectorLabel)
                        .foregroundStyle(DS.Color.textSecondary)
                    Picker("", selection: kindBinding(fallback: shapePayload.kind)) {
                        Text("Rect").tag(FlowDeskShapeKind.rectangle)
                        Text("Round").tag(FlowDeskShapeKind.roundedRectangle)
                        Text("Ellipse").tag(FlowDeskShapeKind.ellipse)
                        Text("Line").tag(FlowDeskShapeKind.line)
                        Text("Arrow").tag(FlowDeskShapeKind.arrow)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                InspectorColorPreviewRow(title: "Stroke", color: strokeColorBinding(fallback: shapePayload.strokeColor), supportsOpacity: true)
                palettePresetRow(colors: strokePresets) { color in
                    canvasViewModel.updateShapePayload(id: elementID) { $0.strokeColor = color }
                }

                if shapePayload.supportsFill {
                    InspectorColorPreviewRow(title: "Fill", color: fillColorBinding(fallback: shapePayload.fillColor), supportsOpacity: true)
                    palettePresetRow(colors: fillPresets) { color in
                        canvasViewModel.updateShapePayload(id: elementID) { $0.fillColor = color }
                    }
                    gradientPreviewRow
                }

                InspectorLabeledSlider(
                    title: "Line width",
                    value: lineWidthBinding(fallback: shapePayload.lineWidth),
                    range: 1 ... 16,
                    step: 0.5,
                    valueLabel: String(format: "%.1f pt", shapePayload.lineWidth)
                )

                if shapePayload.kind == .roundedRectangle || shapePayload.kind == .rectangle {
                    InspectorLabeledSlider(
                        title: "Corner radius",
                        value: cornerRadiusBinding(fallback: shapePayload.cornerRadius),
                        range: 0 ... 48,
                        step: 1,
                        valueLabel: "\(Int(shapePayload.cornerRadius)) pt"
                    )
                }
            }
        }
    }

    private var gradientPreviewRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gradient preview")
                .font(FlowDeskTypography.inspectorLabel)
                .foregroundStyle(DS.Color.textSecondary)
            HStack(spacing: 8) {
                ForEach(Array(gradientPresets.enumerated()), id: \.offset) { _, preset in
                    Button {
                        canvasViewModel.updateShapePayload(id: elementID) { payload in
                            payload.strokeColor = preset.start
                            payload.fillColor = preset.end
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [preset.start.swiftUIColor, preset.end.swiftUIColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 24)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.14), lineWidth: 0.6)
                            }
                    }
                    .buttonStyle(.plain)
                    .help("Apply gradient palette")
                }
            }
        }
    }

    private func palettePresetRow(colors: [CanvasRGBAColor], apply: @escaping (CanvasRGBAColor) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Button {
                    apply(color)
                } label: {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func kindBinding(fallback: FlowDeskShapeKind) -> Binding<FlowDeskShapeKind> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedShapePayload().kind
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateShapePayload(id: elementID) { $0.kind = newValue }
            }
        )
    }

    private func strokeColorBinding(fallback: CanvasRGBAColor) -> Binding<Color> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedShapePayload().strokeColor
                    .swiftUIColor ?? fallback.swiftUIColor
            },
            set: { newColor in
                let rgba = Self.rgba(from: newColor)
                canvasViewModel.updateShapePayload(id: elementID) { $0.strokeColor = rgba }
            }
        )
    }

    private func fillColorBinding(fallback: CanvasRGBAColor) -> Binding<Color> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedShapePayload().fillColor
                    .swiftUIColor ?? fallback.swiftUIColor
            },
            set: { newColor in
                let rgba = Self.rgba(from: newColor)
                canvasViewModel.updateShapePayload(id: elementID) { $0.fillColor = rgba }
            }
        )
    }

    private func lineWidthBinding(fallback: Double) -> Binding<Double> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedShapePayload().lineWidth
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateShapePayload(id: elementID) { $0.lineWidth = newValue }
            }
        )
    }

    private func cornerRadiusBinding(fallback: Double) -> Binding<Double> {
        Binding(
            get: {
                canvasViewModel.boardState.elements.first { $0.id == elementID }?.resolvedShapePayload().cornerRadius
                    ?? fallback
            },
            set: { newValue in
                canvasViewModel.updateShapePayload(id: elementID) { $0.cornerRadius = newValue }
            }
        )
    }

    private static func rgba(from color: Color) -> CanvasRGBAColor {
        guard let cg = color.cgColor, let ns = NSColor(cgColor: cg) else {
            return .defaultText
        }
        return CanvasRGBAColor(nsColor: ns)
    }
}
