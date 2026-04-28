import AppKit
import SwiftUI

/// Stroke color / width for the Draw tool (new strokes).
struct DrawingToolInspectorSection: View {
    @Bindable var canvasViewModel: CanvasBoardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Drawing tool")
                .font(FlowDeskTypography.inspectorEyebrow)
                .tracking(0.85)
                .foregroundStyle(DS.Color.textTertiary)

            InspectorColorPreviewRow(title: "Stroke", color: strokeColorBinding, supportsOpacity: true)

            InspectorLabeledSlider(
                title: "Width",
                value: $canvasViewModel.drawingLineWidth,
                range: 1 ... 24,
                step: 0.5,
                valueLabel: String(format: "%.1f pt", canvasViewModel.drawingLineWidth)
            )

            InspectorLabeledSlider(
                title: "Opacity",
                value: $canvasViewModel.drawingStrokeOpacity,
                range: 0.15 ... 1,
                step: 0.01,
                valueLabel: String(format: "%.0f%%", canvasViewModel.drawingStrokeOpacity * 100)
            )
        }
    }

    private var strokeColorBinding: Binding<Color> {
        Binding(
            get: { canvasViewModel.drawingStrokeColor.swiftUIColor },
            set: { newColor in
                canvasViewModel.drawingStrokeColor = Self.rgba(from: newColor)
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
