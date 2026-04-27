import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export appearance (matches live app chrome)

@MainActor
private enum CanvasExportAppearance {
    static func resolvedAppearance() -> (colorScheme: ColorScheme, tokens: FlowDeskAppearanceTokens) {
        let modeRaw = UserDefaults.standard.string(forKey: "FlowDesk.appearance.mode")
            ?? FlowDeskAppearanceMode.system.rawValue
        let mode = FlowDeskAppearanceMode(rawValue: modeRaw) ?? .system
        let colorScheme: ColorScheme
        switch mode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? .dark
                : .light
        }
        let presetRaw = UserDefaults.standard.string(forKey: "FlowDesk.appearance.stylePreset")
            ?? FlowDeskStylePreset.warmPaper.rawValue
        let preset = FlowDeskStylePreset(rawValue: presetRaw) ?? .warmPaper
        let tokens = FlowDeskAppearanceTokens.resolve(colorScheme: colorScheme, preset: preset)
        return (colorScheme, tokens)
    }
}

/// Renders a snapshot of `CanvasBoardState` off-screen and writes PNG/PDF via the system save panel.
/// Does not mutate documents or live canvas UI state.
@MainActor
enum CanvasExportService {
    enum Format {
        case png
        case pdf
        case jpeg

        var utType: UTType {
            switch self {
            case .png: return .png
            case .pdf: return .pdf
            case .jpeg: return .jpeg
            }
        }

        var pathExtension: String {
            switch self {
            case .png: return "png"
            case .pdf: return "pdf"
            case .jpeg: return "jpg"
            }
        }

        var displayName: String {
            switch self {
            case .png: return "PNG"
            case .pdf: return "PDF"
            case .jpeg: return "JPEG"
            }
        }
    }

    enum Scope: String, CaseIterable, Identifiable {
        case entireCanvas
        case selectedOnly
        case visibleViewport

        var id: String { rawValue }
    }

    enum Quality: String, CaseIterable, Identifiable {
        case standard
        case high
        case retina

        var id: String { rawValue }

        var renderScale: CGFloat {
            switch self {
            case .standard: return 1
            case .high: return 1.5
            case .retina: return 2
            }
        }
    }

    struct Options {
        var format: Format
        var scope: Scope
        var includeBackground: Bool
        var transparentBackground: Bool
        var includeGrid: Bool
        var quality: Quality
        var selectedElementIDs: Set<UUID>
        var viewportSnapshot: CanvasInsertionViewportSnapshot?

        static let `default` = Options(
            format: .png,
            scope: .entireCanvas,
            includeBackground: true,
            transparentBackground: false,
            includeGrid: false,
            quality: .high,
            selectedElementIDs: [],
            viewportSnapshot: nil
        )
    }

    struct RenderPreview {
        let image: NSImage
        let pixelSize: CGSize
    }

    struct ExportSuccess {
        let url: URL
        let format: Format
    }

    enum ExportError: LocalizedError {
        case unsupportedSelectionScope
        case unsupportedViewportScope
        case emptySelection
        case renderFailed
        case encodeFailed
        case userCancelled
        case saveFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedSelectionScope:
                return "Selected objects export is not available for this board state."
            case .unsupportedViewportScope:
                return "Visible viewport export is not available because the viewport could not be resolved."
            case .emptySelection:
                return "Select one or more objects to export only the selection."
            case .renderFailed:
                return "InkNoMi couldn't render the export preview. Please try again."
            case .encodeFailed:
                return "InkNoMi couldn't encode this file format."
            case .userCancelled:
                return "Export was cancelled."
            case .saveFailed(let details):
                return "InkNoMi couldn't save the export. \(details)"
            }
        }
    }

    struct ScopeAvailability {
        let selectedOnlyEnabled: Bool
        let visibleViewportEnabled: Bool
    }

    static func availability(
        boardState: CanvasBoardState,
        selectedElementIDs: Set<UUID>,
        viewportSnapshot: CanvasInsertionViewportSnapshot?
    ) -> ScopeAvailability {
        let hasSelectable = !selectedElements(from: boardState.elements, ids: selectedElementIDs).isEmpty
        let hasViewport = CanvasExportBounds.viewportRect(from: viewportSnapshot) != nil
        return ScopeAvailability(
            selectedOnlyEnabled: hasSelectable,
            visibleViewportEnabled: hasViewport
        )
    }

    static func defaultFileName(documentTitle: String) -> String {
        let baseName = sanitizedFileName(documentTitle)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(baseName)_\(formatter.string(from: Date()))"
    }

    static func renderPreview(
        boardState: CanvasBoardState,
        options: Options
    ) -> Result<RenderPreview, ExportError> {
        if let validationError = validate(boardState: boardState, options: options) {
            return .failure(validationError)
        }
        guard let image = renderExportImage(boardState: boardState, options: options) else {
            return .failure(.renderFailed)
        }
        let pixels = pixelSize(for: image)
        return .success(RenderPreview(image: image, pixelSize: pixels))
    }

    static func exportWithSavePanel(
        boardState: CanvasBoardState,
        documentTitle: String,
        options: Options
    ) -> Result<ExportSuccess, ExportError> {
        if let validationError = validate(boardState: boardState, options: options) {
            return .failure(validationError)
        }
        let renderResult = renderPreview(boardState: boardState, options: options)
        let image: NSImage
        switch renderResult {
        case .success(let preview):
            image = preview.image
        case .failure(let error):
            return .failure(error)
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Export \(options.format.displayName)"
        let defaultName = "\(defaultFileName(documentTitle: documentTitle)).\(options.format.pathExtension)"
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [options.format.utType]
        panel.allowsOtherFileTypes = false
        panel.message = "Choose where to save your export."

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return .failure(.userCancelled)
        }

        switch options.format {
        case .png:
            guard writePNG(image, to: url) else { return .failure(.saveFailed("Please check your destination path.")) }
        case .pdf:
            guard writePDF(from: image, to: url) else { return .failure(.saveFailed("Please check your destination path.")) }
        case .jpeg:
            guard writeJPEG(from: image, to: url) else { return .failure(.saveFailed("Please check your destination path.")) }
        }
        return .success(ExportSuccess(url: url, format: options.format))
    }

    // MARK: - Rendering

    static func renderExportImage(boardState: CanvasBoardState, options: Options) -> NSImage? {
        let scopedElements = elementsForScope(boardState: boardState, options: options)
        let rect = exportRect(boardState: boardState, scopedElements: scopedElements, options: options)
        let appearance = CanvasExportAppearance.resolvedAppearance()
        let includeBackground = options.includeBackground || (options.format == .jpeg)
        let includeGrid = includeBackground && options.includeGrid
        let content = CanvasBoardExportContentView(
            boardState: CanvasBoardState(
                formatVersion: boardState.formatVersion,
                viewport: boardState.viewport,
                elements: scopedElements,
                boardTemplate: boardState.boardTemplate
            ),
            exportRect: rect,
            tokens: appearance.tokens,
            colorScheme: appearance.colorScheme,
            includeBackground: includeBackground,
            includeGrid: includeGrid
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = max(0.5, options.quality.renderScale)
        renderer.proposedSize = ProposedViewSize(
            width: rect.width,
            height: rect.height
        )
        return renderer.nsImage
    }

    // MARK: - Writers

    @discardableResult
    static func writePNG(_ image: NSImage, to url: URL) -> Bool {
        guard let data = pngData(from: image) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            NSSound.beep()
            return false
        }
    }

    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .png, properties: [.compressionFactor: 1])
    }

    @discardableResult
    static func writeJPEG(from image: NSImage, to url: URL) -> Bool {
        guard let data = jpegData(from: image) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            NSSound.beep()
            return false
        }
    }

    static func jpegData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }

    /// Single-page PDF embedding a **raster** of the same bitmap as PNG (Swift Charts / rich text are not vectorized in v1).
    @discardableResult
    static func writePDF(from image: NSImage, to url: URL) -> Bool {
        guard let page = PDFPage(image: image) else { return false }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        return doc.write(to: url)
    }

    // MARK: - Filename

    private static func sanitizedFileName(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Board" : trimmed
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return base
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func pixelSize(for image: NSImage) -> CGSize {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        return image.size
    }

    private static func exportRect(
        boardState: CanvasBoardState,
        scopedElements: [CanvasElementRecord],
        options: Options
    ) -> CGRect {
        switch options.scope {
        case .entireCanvas, .selectedOnly:
            return CanvasExportBounds.exportRect(elements: scopedElements)
        case .visibleViewport:
            return CanvasExportBounds.viewportRect(from: options.viewportSnapshot)
                ?? CanvasExportBounds.exportRect(elements: scopedElements)
        }
    }

    private static func elementsForScope(
        boardState: CanvasBoardState,
        options: Options
    ) -> [CanvasElementRecord] {
        switch options.scope {
        case .entireCanvas, .visibleViewport:
            return boardState.elements
        case .selectedOnly:
            return selectedElements(from: boardState.elements, ids: options.selectedElementIDs)
        }
    }

    private static func selectedElements(
        from elements: [CanvasElementRecord],
        ids: Set<UUID>
    ) -> [CanvasElementRecord] {
        guard !ids.isEmpty else { return [] }
        return elements.filter { ids.contains($0.id) }
    }

    private static func validate(boardState: CanvasBoardState, options: Options) -> ExportError? {
        switch options.scope {
        case .entireCanvas:
            return nil
        case .selectedOnly:
            let selected = selectedElements(from: boardState.elements, ids: options.selectedElementIDs)
            return selected.isEmpty ? .emptySelection : nil
        case .visibleViewport:
            return CanvasExportBounds.viewportRect(from: options.viewportSnapshot) == nil ? .unsupportedViewportScope : nil
        }
    }
}
