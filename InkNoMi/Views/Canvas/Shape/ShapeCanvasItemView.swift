import AppKit
import SwiftUI

/// Selectable shape on the board: vector body, accent chrome, move + resize.
struct ShapeCanvasItemView: View {
    @Environment(\.flowDeskTokens) private var tokens

    let element: CanvasElementRecord
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    @State private var moveDragTranslation: CGSize = .zero
    @State private var moveDragStartCanvasOrigin: CGPoint?
    @State private var resizeDragStartSize: CGSize?
    @State private var isHovered = false

    private var payload: ShapePayload {
        element.resolvedShapePayload()
    }

    private var isSelected: Bool {
        selection.isSelected(element.id)
    }

    private var isActiveContainer: Bool {
        boardViewModel.activeContainerShapeID == element.id
    }

    private var composedMoveOffset: CGSize {
        if boardViewModel.optionDuplicateSourceElementID == element.id {
            return .zero
        }
        if boardViewModel.groupMoveLeaderID == element.id {
            return moveDragTranslation
        }
        if boardViewModel.groupMoveParticipantIDs.contains(element.id) {
            return boardViewModel.groupMovePreviewTranslation
        }
        return moveDragTranslation
    }

    private var chromeCorner: CGFloat { FlowDeskTheme.shapeSelectionChromeCorner }
    private var isConvertingIn: Bool { boardViewModel.convertingShapeIDs.contains(element.id) }

    var body: some View {
        ZStack {
            ShapeCanvasShapeView(payload: payload)

            RoundedRectangle(cornerRadius: chromeCorner, style: .continuous)
                .strokeBorder(tokens.selectionStrokeColor, lineWidth: tokens.selectionStrokeWidth)
                .opacity(isSelected || isActiveContainer ? 1 : 0)
                .allowsHitTesting(false)
            RoundedRectangle(cornerRadius: chromeCorner, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                .opacity(isHovered && !isSelected && !isActiveContainer ? 1 : 0)
                .allowsHitTesting(false)
        }
        .animation(FlowDeskMotion.standardEaseOut, value: isSelected || isActiveContainer)
        .overlay(alignment: .bottomTrailing) {
            if isSelected, !selection.isMultiSelection {
                CanvasTextBlockResizeHandle()
                    .padding(FlowDeskLayout.canvasSelectionChromeInset)
                    .gesture(resizeGesture)
                    .transition(FlowDeskMotion.handleTransition)
            }
        }
        .overlay {
            if boardViewModel.canvasTool == .select, isSelected, !selection.isMultiSelection {
                ShapeConnectorHandlesOverlay(
                    element: element,
                    boardViewModel: boardViewModel,
                    selection: selection
                )
                .allowsHitTesting(true)
                .help("Drag a blue dot to connect to another object (⇧ straight line)")
                .transition(FlowDeskMotion.handleTransition)
            }
        }
        .offset(composedMoveOffset)
        .scaleEffect(isConvertingIn ? 0.95 : 1.0)
        .opacity(isConvertingIn ? 0.76 : 1.0)
        .animation(FlowDeskMotion.standardEaseOut, value: isConvertingIn)
        .contentShape(Rectangle())
        .onTapGesture {
            boardViewModel.stopAllInlineEditing()
            let extend = NSEvent.modifierFlags.contains(.shift)
            selection.handleCanvasTap(elementID: element.id, extendSelection: extend)
            if !extend {
                boardViewModel.setActiveContainer(shapeID: element.id)
            }
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
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if moveDragStartCanvasOrigin == nil {
                    if boardViewModel.beginOptionDuplicateIfNeeded(fromElementId: element.id, selection: selection) {
                        let subject = boardViewModel.moveGestureSubjectElementId(viewElementId: element.id)
                        if let rec = boardViewModel.boardState.elements.first(where: { $0.id == subject }) {
                            moveDragStartCanvasOrigin = CGPoint(x: CGFloat(rec.x), y: CGFloat(rec.y))
                        }
                    } else {
                        moveDragStartCanvasOrigin = CGPoint(x: element.x, y: element.y)
                        boardViewModel.configureGroupMoveIfNeeded(leaderId: element.id, selection: selection)
                    }
                }
                let subjectId = boardViewModel.moveGestureSubjectElementId(viewElementId: element.id)
                guard let subjectRec = boardViewModel.boardState.elements.first(where: { $0.id == subjectId }) else { return }
                let start = moveDragStartCanvasOrigin ?? CGPoint(x: subjectRec.x, y: subjectRec.y)
                let rawX = start.x + value.translation.width
                let rawY = start.y + value.translation.height
                let snappingEnabled = !NSEvent.modifierFlags.contains(.option)
                let exclude = boardViewModel.snapExclusionsForFramedMove(leaderId: subjectId, selection: selection)
                let (snapped, guides) = boardViewModel.snapMoveFrame(
                    rawOrigin: CGPoint(x: rawX, y: rawY),
                    size: CGSize(width: subjectRec.width, height: subjectRec.height),
                    excludingElementIds: exclude,
                    movingElementId: subjectId,
                    enableSnapping: snappingEnabled
                )
                if boardViewModel.optionDuplicateSourceElementID == element.id {
                    boardViewModel.setShapeFrame(
                        id: subjectId,
                        x: Double(snapped.x),
                        y: Double(snapped.y),
                        width: subjectRec.width,
                        height: subjectRec.height
                    )
                    moveDragTranslation = .zero
                } else {
                    moveDragTranslation = CGSize(
                        width: snapped.x - CGFloat(subjectRec.x),
                        height: snapped.y - CGFloat(subjectRec.y)
                    )
                }
                boardViewModel.syncGroupMovePreview(leaderId: element.id, translation: moveDragTranslation)
                boardViewModel.updateAlignmentGuides(guides)
            }
            .onEnded { value in
                boardViewModel.clearAlignmentGuides(after: 0.14)
                let subjectId = boardViewModel.moveGestureSubjectElementId(viewElementId: element.id)
                guard let subjectRec = boardViewModel.boardState.elements.first(where: { $0.id == subjectId }) else {
                    boardViewModel.resetGroupMoveState()
                    boardViewModel.clearOptionDuplicateDragState()
                    moveDragTranslation = .zero
                    moveDragStartCanvasOrigin = nil
                    return
                }
                let start = moveDragStartCanvasOrigin ?? CGPoint(x: subjectRec.x, y: subjectRec.y)
                let rawX = start.x + value.translation.width
                let rawY = start.y + value.translation.height
                let snappingEnabled = !NSEvent.modifierFlags.contains(.option)
                let exclude = boardViewModel.snapExclusionsForFramedMove(leaderId: subjectId, selection: selection)
                let (snapped, _) = boardViewModel.snapMoveFrame(
                    rawOrigin: CGPoint(x: rawX, y: rawY),
                    size: CGSize(width: subjectRec.width, height: subjectRec.height),
                    excludingElementIds: exclude,
                    movingElementId: subjectId,
                    enableSnapping: snappingEnabled
                )
                let participants = boardViewModel.groupMoveParticipantIDs
                if boardViewModel.groupMoveLeaderID == element.id,
                   participants.count > 1 {
                    let dx = Double(snapped.x - start.x)
                    let dy = Double(snapped.y - start.y)
                    boardViewModel.applyFramedGroupPositionDelta(ids: participants, dx: dx, dy: dy)
                } else {
                    boardViewModel.setShapeFrame(
                        id: subjectId,
                        x: Double(snapped.x),
                        y: Double(snapped.y),
                        width: subjectRec.width,
                        height: subjectRec.height
                    )
                }
                boardViewModel.resetGroupMoveState()
                boardViewModel.clearOptionDuplicateDragState()
                moveDragTranslation = .zero
                moveDragStartCanvasOrigin = nil
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if resizeDragStartSize == nil {
                    boardViewModel.beginBoardUndoCoalescing()
                    resizeDragStartSize = CGSize(width: element.width, height: element.height)
                }
                guard let start = resizeDragStartSize else { return }
                let nw = max(CanvasShapeLayout.minWidth, Double(start.width) + Double(value.translation.width))
                let nh = max(CanvasShapeLayout.minHeight, Double(start.height) + Double(value.translation.height))
                let snappingEnabled = !NSEvent.modifierFlags.contains(.option)
                let (snappedSize, guides) = boardViewModel.snapResizeBottomRightFrame(
                    origin: CGPoint(x: element.x, y: element.y),
                    rawSize: CGSize(width: nw, height: nh),
                    elementId: element.id,
                    minWidth: CGFloat(CanvasShapeLayout.minWidth),
                    minHeight: CGFloat(CanvasShapeLayout.minHeight),
                    enableSnapping: snappingEnabled
                )
                boardViewModel.setShapeFrame(
                    id: element.id,
                    x: element.x,
                    y: element.y,
                    width: Double(snappedSize.width),
                    height: Double(snappedSize.height)
                )
                boardViewModel.updateAlignmentGuides(guides)
            }
            .onEnded { _ in
                boardViewModel.clearAlignmentGuides(after: 0.14)
                boardViewModel.endBoardUndoCoalescing()
                resizeDragStartSize = nil
            }
    }
}

enum CanvasShapeLayout {
    static let minWidth: Double = 44
    static let minHeight: Double = 28
}
