import AppKit
import CoreGraphics
import Foundation
import SwiftUI
#if canImport(Vision)
import Vision
#endif

// MARK: - Recognition domain models

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

    var bounds: CGRect {
        guard let first = points.first else { return .null }
        return points.dropFirst().reduce(CGRect(origin: first, size: .zero)) { partial, point in
            partial.union(CGRect(origin: point, size: .zero))
        }
    }
}

struct ShapeModel: Equatable, Sendable {
    var kind: FlowDeskShapeKind
    var frame: CGRect
    var confidence: Double
    /// For multi-stroke shape recognition (e.g. arrow shaft + head), these old strokes are removed.
    var consumedStrokeElementIDs: [UUID] = []
}

struct TextElement: Equatable, Sendable {
    var text: String
    var frame: CGRect
    var confidence: Double
}

enum StrokeCandidateKind: Sendable {
    case shapeCandidate
    case handwritingCandidate
    case unknown
}

enum RecognitionPipelineOutcome: Equatable, Sendable {
    case freehand
    case shape(ShapeModel)
    case text(TextElement)
}

protocol StrokeClassifier {
    func classify(stroke: FreehandStroke) -> StrokeCandidateKind
}

protocol ShapeRecognizer {
    func recognize(stroke: FreehandStroke, existingElements: [CanvasElementRecord]) -> ShapeModel?
}

protocol HandwritingRecognizer {
    /// Returns `nil` when confidence is too low.
    func recognize(strokes: [FreehandStroke]) -> TextElement?
}

protocol RecognitionPipeline {
    func recognizeImmediateShape(stroke: FreehandStroke, existingElements: [CanvasElementRecord]) -> ShapeModel?
}

struct BasicStrokeClassifier: StrokeClassifier {
    func classify(stroke: FreehandStroke) -> StrokeCandidateKind {
        guard stroke.points.count >= 4 else { return .unknown }
        let bounds = stroke.bounds.standardized
        let path = polylineLength(points: stroke.points)
        guard path > 0 else { return .unknown }
        let direct = directDistance(points: stroke.points)
        let straightness = direct / path
        let turns = turnDensity(points: stroke.points)
        let area = bounds.width * bounds.height

        // Geometric strokes skew toward shape recognition.
        if straightness >= 0.94 || (turns >= 0.3 && bounds.width >= 40 && bounds.height >= 40) {
            return .shapeCandidate
        }
        // Curvy and compact strokes skew toward handwriting recognition.
        if straightness <= 0.9,
           turns <= 0.28,
           area <= 280_000,
           bounds.width <= 1200,
           bounds.height <= 420 {
            return .handwritingCandidate
        }
        return .unknown
    }

    private func directDistance(points: [CGPoint]) -> CGFloat {
        guard let first = points.first, let last = points.last else { return 0 }
        return hypot(last.x - first.x, last.y - first.y)
    }

    private func polylineLength(points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for idx in 1..<points.count {
            total += hypot(points[idx].x - points[idx - 1].x, points[idx].y - points[idx - 1].y)
        }
        return total
    }

    private func turnDensity(points: [CGPoint]) -> Double {
        guard points.count >= 6 else { return 0 }
        let sampled = stride(from: 0, to: points.count, by: 2).map { points[$0] }
        guard sampled.count >= 5 else { return 0 }
        var turnCount = 0
        for idx in 2..<(sampled.count - 2) {
            let p0 = sampled[idx - 2]
            let p1 = sampled[idx]
            let p2 = sampled[idx + 2]
            let angle = abs(turnAngleDegrees(
                v1: CGVector(dx: p1.x - p0.x, dy: p1.y - p0.y),
                v2: CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)
            ))
            if angle >= 28 { turnCount += 1 }
        }
        return Double(turnCount) / Double(max(1, sampled.count))
    }

    private func turnAngleDegrees(v1: CGVector, v2: CGVector) -> CGFloat {
        let n1 = hypot(v1.dx, v1.dy)
        let n2 = hypot(v2.dx, v2.dy)
        guard n1 > 0.0001, n2 > 0.0001 else { return 0 }
        let dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (n1 * n2)
        return acos(max(-1, min(1, dot))) * 180 / .pi
    }
}

struct SmartShapeRecognizer: ShapeRecognizer {
    private let minimumRectangleConfidence = 0.72

    func recognize(stroke: FreehandStroke, existingElements: [CanvasElementRecord]) -> ShapeModel? {
        if let rectangle = detectRectangle(in: stroke) { return rectangle }
        if let arrow = detectArrow(using: stroke, existingElements: existingElements) { return arrow }
        if let line = detectLine(in: stroke) { return line }
        return nil
    }

    /// Rectangle detection: closure + corner geometry.
    private func detectRectangle(in stroke: FreehandStroke) -> ShapeModel? {
        guard stroke.points.count >= 12 else { return nil }
        let bounds = stroke.bounds.standardized
        guard bounds.width >= 24, bounds.height >= 24 else { return nil }
        guard let first = stroke.points.first, let last = stroke.points.last else { return nil }

        let diagonal = max(1, hypot(bounds.width, bounds.height))
        let closureDistance = hypot(last.x - first.x, last.y - first.y)
        let closureScore = max(0, 1 - (closureDistance / max(18, diagonal * 0.18)))
        guard closureScore > 0.4 else { return nil }

        let corners = majorCorners(points: stroke.points)
        guard corners.count >= 4 else { return nil }
        let cornerScore = min(1, Double(corners.count) / 4)
        let rightAngleScore = 0.9 // practical approximation from corner extraction
        let confidence = (closureScore * 0.35) + (cornerScore * 0.25) + (rightAngleScore * 0.4)
        guard confidence >= minimumRectangleConfidence else { return nil }
        return ShapeModel(kind: .rectangle, frame: bounds, confidence: confidence)
    }

    private func detectLine(in stroke: FreehandStroke) -> ShapeModel? {
        guard stroke.points.count >= 2 else { return nil }
        guard let first = stroke.points.first, let last = stroke.points.last else { return nil }
        let path = polylineLength(points: stroke.points)
        let direct = hypot(last.x - first.x, last.y - first.y)
        let straightness = direct / max(path, 0.001)
        guard path >= 28, straightness >= 0.955 else { return nil }

        let minX = min(first.x, last.x)
        let minY = min(first.y, last.y)
        let frame = CGRect(
            x: minX,
            y: minY,
            width: max(abs(last.x - first.x), CanvasShapeLayout.minWidth),
            height: max(abs(last.y - first.y), CanvasShapeLayout.minHeight)
        )
        return ShapeModel(kind: .line, frame: frame, confidence: Double(straightness))
    }

    /// Arrow detection:
    /// 1) one-stroke arrow
    /// 2) separate head stroke + nearby line shaft stroke
    private func detectArrow(using stroke: FreehandStroke, existingElements: [CanvasElementRecord]) -> ShapeModel? {
        if let oneStrokeArrow = detectSingleStrokeArrow(in: stroke) {
            return oneStrokeArrow
        }
        guard isArrowHeadCandidate(stroke) else { return nil }
        let headCenter = CGPoint(x: stroke.bounds.midX, y: stroke.bounds.midY)
        guard let shaft = nearestLineStrokeElement(to: headCenter, in: existingElements) else { return nil }
        let shaftPoints = absolutePoints(from: shaft)
        guard let shaftStart = shaftPoints.first, let shaftEnd = shaftPoints.last else { return nil }

        let startDistance = hypot(headCenter.x - shaftStart.x, headCenter.y - shaftStart.y)
        let endDistance = hypot(headCenter.x - shaftEnd.x, headCenter.y - shaftEnd.y)
        let attachDistance = min(startDistance, endDistance)
        guard attachDistance <= 70 else { return nil }

        let shaftRect = CGRect(
            x: min(shaftStart.x, shaftEnd.x),
            y: min(shaftStart.y, shaftEnd.y),
            width: abs(shaftEnd.x - shaftStart.x),
            height: abs(shaftEnd.y - shaftStart.y)
        )
        let union = stroke.bounds.union(shaftRect).insetBy(dx: -8, dy: -8)
        return ShapeModel(
            kind: .arrow,
            frame: CGRect(
                x: union.minX,
                y: union.minY,
                width: max(union.width, CanvasShapeLayout.minWidth),
                height: max(union.height, CanvasShapeLayout.minHeight)
            ),
            confidence: 0.84,
            consumedStrokeElementIDs: [shaft.id]
        )
    }

    private func detectSingleStrokeArrow(in stroke: FreehandStroke) -> ShapeModel? {
        guard stroke.points.count >= 8 else { return nil }
        guard let first = stroke.points.first, let last = stroke.points.last else { return nil }
        let bounds = stroke.bounds.standardized
        guard bounds.width >= 36 || bounds.height >= 36 else { return nil }
        let path = polylineLength(points: stroke.points)
        let direct = hypot(last.x - first.x, last.y - first.y)
        guard path > 0, direct / path >= 0.72 else { return nil }

        let sampled = sample(points: stroke.points, step: 2)
        guard sampled.count >= 6 else { return nil }
        let tailIndex = max(2, sampled.count - 5)
        var sharpTurnsNearTail = 0
        for idx in tailIndex..<(sampled.count - 2) {
            let p0 = sampled[idx - 1]
            let p1 = sampled[idx]
            let p2 = sampled[idx + 1]
            let angle = abs(turnAngleDegrees(
                v1: CGVector(dx: p1.x - p0.x, dy: p1.y - p0.y),
                v2: CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)
            ))
            if angle >= 38 { sharpTurnsNearTail += 1 }
        }
        guard sharpTurnsNearTail >= 1 else { return nil }

        let frame = bounds.insetBy(dx: -8, dy: -8)
        return ShapeModel(
            kind: .arrow,
            frame: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: max(frame.width, CanvasShapeLayout.minWidth),
                height: max(frame.height, CanvasShapeLayout.minHeight)
            ),
            confidence: 0.8
        )
    }

    private func isArrowHeadCandidate(_ stroke: FreehandStroke) -> Bool {
        let bounds = stroke.bounds.standardized
        let path = polylineLength(points: stroke.points)
        guard path >= 10, path <= 220 else { return false }
        guard bounds.width <= 140, bounds.height <= 140 else { return false }
        return majorCorners(points: stroke.points).count >= 1
    }

    private func nearestLineStrokeElement(to point: CGPoint, in elements: [CanvasElementRecord]) -> CanvasElementRecord? {
        elements
            .filter { $0.kind == .stroke }
            .sorted { $0.zIndex > $1.zIndex }
            .prefix(8)
            .compactMap { element -> (CanvasElementRecord, CGFloat)? in
                let points = absolutePoints(from: element)
                guard points.count >= 2, let first = points.first, let last = points.last else { return nil }
                let path = polylineLength(points: points)
                let direct = hypot(last.x - first.x, last.y - first.y)
                let straightness = direct / max(path, 0.001)
                guard straightness >= 0.95, path >= 36 else { return nil }
                let distance = min(
                    hypot(point.x - first.x, point.y - first.y),
                    hypot(point.x - last.x, point.y - last.y)
                )
                return (element, distance)
            }
            .sorted { $0.1 < $1.1 }
            .first?
            .0
    }

    private func absolutePoints(from element: CanvasElementRecord) -> [CGPoint] {
        element.resolvedStrokePayload().points.map {
            CGPoint(x: CGFloat(element.x + $0.x), y: CGFloat(element.y + $0.y))
        }
    }

    private func majorCorners(points: [CGPoint]) -> [CGPoint] {
        let sampled = sample(points: points, step: 3)
        guard sampled.count >= 9 else { return [] }
        var corners: [CGPoint] = []
        for idx in 2..<(sampled.count - 2) {
            let p0 = sampled[idx - 2]
            let p1 = sampled[idx]
            let p2 = sampled[idx + 2]
            let angle = abs(turnAngleDegrees(
                v1: CGVector(dx: p1.x - p0.x, dy: p1.y - p0.y),
                v2: CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)
            ))
            if angle > 40 { corners.append(p1) }
        }
        return corners
    }

    private func sample(points: [CGPoint], step: Int) -> [CGPoint] {
        guard step > 1, points.count > step else { return points }
        var sampled: [CGPoint] = []
        for idx in stride(from: 0, to: points.count, by: step) {
            sampled.append(points[idx])
        }
        if sampled.last != points.last, let last = points.last { sampled.append(last) }
        return sampled
    }

    private func polylineLength(points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for idx in 1..<points.count {
            total += hypot(points[idx].x - points[idx - 1].x, points[idx].y - points[idx - 1].y)
        }
        return total
    }

    private func turnAngleDegrees(v1: CGVector, v2: CGVector) -> CGFloat {
        let n1 = hypot(v1.dx, v1.dy)
        let n2 = hypot(v2.dx, v2.dy)
        guard n1 > 0.0001, n2 > 0.0001 else { return 0 }
        let dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (n1 * n2)
        return acos(max(-1, min(1, dot))) * 180 / .pi
    }
}

struct VisionHandwritingRecognizer: HandwritingRecognizer {
    private let confidenceThreshold: Float

    init(confidenceThreshold: Float) {
        self.confidenceThreshold = confidenceThreshold
    }

    /// Runs OCR on the grouped stroke image (not on a single stroke).
    func recognize(strokes: [FreehandStroke]) -> TextElement? {
        #if canImport(Vision)
        guard !strokes.isEmpty else { return nil }
        let groupedBounds = unionBounds(strokes: strokes)
        guard let image = renderGroupedStrokeImage(strokes: strokes, bounds: groupedBounds) else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.04
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first,
                  let top = observation.topCandidates(1).first
            else {
                print("[InkNoMi OCR] OCR result: none")
                return nil
            }
            let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let confidence = top.confidence
            print("[InkNoMi OCR] OCR result: \"\(text)\" confidence=\(confidence)")
            guard !text.isEmpty, confidence >= confidenceThreshold else { return nil }
            return TextElement(
                text: text,
                frame: groupedBounds.insetBy(dx: -8, dy: -8).standardized,
                confidence: Double(confidence)
            )
        } catch {
            print("[InkNoMi OCR] OCR error: \(error.localizedDescription)")
            return nil
        }
        #else
        return nil
        #endif
    }

    private func unionBounds(strokes: [FreehandStroke]) -> CGRect {
        strokes.reduce(CGRect.null) { partial, stroke in
            partial.union(stroke.bounds)
        }.standardized
    }

    private func renderGroupedStrokeImage(strokes: [FreehandStroke], bounds: CGRect) -> CGImage? {
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let padding: CGFloat = 18
        let imageSize = CGSize(width: bounds.width + (padding * 2), height: bounds.height + (padding * 2))

        guard let context = CGContext(
            data: nil,
            width: Int(ceil(imageSize.width)),
            height: Int(ceil(imageSize.height)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(3.5)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.translateBy(x: 0, y: imageSize.height)
        context.scaleBy(x: 1, y: -1)

        for stroke in strokes {
            var previous: CGPoint?
            for point in stroke.points {
                let p = CGPoint(
                    x: (point.x - bounds.minX) + padding,
                    y: (point.y - bounds.minY) + padding
                )
                if let prev = previous {
                    context.move(to: prev)
                    context.addLine(to: p)
                    context.strokePath()
                }
                previous = p
            }
        }
        return context.makeImage()
    }
}

struct CanvasRecognitionPipeline: RecognitionPipeline {
    private let classifier: StrokeClassifier
    private let shapeRecognizer: ShapeRecognizer

    init(
        classifier: StrokeClassifier,
        shapeRecognizer: ShapeRecognizer,
        handwritingRecognizer: HandwritingRecognizer
    ) {
        // Handwriting is intentionally buffered/debounced outside this immediate pipeline.
        self.classifier = classifier
        self.shapeRecognizer = shapeRecognizer
    }

    func recognizeImmediateShape(stroke: FreehandStroke, existingElements: [CanvasElementRecord]) -> ShapeModel? {
        let kind = classifier.classify(stroke: stroke)
        switch kind {
        case .shapeCandidate, .unknown:
            return shapeRecognizer.recognize(stroke: stroke, existingElements: existingElements)
        case .handwritingCandidate:
            return nil
        }
    }
}

// MARK: - Handwriting buffer + debouncer

struct HandwritingStrokeBuffer: Sendable {
    var strokeElementIDs: [UUID] = []
    var groupedBounds: CGRect = .null
    var lastStrokeTime: Date?

    mutating func clear() {
        strokeElementIDs = []
        groupedBounds = .null
        lastStrokeTime = nil
    }

    mutating func addStroke(id: UUID, bounds: CGRect, at time: Date) {
        strokeElementIDs.append(id)
        groupedBounds = groupedBounds.isNull ? bounds : groupedBounds.union(bounds)
        lastStrokeTime = time
    }

    func canGroup(newBounds: CGRect, at time: Date, maxGap: TimeInterval, maxDistance: CGFloat) -> Bool {
        guard let lastStrokeTime else { return false }
        guard time.timeIntervalSince(lastStrokeTime) <= maxGap else { return false }
        guard !groupedBounds.isNull else { return false }
        let expanded = groupedBounds.insetBy(dx: -maxDistance, dy: -maxDistance)
        return expanded.intersects(newBounds) || expanded.contains(newBounds)
    }
}

struct RecognitionDebouncer: Sendable {
    var delaySeconds: TimeInterval
}

// MARK: - Canvas stroke commit and replacement

extension CanvasBoardViewModel {
    private static let handwritingGroupingTimeWindow: TimeInterval = 1.2
    private static let handwritingGroupingDistance: CGFloat = 180

    /// Temporary grouped handwriting state.
    private static var fallbackBuffer = HandwritingStrokeBuffer()
    private static var fallbackDebouncer = RecognitionDebouncer(delaySeconds: 0.95)
    private static var fallbackWorkItem: DispatchWorkItem?

    private var handwritingBuffer: HandwritingStrokeBuffer {
        get { Self.fallbackBuffer }
        set { Self.fallbackBuffer = newValue }
    }

    private var handwritingDebouncer: RecognitionDebouncer {
        get { Self.fallbackDebouncer }
        set { Self.fallbackDebouncer = newValue }
    }

    private var handwritingRecognitionWorkItem: DispatchWorkItem? {
        get { Self.fallbackWorkItem }
        set { Self.fallbackWorkItem = newValue }
    }

    func scheduleFreehandRecognition(
        absoluteCanvasPoints: [CGPoint],
        selection: CanvasSelectionModel,
        delay: TimeInterval = 0.2
    ) {
        let points = absoluteCanvasPoints
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.commitFreehandStroke(absoluteCanvasPoints: points, selection: selection)
        }
    }

    func commitFreehandStroke(absoluteCanvasPoints: [CGPoint], selection: CanvasSelectionModel) {
        let decimated = StrokePathSmoothing.decimatedCanvasPoints(absoluteCanvasPoints, minDistance: 2)
        guard decimated.count >= 2 else { return }
        stopAllInlineEditing()
        let stroke = FreehandStroke(points: decimated)

        // Fast shape conversion still happens immediately.
        if let shape = recognitionPipeline.recognizeImmediateShape(
            stroke: stroke,
            existingElements: boardState.elements
        ) {
            insertRecognizedShape(shape, fallbackStroke: stroke, selection: selection)
            return
        }

        // Non-shape strokes are persisted, then grouped for delayed handwriting OCR.
        let persisted = insertPersistedFreehandStroke(stroke, selection: selection)
        addStrokeToHandwritingBuffer(
            persistedStrokeID: persisted.id,
            strokeBounds: persisted.bounds,
            selection: selection
        )
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

    private func addStrokeToHandwritingBuffer(
        persistedStrokeID: UUID,
        strokeBounds: CGRect,
        selection: CanvasSelectionModel
    ) {
        let now = Date()
        if handwritingBuffer.strokeElementIDs.isEmpty {
            handwritingBuffer.clear()
            handwritingBuffer.addStroke(id: persistedStrokeID, bounds: strokeBounds, at: now)
            print("[InkNoMi OCR] stroke added to handwriting buffer id=\(persistedStrokeID.uuidString)")
            scheduleHandwritingRecognition(selection: selection)
            return
        }

        let canGroup = handwritingBuffer.canGroup(
            newBounds: strokeBounds,
            at: now,
            maxGap: Self.handwritingGroupingTimeWindow,
            maxDistance: Self.handwritingGroupingDistance
        )

        if canGroup {
            handwritingBuffer.addStroke(id: persistedStrokeID, bounds: strokeBounds, at: now)
            print("[InkNoMi OCR] stroke added to handwriting buffer id=\(persistedStrokeID.uuidString)")
            cancelPendingHandwritingRecognition(reason: "user continued writing")
            scheduleHandwritingRecognition(selection: selection)
        } else {
            performHandwritingRecognition(selection: selection)
            handwritingBuffer.clear()
            handwritingBuffer.addStroke(id: persistedStrokeID, bounds: strokeBounds, at: now)
            print("[InkNoMi OCR] stroke added to handwriting buffer id=\(persistedStrokeID.uuidString)")
            scheduleHandwritingRecognition(selection: selection)
        }
    }

    private func scheduleHandwritingRecognition(selection: CanvasSelectionModel) {
        let delay = handwritingDebouncer.delaySeconds
        print("[InkNoMi OCR] recognition delayed by \(delay)s")
        let workItem = DispatchWorkItem { [weak self] in
            self?.performHandwritingRecognition(selection: selection)
        }
        handwritingRecognitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelPendingHandwritingRecognition(reason: String) {
        if let workItem = handwritingRecognitionWorkItem {
            workItem.cancel()
            handwritingRecognitionWorkItem = nil
            print("[InkNoMi OCR] recognition cancelled because \(reason)")
        }
    }

    private func performHandwritingRecognition(selection: CanvasSelectionModel) {
        handwritingRecognitionWorkItem = nil
        let ids = handwritingBuffer.strokeElementIDs
        guard !ids.isEmpty else { return }

        let groupedElements = boardState.elements.filter { ids.contains($0.id) && $0.kind == .stroke }
        guard !groupedElements.isEmpty else {
            handwritingBuffer.clear()
            return
        }

        let groupedStrokes: [FreehandStroke] = groupedElements.compactMap { element in
            let payload = element.resolvedStrokePayload()
            guard !payload.points.isEmpty else { return nil }
            let points = payload.points.map {
                CGPoint(x: CGFloat(element.x + $0.x), y: CGFloat(element.y + $0.y))
            }
            return FreehandStroke(points: points)
        }
        guard !groupedStrokes.isEmpty else {
            handwritingBuffer.clear()
            return
        }

        let groupedBounds = groupedStrokes.reduce(CGRect.null) { partial, stroke in
            partial.union(stroke.bounds)
        }.standardized
        print("[InkNoMi OCR] grouped bounds=\(groupedBounds.debugDescription)")

        let recognizer = VisionHandwritingRecognizer(confidenceThreshold: 0.25)
        guard let textElement = recognizer.recognize(strokes: groupedStrokes) else {
            // Keep raw strokes when confidence is low or OCR is uncertain.
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            applyBoardMutation { state in
                state.elements.removeAll { ids.contains($0.id) }
            }
        }
        insertRecognizedText(textElement, selection: selection)
        handwritingBuffer.clear()
    }

    private func insertRecognizedShape(
        _ shape: ShapeModel,
        fallbackStroke: FreehandStroke,
        selection: CanvasSelectionModel
    ) {
        let frame = shape.frame.standardized
        guard frame.width >= CanvasShapeLayout.minWidth, frame.height >= CanvasShapeLayout.minHeight else {
            _ = insertPersistedFreehandStroke(fallbackStroke, selection: selection)
            return
        }
        var payload = ShapePayload.default
        payload.kind = shape.kind
        let shapeID = UUID()
        let record = CanvasElementRecord(
            id: shapeID,
            kind: .shape,
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height,
            zIndex: nextZIndex(),
            shapePayload: payload
        )
        withAnimation(.easeInOut(duration: 0.18)) {
            applyBoardMutation { state in
                if !shape.consumedStrokeElementIDs.isEmpty {
                    state.elements.removeAll { shape.consumedStrokeElementIDs.contains($0.id) }
                }
                state.elements.append(record)
            }
        }
        selection.selectOnly(shapeID)
    }

    private func insertRecognizedText(_ textElement: TextElement, selection: CanvasSelectionModel) {
        guard !textElement.text.isEmpty else { return }
        let frame = textElement.frame.standardized
        let width = max(frame.width, CanvasTextBlockLayout.minWidth)
        let height = max(frame.height, CanvasTextBlockLayout.minHeight)
        var payload = TextBlockPayload.default
        payload.text = textElement.text
        let textID = UUID()
        let record = CanvasElementRecord(
            id: textID,
            kind: .textBlock,
            x: frame.minX,
            y: frame.minY,
            width: width,
            height: height,
            zIndex: nextZIndex(),
            textBlock: payload
        )
        withAnimation(.easeInOut(duration: 0.18)) {
            applyBoardMutation { state in
                state.elements.append(record)
            }
        }
        selection.selectOnly(textID)
        editingStickyNoteElementID = nil
        editingConnectorLabelElementID = nil
        editingTextElementID = textID
    }

    @discardableResult
    private func insertPersistedFreehandStroke(
        _ stroke: FreehandStroke,
        selection: CanvasSelectionModel
    ) -> (id: UUID, bounds: CGRect) {
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
            strokePayload: payload
        )
        applyBoardMutation { state in
            state.elements.append(record)
        }
        selection.selectOnly(id)
        return (id, CGRect(x: originX, y: originY, width: w, height: h))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
