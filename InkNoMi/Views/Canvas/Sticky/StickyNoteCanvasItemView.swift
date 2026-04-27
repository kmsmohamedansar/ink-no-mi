import AppKit
import SwiftUI

/// Renders and edits a sticky note: paper color, soft shadow, inline text editing, move/resize.
struct StickyNoteCanvasItemView: View {
    @Environment(\.flowDeskTokens) private var tokens

    let element: CanvasElementRecord
    @Bindable var boardViewModel: CanvasBoardViewModel
    @Bindable var selection: CanvasSelectionModel

    @State private var draftText: String = ""
    @State private var moveDragTranslation: CGSize = .zero
    @State private var moveDragStartCanvasOrigin: CGPoint?
    @State private var resizeDragStartSize: CGSize?
    @State private var isHovered: Bool = false
    @State private var connectDragStartCanvasPoint: CGPoint?
    @FocusState private var editorFocused: Bool

    private var payload: StickyNotePayload {
        element.resolvedStickyNotePayload()
    }

    private var isEditing: Bool {
        boardViewModel.editingStickyNoteElementID == element.id
    }

    private var isSelected: Bool {
        selection.isSelected(element.id)
    }
    private var isDragging: Bool {
        moveDragStartCanvasOrigin != nil
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

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CanvasStickyNoteLayout.cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardShape
                .fill(payload.backgroundColor.swiftUIColor)
                .shadow(
                    color: Color.black.opacity(
                        isDragging ? 0.14 : (isSelected ? tokens.canvasItemShadowSelected : tokens.canvasItemShadowNormal)
                    ),
                    radius: isDragging ? 14 : (isSelected ? tokens.canvasItemShadowRadiusSelected : tokens.canvasItemShadowRadiusNormal),
                    x: 0,
                    y: isDragging ? 8 : (isSelected ? tokens.canvasItemShadowYSelected : tokens.canvasItemShadowYNormal)
                )
                .overlay {
                    cardShape
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5)
                        .blendMode(.plusLighter)
                }

            Group {
                if isEditing {
                    let font = NSFont.systemFont(
                        ofSize: CGFloat(payload.fontSize),
                        weight: payload.isBold ? .semibold : .regular
                    )
                    TextEditor(text: $draftText)
                        .font(Font(font))
                        .foregroundStyle(payload.textColor.swiftUIColor)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color.clear)
                        .focused($editorFocused)
                } else {
                    StickyNoteDisplayView(payload: payload)
                }
            }
            .padding(CanvasStickyNoteLayout.contentPadding)

            cardShape
                .strokeBorder(tokens.selectionStrokeColor, lineWidth: tokens.selectionStrokeWidth)
                .opacity(isSelected ? 1 : 0)
                .allowsHitTesting(false)
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .strokeBorder(DS.Color.accent.opacity(0.2), lineWidth: 1)
                .opacity(isHovered && !isSelected ? 1 : 0)
                .allowsHitTesting(false)
        }
        .animation(FlowDeskMotion.standardEaseOut, value: isSelected)
        .animation(FlowDeskMotion.smoothEaseOut, value: isSelected && !selection.isMultiSelection)
        .overlay(alignment: .bottomTrailing) {
            if isSelected, !isEditing, !selection.isMultiSelection {
                CanvasTextBlockResizeHandle()
                    .padding(FlowDeskLayout.canvasSelectionChromeInset)
                    .gesture(resizeGesture)
                    .transition(FlowDeskMotion.handleTransition)
            }
        }
        .overlay {
            if boardViewModel.canvasTool == .select, isSelected, !isEditing, !selection.isMultiSelection {
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
        .zIndex(isDragging ? Double(element.zIndex) + 0.1 : Double(element.zIndex))
        .scaleEffect(isDragging ? 1.01 : 1.0)
        .contentShape(cardShape)
        .animation(FlowDeskMotion.quickEaseOut, value: isDragging)
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                selection.selectOnly(element.id)
                beginEditing()
            }
        )
        .onTapGesture {
            boardViewModel.stopAllInlineEditing()
            let extend = NSEvent.modifierFlags.contains(.shift)
            selection.handleCanvasTap(elementID: element.id, extendSelection: extend)
        }
        .simultaneousGesture(moveGesture)
        .simultaneousGesture(connectGesture)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Edit") { beginEditing() }
            Divider()
            CanvasElementEditorContextMenuItems(
                elementID: element.id,
                boardViewModel: boardViewModel,
                selection: selection
            )
        }
        .onAppear {
            if isEditing {
                draftText = payload.text
                DispatchQueue.main.async { editorFocused = true }
            }
        }
        .onChange(of: isEditing) { _, editing in
            if editing {
                draftText = payload.text
                DispatchQueue.main.async { editorFocused = true }
            }
        }
        .onChange(of: boardViewModel.editingStickyNoteElementID) { oldValue, newValue in
            if oldValue == element.id, newValue != element.id {
                commitDraftIfNeeded()
                editorFocused = false
            }
        }
        .onChange(of: selection.primarySelectedID) { _, newId in
            guard isEditing else { return }
            if newId != element.id {
                commitDraftIfNeeded()
                editorFocused = false
                boardViewModel.stopEditingStickyNote()
            }
        }
        .onChange(of: editorFocused) { _, focused in
            if !focused, isEditing {
                commitDraftIfNeeded()
                boardViewModel.stopEditingStickyNote()
            }
        }
        .onDisappear {
            if isEditing {
                commitDraftIfNeeded()
            }
        }
    }

    private func beginEditing() {
        boardViewModel.beginEditingStickyNote(id: element.id)
    }

    private func commitDraftIfNeeded() {
        boardViewModel.updateStickyNotePayload(id: element.id) { $0.text = draftText }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard boardViewModel.canvasTool == .select else { return }
                guard !isEditing else { return }
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
                    boardViewModel.setStickyNoteFrame(
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
                guard boardViewModel.canvasTool == .select else { return }
                guard !isEditing else { return }
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
                    boardViewModel.setStickyNoteFrame(
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
                let nw = max(CanvasStickyNoteLayout.minWidth, Double(start.width) + Double(value.translation.width))
                let nh = max(CanvasStickyNoteLayout.minHeight, Double(start.height) + Double(value.translation.height))
                let snappingEnabled = !NSEvent.modifierFlags.contains(.option)
                let (snappedSize, guides) = boardViewModel.snapResizeBottomRightFrame(
                    origin: CGPoint(x: element.x, y: element.y),
                    rawSize: CGSize(width: nw, height: nh),
                    elementId: element.id,
                    minWidth: CGFloat(CanvasStickyNoteLayout.minWidth),
                    minHeight: CGFloat(CanvasStickyNoteLayout.minHeight),
                    enableSnapping: snappingEnabled
                )
                boardViewModel.setStickyNoteFrame(
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

    private var connectGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard boardViewModel.canvasTool == .connect else { return }
                guard !isEditing else { return }
                if connectDragStartCanvasPoint == nil {
                    selection.selectOnly(element.id)
                    let frame = CGRect(x: element.x, y: element.y, width: element.width, height: element.height)
                    let start = CGPoint(x: frame.midX, y: frame.midY)
                    let target = CGPoint(x: element.x + value.startLocation.x, y: element.y + value.startLocation.y)
                    let edge = nearestEdge(in: frame, to: target)
                    let t = edgeT(for: target, in: frame, edge: edge)
                    let startPoint = CanvasConnectorGeometry.pointOnElementFrame(edge: edge, t: t, rect: frame)
                    connectDragStartCanvasPoint = startPoint
                    let style: ConnectorLineStyle = NSEvent.modifierFlags.contains(.shift) ? .straight : .arrow
                    boardViewModel.beginConnectorDrag(
                        startElementID: element.id,
                        startEdge: edge,
                        startT: Double(t),
                        startCanvasPoint: startPoint,
                        style: style
                    )
                }
                let current = CGPoint(x: element.x + value.location.x, y: element.y + value.location.y)
                boardViewModel.updateConnectorDrag(currentCanvasPoint: current)
            }
            .onEnded { _ in
                guard boardViewModel.canvasTool == .connect else { return }
                defer { connectDragStartCanvasPoint = nil }
                boardViewModel.commitConnectorDrag(selection: selection)
            }
    }

    private func nearestEdge(in rect: CGRect, to point: CGPoint) -> ConnectorEdge {
        let distances: [(ConnectorEdge, CGFloat)] = [
            (.top, abs(point.y - rect.minY)),
            (.bottom, abs(point.y - rect.maxY)),
            (.left, abs(point.x - rect.minX)),
            (.right, abs(point.x - rect.maxX))
        ]
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? .right
    }

    private func edgeT(for point: CGPoint, in rect: CGRect, edge: ConnectorEdge) -> CGFloat {
        switch edge {
        case .top, .bottom:
            guard rect.width > 0 else { return 0.5 }
            return ((point.x - rect.minX) / rect.width).clamped(to: 0...1)
        case .left, .right:
            guard rect.height > 0 else { return 0.5 }
            return ((point.y - rect.minY) / rect.height).clamped(to: 0...1)
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
