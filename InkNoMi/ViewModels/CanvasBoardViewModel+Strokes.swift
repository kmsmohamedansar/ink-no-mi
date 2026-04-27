import CoreGraphics
import Foundation
#if canImport(Vision)
import Vision
#endif

/// Raw freehand input captured from mouse/trackpad in absolute canvas space.
struct FreehandStroke: Equatable, Sendable {
    var id: UUID
    var points: [CGPoint]
    var createdAt: Date

    init(id: UUID = UUID(), points: [CGPoint], createdAt: Date = Date()) {
        self.id = id
        self.points = points
        self.createdAt = createdAt
    }
}

@MainActor
extension CanvasBoardViewModel {
    /// Keeps legacy call sites while routing directly to raw stroke commit.
    func scheduleFreehandRecognition(
        absoluteCanvasPoints: [CGPoint],
        selection: CanvasSelectionModel,
        delay: TimeInterval = 0.2
    ) {
        _ = delay
        commitFreehandStroke(absoluteCanvasPoints: absoluteCanvasPoints, selection: selection)
    }

    func configureStrokeStyleForActiveTool() {
        switch canvasTool {
        case .pencil:
            drawingLineWidth = 1.8
            drawingStrokeOpacity = 0.62
        case .pen:
            drawingLineWidth = max(drawingLineWidth, 2.6)
            drawingStrokeOpacity = max(drawingStrokeOpacity, 0.95)
        default:
            break
        }
    }

    /// Pure paint behavior: always persist the stroke exactly as drawn.
    func commitFreehandStroke(absoluteCanvasPoints: [CGPoint], selection: CanvasSelectionModel) {
        let refined = StrokePathSmoothing.finalizedStrokePoints(absoluteCanvasPoints)
        guard refined.count >= 2 else { return }
        stopAllInlineEditing()
        let stroke = FreehandStroke(points: refined)
        _ = insertPersistedFreehandStroke(stroke, selection: selection)
    }

    func updateStrokePayload(id: UUID, _ body: (inout StrokePayload) -> Void) {
        updateElement(id: id) { element in
            guard element.kind == .stroke else { return }
            var payload = element.resolvedStrokePayload()
            body(&payload)
            payload.opacity = payload.opacity.clamped(to: 0...1)
            element.strokePayload = payload
        }
    }

    func setStrokeFrame(id: UUID, x: Double, y: Double, width: Double, height: Double) {
        updateElement(id: id) { element in
            guard element.kind == .stroke else { return }
            element.x = x
            element.y = y
            element.width = max(width, 1)
            element.height = max(height, 1)
        }
    }

    @discardableResult
    private func insertPersistedFreehandStroke(
        _ stroke: FreehandStroke,
        selection: CanvasSelectionModel
    ) -> (id: UUID, bounds: CGRect) {
        _ = selection
        let pad = max(6, CGFloat(drawingLineWidth) * 0.5 + 4)
        let xs = stroke.points.map(\.x)
        let ys = stroke.points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            let fallbackID = UUID()
            return (fallbackID, .null)
        }

        let originX = Double(minX) - Double(pad)
        let originY = Double(minY) - Double(pad)
        let w = max(8, Double(maxX - minX) + Double(pad) * 2)
        let h = max(8, Double(maxY - minY) + Double(pad) * 2)

        let localPoints: [StrokePathPoint] = stroke.points.map { p in
            StrokePathPoint(x: Double(p.x) - originX, y: Double(p.y) - originY)
        }

        var payload = StrokePayload.default
        payload.points = localPoints
        payload.color = drawingStrokeColor
        payload.lineWidth = drawingLineWidth
        payload.opacity = drawingStrokeOpacity.clamped(to: 0...1)

        let id = UUID()
        let record = CanvasElementRecord(
            id: id,
            kind: .stroke,
            x: originX,
            y: originY,
            width: w,
            height: h,
            zIndex: nextZIndex(),
            parentShapeID: nil,
            strokePayload: payload
        )
        applyBoardMutation { state in
            state.elements.append(record)
        }
        return (id, CGRect(x: originX, y: originY, width: w, height: h))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

@MainActor
extension CanvasBoardViewModel {
    func convertSelectedStrokesToShape(selection: CanvasSelectionModel) {
        let selected = selectedStrokeRecords(selection: selection)
        guard !selected.isEmpty else { return }
        let strokes = selected.map(absoluteStroke(from:))
        guard let candidate = detectBestShape(from: strokes) else { return }

        var payload = ShapePayload.default
        payload.kind = candidate.kind
        let frame = candidate.frame.standardized
        guard frame.width >= CanvasShapeLayout.minWidth, frame.height >= CanvasShapeLayout.minHeight else { return }

        let id = UUID()
        let sourceIDs = Set(selected.map(\.id))
        let record = CanvasElementRecord(
            id: id,
            kind: .shape,
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height,
            zIndex: nextZIndex(),
            parentShapeID: nil,
            shapePayload: payload
        )
        applyBoardMutation { state in
            state.elements.removeAll { sourceIDs.contains($0.id) }
            state.elements.append(record)
        }
        selection.selectOnly(id)
    }

    func convertSelectedStrokesToText(selection: CanvasSelectionModel) {
        let selected = selectedStrokeRecords(selection: selection)
        guard !selected.isEmpty else { return }
        let strokes = selected.map(absoluteStroke(from:))
        let sourceIDs = Set(selected.map(\.id))
        Task { [strokes] in
            let result = await Task.detached(priority: .userInitiated) {
                Self.recognizeText(from: strokes)
            }.value
            guard let recognized = result else { return }
            self.replaceStrokesWithText(recognized: recognized, sourceStrokeIDs: sourceIDs, selection: selection)
        }
    }

    func convertSelectedStrokesToDiagram(selection: CanvasSelectionModel) {
        let selected = selectedStrokeRecords(selection: selection)
        guard selected.count >= 2 else { return }
        let strokes = selected.map(absoluteStroke(from:))
        let groups = groupDiagramStrokes(strokes)
        guard groups.count >= 2 else { return }
        let plan = buildDiagramPlan(strokes: strokes, groups: groups)
        applyDiagramPlan(plan, selectedStrokeIDs: Set(selected.map(\.id)), selection: selection)
    }
}

private extension CanvasBoardViewModel {
    struct ManualShapeCandidate {
        var kind: FlowDeskShapeKind
        var frame: CGRect
        var confidence: Double
    }

    struct RecognizedManualText {
        var text: String
        var frame: CGRect
        var confidence: Double
    }

    struct DiagramStrokeGroup {
        var strokeIDs: Set<UUID>
        var bounds: CGRect
        var centroid: CGPoint
    }

    struct DiagramElementDraft {
        var id: UUID
        var kind: CanvasElementKind
        var frame: CGRect
        var zIndex: Int
        var shapePayload: ShapePayload?
        var textPayload: TextBlockPayload?
    }

    struct DiagramConnectorDraft {
        var startID: UUID
        var endID: UUID
        var startPoint: CGPoint
        var endPoint: CGPoint
        var style: ConnectorLineStyle
    }

    struct DiagramPlan {
        var drafts: [DiagramElementDraft]
        var connectors: [DiagramConnectorDraft]
        var confidence: Double
    }

    enum DiagramGroupKind {
        case rectangle(ManualShapeCandidate)
        case arrow(ManualShapeCandidate)
        case text(RecognizedManualText)
    }

    func selectedStrokeRecords(selection: CanvasSelectionModel) -> [CanvasElementRecord] {
        boardState.elements.filter { selection.selectedElementIDs.contains($0.id) && $0.kind == .stroke }
    }

    func absoluteStroke(from element: CanvasElementRecord) -> FreehandStroke {
        let payload = element.resolvedStrokePayload()
        let points = payload.points.map { CGPoint(x: element.x + $0.x, y: element.y + $0.y) }
        return FreehandStroke(id: element.id, points: points)
    }

    func detectBestShape(from strokes: [FreehandStroke]) -> ManualShapeCandidate? {
        var candidates: [ManualShapeCandidate] = []
        if strokes.count == 1, let stroke = strokes.first {
            if let rectangle = detectRectangle(stroke) { candidates.append(rectangle) }
            if let arrow = detectSingleStrokeArrow(stroke) { candidates.append(arrow) }
            if let line = detectLine(stroke) { candidates.append(line) }
        } else if let arrow = detectMultiStrokeArrow(strokes) {
            candidates.append(arrow)
        }
        return candidates.sorted(by: { $0.confidence > $1.confidence }).first
    }

    func groupDiagramStrokes(_ strokes: [FreehandStroke]) -> [DiagramStrokeGroup] {
        guard !strokes.isEmpty else { return [] }
        let metrics: [(stroke: FreehandStroke, bounds: CGRect, centroid: CGPoint)] = strokes.compactMap { stroke in
            guard !stroke.points.isEmpty else { return nil }
            let bounds = boundsForPoints(stroke.points).insetBy(dx: -8, dy: -8)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            return (stroke, bounds, center)
        }
        guard !metrics.isEmpty else { return [] }

        let proximityThreshold: CGFloat = 72
        var adjacency: [UUID: Set<UUID>] = [:]
        for item in metrics {
            adjacency[item.stroke.id] = []
        }
        for i in 0..<metrics.count {
            for j in (i + 1)..<metrics.count {
                let a = metrics[i]
                let b = metrics[j]
                let expandedIntersect = a.bounds.insetBy(dx: -14, dy: -14).intersects(b.bounds.insetBy(dx: -14, dy: -14))
                let centerDistance = hypot(a.centroid.x - b.centroid.x, a.centroid.y - b.centroid.y)
                let nearby = centerDistance <= proximityThreshold
                if expandedIntersect || nearby {
                    adjacency[a.stroke.id, default: []].insert(b.stroke.id)
                    adjacency[b.stroke.id, default: []].insert(a.stroke.id)
                }
            }
        }

        var visited: Set<UUID> = []
        var groups: [DiagramStrokeGroup] = []
        let byID: [UUID: (stroke: FreehandStroke, bounds: CGRect, centroid: CGPoint)] = Dictionary(uniqueKeysWithValues: metrics.map { ($0.stroke.id, $0) })
        for metric in metrics {
            if visited.contains(metric.stroke.id) { continue }
            var queue: [UUID] = [metric.stroke.id]
            var ids: Set<UUID> = []
            while let current = queue.popLast() {
                if visited.contains(current) { continue }
                visited.insert(current)
                ids.insert(current)
                for neighbor in adjacency[current, default: []] where !visited.contains(neighbor) {
                    queue.append(neighbor)
                }
            }
            let groupRects = ids.compactMap { byID[$0]?.bounds }
            guard let first = groupRects.first else { continue }
            let bounds = groupRects.dropFirst().reduce(first) { $0.union($1) }
            let centers = ids.compactMap { byID[$0]?.centroid }
            let centroid = centers.isEmpty
                ? CGPoint(x: bounds.midX, y: bounds.midY)
                : CGPoint(
                    x: centers.reduce(0) { $0 + $1.x } / CGFloat(centers.count),
                    y: centers.reduce(0) { $0 + $1.y } / CGFloat(centers.count)
                )
            groups.append(DiagramStrokeGroup(strokeIDs: ids, bounds: bounds, centroid: centroid))
        }
        return groups.sorted { lhs, rhs in
            if lhs.centroid.y != rhs.centroid.y { return lhs.centroid.y < rhs.centroid.y }
            return lhs.centroid.x < rhs.centroid.x
        }
    }

    func buildDiagramPlan(strokes: [FreehandStroke], groups: [DiagramStrokeGroup]) -> DiagramPlan? {
        guard !groups.isEmpty else { return nil }
        let strokeMap = Dictionary(uniqueKeysWithValues: strokes.map { ($0.id, $0) })
        var classified: [(group: DiagramStrokeGroup, kind: DiagramGroupKind, confidence: Double)] = []

        for group in groups {
            let groupStrokes = group.strokeIDs.compactMap { strokeMap[$0] }
            guard !groupStrokes.isEmpty else { continue }
            if let kind = classifyDiagramGroup(groupStrokes: groupStrokes, groupBounds: group.bounds) {
                let confidence: Double
                switch kind {
                case .rectangle(let rect): confidence = rect.confidence
                case .arrow(let arrow): confidence = arrow.confidence
                case .text(let text): confidence = text.confidence
                }
                classified.append((group, kind, confidence))
            }
        }

        guard !classified.isEmpty else { return nil }
        let validRatio = Double(classified.count) / Double(max(groups.count, 1))
        let avgConfidence = classified.reduce(0.0) { $0 + $1.confidence } / Double(classified.count)
        let totalConfidence = (validRatio * 0.45) + (avgConfidence * 0.55)
        guard totalConfidence >= 0.74 else { return nil }

        let boxItems = classified.filter {
            if case .rectangle = $0.kind { return true }
            return false
        }.sorted {
            if $0.group.centroid.y != $1.group.centroid.y { return $0.group.centroid.y < $1.group.centroid.y }
            return $0.group.centroid.x < $1.group.centroid.x
        }

        var boxFramesByGroup: [Set<UUID>: CGRect] = [:]
        if !boxItems.isEmpty {
            let laneSpacing: CGFloat = 44
            var cursorX: CGFloat = boxItems.first?.group.bounds.minX ?? 120
            let cursorY: CGFloat = boxItems.first?.group.bounds.minY ?? 120
            for item in boxItems {
                let source: CGRect
                if case .rectangle(let shape) = item.kind {
                    source = shape.frame.standardized
                } else {
                    source = item.group.bounds.standardized
                }
                let width = max(source.width, 110)
                let height = max(source.height, 72)
                let alignedY = round(cursorY / 8) * 8
                let alignedX = round(cursorX / 8) * 8
                let snapped = CGRect(x: alignedX, y: alignedY, width: round(width / 8) * 8, height: round(height / 8) * 8)
                boxFramesByGroup[item.group.strokeIDs] = snapped
                cursorX = snapped.maxX + laneSpacing
            }
        }

        var drafts: [DiagramElementDraft] = []
        var groupElementIDs: [Set<UUID>: UUID] = [:]
        var runningZ = 1

        for item in classified {
            let id = UUID()
            groupElementIDs[item.group.strokeIDs] = id
            var frame = item.group.bounds.standardized
            var shapePayload: ShapePayload?
            var textPayload: TextBlockPayload?
            var kind: CanvasElementKind = .shape

            switch item.kind {
            case .rectangle(let shape):
                frame = boxFramesByGroup[item.group.strokeIDs] ?? shape.frame.standardized
                var payload = ShapePayload.default
                payload.kind = .rectangle
                shapePayload = payload
                kind = .shape
            case .arrow(let arrow):
                frame = arrow.frame.standardized
                var payload = ShapePayload.default
                payload.kind = .arrow
                shapePayload = payload
                kind = .shape
            case .text(let recognized):
                frame = recognized.frame.standardized
                let width = max(frame.width, CanvasTextBlockLayout.minWidth)
                let height = max(frame.height, CanvasTextBlockLayout.minHeight)
                frame = CGRect(x: frame.minX, y: frame.minY, width: width, height: height)
                var payload = TextBlockPayload.default
                payload.text = recognized.text
                textPayload = payload
                kind = .textBlock
            }

            drafts.append(
                DiagramElementDraft(
                    id: id,
                    kind: kind,
                    frame: frame,
                    zIndex: runningZ,
                    shapePayload: shapePayload,
                    textPayload: textPayload
                )
            )
            runningZ += 1
        }

        let boxDrafts = drafts.filter {
            $0.kind == .shape && $0.shapePayload?.kind == .rectangle
        }
        var connectors: [DiagramConnectorDraft] = []
        for item in classified {
            guard case .arrow = item.kind,
                  let arrowID = groupElementIDs[item.group.strokeIDs],
                  let arrowDraft = drafts.first(where: { $0.id == arrowID })
            else { continue }

            let sourceCenter = CGPoint(x: arrowDraft.frame.midX, y: arrowDraft.frame.midY)
            let nearBoxes = boxDrafts
                .map { box -> (draft: DiagramElementDraft, distance: CGFloat) in
                    let c = CGPoint(x: box.frame.midX, y: box.frame.midY)
                    return (box, hypot(c.x - sourceCenter.x, c.y - sourceCenter.y))
                }
                .sorted { $0.distance < $1.distance }

            guard nearBoxes.count >= 2 else { continue }
            let a = nearBoxes[0].draft
            let b = nearBoxes[1].draft
            if a.id == b.id { continue }
            let connection = Self.connectorBetween(start: a, end: b)
            connectors.append(connection)
        }

        return DiagramPlan(drafts: drafts, connectors: connectors, confidence: totalConfidence)
    }

    func classifyDiagramGroup(groupStrokes: [FreehandStroke], groupBounds: CGRect) -> DiagramGroupKind? {
        if groupStrokes.count == 1, let stroke = groupStrokes.first, let rectangle = detectRectangle(stroke), rectangle.confidence >= 0.79 {
            return .rectangle(rectangle)
        }
        if let arrow = detectMultiStrokeArrow(groupStrokes), arrow.confidence >= 0.78 {
            return .arrow(arrow)
        }
        if groupStrokes.count == 1, let stroke = groupStrokes.first, let arrow = detectSingleStrokeArrow(stroke), arrow.confidence >= 0.8 {
            return .arrow(arrow)
        }
        if let recognized = Self.recognizeText(from: groupStrokes), recognized.confidence >= 0.74 {
            return .text(recognized)
        }
        _ = groupBounds
        return nil
    }

    static func connectorBetween(start: DiagramElementDraft, end: DiagramElementDraft) -> DiagramConnectorDraft {
        let startCenter = CGPoint(x: start.frame.midX, y: start.frame.midY)
        let endCenter = CGPoint(x: end.frame.midX, y: end.frame.midY)
        let dx = endCenter.x - startCenter.x
        let dy = endCenter.y - startCenter.y
        if abs(dx) >= abs(dy) {
            let startPoint = CGPoint(x: dx >= 0 ? start.frame.maxX : start.frame.minX, y: startCenter.y)
            let endPoint = CGPoint(x: dx >= 0 ? end.frame.minX : end.frame.maxX, y: endCenter.y)
            return DiagramConnectorDraft(startID: start.id, endID: end.id, startPoint: startPoint, endPoint: endPoint, style: .arrow)
        }
        let startPoint = CGPoint(x: startCenter.x, y: dy >= 0 ? start.frame.maxY : start.frame.minY)
        let endPoint = CGPoint(x: endCenter.x, y: dy >= 0 ? end.frame.minY : end.frame.maxY)
        return DiagramConnectorDraft(startID: start.id, endID: end.id, startPoint: startPoint, endPoint: endPoint, style: .arrow)
    }

    func applyDiagramPlan(_ plan: DiagramPlan?, selectedStrokeIDs: Set<UUID>, selection: CanvasSelectionModel) {
        guard let plan else { return }
        guard plan.confidence >= 0.74 else { return }
        guard !plan.drafts.isEmpty else { return }

        let existingMaxZ = boardState.elements.map(\.zIndex).max() ?? 0
        var records: [CanvasElementRecord] = []
        for (index, draft) in plan.drafts.enumerated() {
            let frame = draft.frame.standardized
            let record = CanvasElementRecord(
                id: draft.id,
                kind: draft.kind,
                x: frame.minX,
                y: frame.minY,
                width: max(1, frame.width),
                height: max(1, frame.height),
                zIndex: existingMaxZ + index + 1,
                parentShapeID: nil,
                textBlock: draft.textPayload,
                shapePayload: draft.shapePayload
            )
            records.append(record)
        }

        let shapeRecordsByID: [UUID: CanvasElementRecord] = Dictionary(
            uniqueKeysWithValues: records.filter { $0.kind == .shape }.map { ($0.id, $0) }
        )

        let connectorRecords: [CanvasElementRecord] = plan.connectors.compactMap { connector in
            guard let start = shapeRecordsByID[connector.startID], let end = shapeRecordsByID[connector.endID] else { return nil }
            let startRect = CGRect(x: start.x, y: start.y, width: start.width, height: start.height)
            let endRect = CGRect(x: end.x, y: end.y, width: end.width, height: end.height)
            let startEdge = edgeForPoint(connector.startPoint, rect: startRect)
            let endEdge = edgeForPoint(connector.endPoint, rect: endRect)
            let startT = edgeT(for: connector.startPoint, in: startRect, edge: startEdge)
            let endT = edgeT(for: connector.endPoint, in: endRect, edge: endEdge)
            let poly = CanvasConnectorGeometry.routingPolyline(
                start: connector.startPoint,
                end: connector.endPoint,
                startEdge: startEdge,
                endEdge: endEdge,
                lineStyle: connector.style
            )
            let box = CanvasConnectorGeometry.boundingFrame(polyline: poly, padding: CanvasConnectorGeometry.framePadding)
            let payload = ConnectorPayload(
                startElementID: start.id,
                endElementID: end.id,
                startEdge: startEdge,
                endEdge: endEdge,
                startT: startT,
                endT: endT,
                style: connector.style,
                strokeColor: FlowDeskConnectorVisuals.defaultStrokeRGBA,
                lineWidth: FlowDeskConnectorVisuals.defaultLineWidthDouble,
                label: ""
            )
            return CanvasElementRecord(
                id: UUID(),
                kind: .connector,
                x: Double(box.minX),
                y: Double(box.minY),
                width: Double(box.width),
                height: Double(box.height),
                zIndex: (existingMaxZ + records.count + 1),
                connectorPayload: payload
            )
        }

        let newIDs = Set(records.map(\.id))
        applyBoardMutation { state in
            state.elements.removeAll { selectedStrokeIDs.contains($0.id) }
            state.elements.append(contentsOf: records)
            state.elements.append(contentsOf: connectorRecords)
        }
        selection.replaceSelection(newIDs)
    }

    func edgeForPoint(_ point: CGPoint, rect: CGRect) -> ConnectorEdge {
        let distances: [(ConnectorEdge, CGFloat)] = [
            (.top, abs(point.y - rect.minY)),
            (.bottom, abs(point.y - rect.maxY)),
            (.left, abs(point.x - rect.minX)),
            (.right, abs(point.x - rect.maxX))
        ]
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? .right
    }

    func edgeT(for point: CGPoint, in rect: CGRect, edge: ConnectorEdge) -> Double {
        switch edge {
        case .top, .bottom:
            let denom = max(rect.width, 1)
            return Double(((point.x - rect.minX) / denom).clamped(to: 0...1))
        case .left, .right:
            let denom = max(rect.height, 1)
            return Double(((point.y - rect.minY) / denom).clamped(to: 0...1))
        }
    }

    func detectRectangle(_ stroke: FreehandStroke) -> ManualShapeCandidate? {
        guard stroke.points.count >= 8 else { return nil }
        guard let first = stroke.points.first, let last = stroke.points.last else { return nil }
        let bounds = boundsForPoints(stroke.points)
        guard bounds.width >= 28, bounds.height >= 28 else { return nil }

        let perimeter = max(1, (bounds.width + bounds.height) * 2)
        let closure = hypot(last.x - first.x, last.y - first.y)
        let closureScore = max(0, 1 - (closure / max(22, perimeter * 0.12)))
        guard closureScore > 0.6 else { return nil }

        let simplified = douglasPeucker(points: stroke.points, epsilon: max(4, hypot(bounds.width, bounds.height) * 0.03))
        let corners = countCorners(points: simplified, thresholdDegrees: 42)
        let cornerScore = max(0, 1 - (abs(Double(corners) - 4) / 4))
        let confidence = closureScore * 0.55 + cornerScore * 0.45
        guard confidence >= 0.78 else { return nil }
        return ManualShapeCandidate(kind: .rectangle, frame: bounds, confidence: confidence)
    }

    func detectLine(_ stroke: FreehandStroke) -> ManualShapeCandidate? {
        guard stroke.points.count >= 2, let first = stroke.points.first, let last = stroke.points.last else { return nil }
        let path = polylineLength(stroke.points)
        guard path > 24 else { return nil }
        let direct = hypot(last.x - first.x, last.y - first.y)
        let straightness = direct / max(path, 0.001)
        guard straightness >= 0.95 else { return nil }
        let frame = CGRect(
            x: min(first.x, last.x),
            y: min(first.y, last.y),
            width: max(abs(last.x - first.x), CanvasShapeLayout.minWidth),
            height: max(abs(last.y - first.y), CanvasShapeLayout.minHeight)
        )
        return ManualShapeCandidate(kind: .line, frame: frame, confidence: min(1, Double(straightness)))
    }

    func detectSingleStrokeArrow(_ stroke: FreehandStroke) -> ManualShapeCandidate? {
        guard stroke.points.count >= 9 else { return nil }
        guard let first = stroke.points.first, let last = stroke.points.last else { return nil }
        let path = polylineLength(stroke.points)
        let direct = hypot(last.x - first.x, last.y - first.y)
        let straightness = direct / max(path, 0.001)
        guard straightness >= 0.72 else { return nil }

        let sampled = sample(stroke.points, step: 2)
        guard sampled.count >= 6 else { return nil }
        var sharpTurns = 0
        let tailStart = max(2, sampled.count - 6)
        for i in tailStart..<(sampled.count - 2) {
            let a = sampled[i - 1]
            let b = sampled[i]
            let c = sampled[i + 1]
            let angle = abs(turnAngleDegrees(v1: CGVector(dx: b.x - a.x, dy: b.y - a.y), v2: CGVector(dx: c.x - b.x, dy: c.y - b.y)))
            if angle >= 38 { sharpTurns += 1 }
        }
        guard sharpTurns >= 1 else { return nil }
        let frame = boundsForPoints(stroke.points).insetBy(dx: -8, dy: -8)
        return ManualShapeCandidate(kind: .arrow, frame: frame, confidence: 0.82)
    }

    func detectMultiStrokeArrow(_ strokes: [FreehandStroke]) -> ManualShapeCandidate? {
        let ranked = strokes
            .map { stroke -> (stroke: FreehandStroke, straightness: CGFloat, path: CGFloat)? in
                guard let first = stroke.points.first, let last = stroke.points.last else { return nil }
                let path = polylineLength(stroke.points)
                guard path >= 36 else { return nil }
                let direct = hypot(last.x - first.x, last.y - first.y)
                let straightness = direct / max(path, 0.001)
                return (stroke, straightness, path)
            }
            .compactMap { $0 }
            .sorted { $0.path > $1.path }
        guard let shaft = ranked.first, shaft.straightness >= 0.92 else { return nil }
        guard let shaftFirst = shaft.stroke.points.first, let shaftLast = shaft.stroke.points.last else { return nil }
        let shaftEnd = shaftLast
        let nearHead = strokes
            .filter { $0.id != shaft.stroke.id }
            .contains { stroke in
                let b = boundsForPoints(stroke.points)
                let headCenter = CGPoint(x: b.midX, y: b.midY)
                return hypot(headCenter.x - shaftEnd.x, headCenter.y - shaftEnd.y) <= 80 && countCorners(points: stroke.points, thresholdDegrees: 35) >= 1
            }
        guard nearHead else { return nil }
        let frame = boundsForPoints(strokes.flatMap(\.points)).insetBy(dx: -8, dy: -8)
        let adjusted = CGRect(
            x: min(frame.minX, shaftFirst.x),
            y: min(frame.minY, shaftFirst.y),
            width: max(frame.width, CanvasShapeLayout.minWidth),
            height: max(frame.height, CanvasShapeLayout.minHeight)
        )
        return ManualShapeCandidate(kind: .arrow, frame: adjusted, confidence: 0.8)
    }

    func replaceStrokesWithText(recognized: RecognizedManualText, sourceStrokeIDs: Set<UUID>, selection: CanvasSelectionModel) {
        guard !recognized.text.isEmpty else { return }
        let frame = recognized.frame.standardized
        let width = max(frame.width, CanvasTextBlockLayout.minWidth)
        let height = max(frame.height, CanvasTextBlockLayout.minHeight)
        var payload = TextBlockPayload.default
        payload.text = recognized.text
        let id = UUID()
        let record = CanvasElementRecord(
            id: id,
            kind: .textBlock,
            x: frame.minX,
            y: frame.minY,
            width: width,
            height: height,
            zIndex: nextZIndex(),
            parentShapeID: nil,
            textBlock: payload
        )
        applyBoardMutation { state in
            state.elements.removeAll { sourceStrokeIDs.contains($0.id) }
            state.elements.append(record)
        }
        selection.selectOnly(id)
    }

    nonisolated static func recognizeText(from strokes: [FreehandStroke]) -> RecognizedManualText? {
        #if canImport(Vision)
        guard !strokes.isEmpty else { return nil }
        let grouped = boundsForPoints(strokes.flatMap(\.points)).standardized
        guard grouped.width >= 24, grouped.height >= 16 else { return nil }
        guard let image = renderStrokeImage(strokes: strokes, bounds: grouped) else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]
        request.minimumTextHeight = 0.03
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first, let top = observation.topCandidates(1).first else { return nil }
            let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let confidence = Double(top.confidence)
            if confidence < 0.72 { return nil }
            if text.count == 1, strokes.count >= 2, confidence < 0.85 { return nil }
            return RecognizedManualText(text: text, frame: grouped.insetBy(dx: -8, dy: -8), confidence: confidence)
        } catch {
            return nil
        }
        #else
        _ = strokes
        return nil
        #endif
    }

    nonisolated static func renderStrokeImage(strokes: [FreehandStroke], bounds: CGRect) -> CGImage? {
        let padding: CGFloat = 18
        let size = CGSize(width: bounds.width + padding * 2, height: bounds.height + padding * 2)
        guard let context = CGContext(
            data: nil,
            width: Int(ceil(size.width)),
            height: Int(ceil(size.height)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(3.5)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        for stroke in strokes {
            var prev: CGPoint?
            for point in stroke.points {
                let p = CGPoint(x: (point.x - bounds.minX) + padding, y: (point.y - bounds.minY) + padding)
                if let prev {
                    context.move(to: prev)
                    context.addLine(to: p)
                    context.strokePath()
                }
                prev = p
            }
        }
        return context.makeImage()
    }

    nonisolated static func boundsForPoints(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .null }
        return points.dropFirst().reduce(CGRect(origin: first, size: .zero)) { partial, point in
            partial.union(CGRect(origin: point, size: .zero))
        }
    }

    func boundsForPoints(_ points: [CGPoint]) -> CGRect {
        Self.boundsForPoints(points)
    }

    func polylineLength(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count {
            total += hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
        }
        return total
    }

    func sample(_ points: [CGPoint], step: Int) -> [CGPoint] {
        guard step > 1, points.count > step else { return points }
        var sampled: [CGPoint] = []
        for index in stride(from: 0, to: points.count, by: step) {
            sampled.append(points[index])
        }
        if sampled.last != points.last, let last = points.last { sampled.append(last) }
        return sampled
    }

    func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var maxDistance: CGFloat = 0
        var index = 0
        let start = points[0]
        let end = points[points.count - 1]
        for i in 1..<(points.count - 1) {
            let distance = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                index = i
            }
        }
        if maxDistance > epsilon {
            let left = douglasPeucker(points: Array(points[0...index]), epsilon: epsilon)
            let right = douglasPeucker(points: Array(points[index...]), epsilon: epsilon)
            return Array(left.dropLast()) + right
        }
        return [start, end]
    }

    func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let den = max(0.0001, hypot(dx, dy))
        return abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x) / den
    }

    func countCorners(points: [CGPoint], thresholdDegrees: CGFloat) -> Int {
        let sampled = sample(points, step: 2)
        guard sampled.count >= 5 else { return 0 }
        var corners = 0
        for i in 1..<(sampled.count - 1) {
            let a = sampled[i - 1]
            let b = sampled[i]
            let c = sampled[i + 1]
            let angle = abs(turnAngleDegrees(v1: CGVector(dx: b.x - a.x, dy: b.y - a.y), v2: CGVector(dx: c.x - b.x, dy: c.y - b.y)))
            if angle >= thresholdDegrees { corners += 1 }
        }
        return corners
    }

    func turnAngleDegrees(v1: CGVector, v2: CGVector) -> CGFloat {
        let n1 = hypot(v1.dx, v1.dy)
        let n2 = hypot(v2.dx, v2.dy)
        guard n1 > 0.0001, n2 > 0.0001 else { return 0 }
        let dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (n1 * n2)
        return acos(max(-1, min(1, dot))) * 180 / .pi
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
