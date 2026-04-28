import AppKit
import SwiftUI

/// Bounding-box chrome, selection, and move for a persisted freehand stroke (no resize in v1).
struct StrokeCanvasItemView: View {
    let element: CanvasElementRecord
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    @State private var moveDragTranslation: CGSize = .zero
    @State private var moveDragStartCanvasOrigin: CGPoint?
    @State private var isHovered = false

    private var payload: StrokePayload {
        element.resolvedStrokePayload()
    }

    private var isSelected: Bool {
        selection.isSelected(element.id)
    }

    private var isDragging: Bool {
        moveDragStartCanvasOrigin != nil
    }

    /// Slight zoom compensation keeps perceived stroke weight steadier across zoom levels.
    private var zoomCompensatedLineWidth: CGFloat {
        let zoom = max(0.25, min(4, CGFloat(boardViewModel.boardState.viewport.scale)))
        let compensation = pow(zoom, -0.12) // subtle, not absolute lock
        let clamped = min(max(compensation, 0.9), 1.12)
        return CGFloat(payload.lineWidth) * clamped
    }

    private var strokeDragScale: CGFloat {
        if isConverting { return 0.985 }
        return isDragging ? 1.01 : 1.0
    }

    private var chromeCorner: CGFloat { FlowDeskTheme.strokeSelectionChromeCorner }
    private var isConverting: Bool { boardViewModel.convertingStrokeIDs.contains(element.id) }

    var body: some View {
        ZStack {
            FreehandStrokeShapeView(
                points: payload.points,
                color: payload.color,
                lineWidth: zoomCompensatedLineWidth,
                opacity: payload.opacity
            )

            CanvasFramedItemSelectionChrome(
                cornerRadius: chromeCorner,
                isVisible: isSelected
            )
            if isHovered && !isSelected {
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .strokeBorder(DS.Color.accent.opacity(0.2), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .offset(moveDragTranslation)
        .zIndex(isDragging ? Double(element.zIndex) + 0.1 : Double(element.zIndex))
        .scaleEffect(strokeDragScale)
        .opacity(isConverting ? 0 : 1)
        .animation(FlowDeskMotion.quickEaseOut, value: isDragging)
        .animation(FlowDeskMotion.fastEaseOut, value: isConverting)
        .contentShape(Rectangle())
        .onTapGesture {
            guard boardViewModel.canvasTool == .select else { return }
            boardViewModel.stopAllInlineEditing()
            let extend = NSEvent.modifierFlags.contains(.shift)
            selection.handleCanvasTap(elementID: element.id, extendSelection: extend)
        }
        .simultaneousGesture(moveGesture)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            CanvasElementEditorContextMenuItems(
                elementID: element.id,
                boardViewModel: boardViewModel,
                selection: selection
            )
        }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                guard boardViewModel.canvasTool == .select, isSelected else { return }
                if moveDragStartCanvasOrigin == nil {
                    moveDragStartCanvasOrigin = CGPoint(x: element.x, y: element.y)
                }
                moveDragTranslation = value.translation
            }
            .onEnded { value in
                guard boardViewModel.canvasTool == .select, isSelected else {
                    moveDragTranslation = .zero
                    moveDragStartCanvasOrigin = nil
                    return
                }
                let start = moveDragStartCanvasOrigin ?? CGPoint(x: element.x, y: element.y)
                let nx = Double(start.x) + Double(value.translation.width)
                let ny = Double(start.y) + Double(value.translation.height)
                boardViewModel.setStrokeFrame(
                    id: element.id,
                    x: nx,
                    y: ny,
                    width: element.width,
                    height: element.height
                )
                moveDragTranslation = .zero
                moveDragStartCanvasOrigin = nil
            }
    }
}
