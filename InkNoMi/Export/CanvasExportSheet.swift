import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class CanvasExportSheetViewModel: Identifiable {
    let id = UUID()
    let boardState: CanvasBoardState
    let documentTitle: String

    var options: CanvasExportService.Options
    var fileNameBase: String
    var previewImage: NSImage?
    var previewPixelLabel: String = ""
    var isExporting = false
    var successMessage: String?
    var exportedURL: URL?
    var errorMessage: String?

    let selectedOnlySupported: Bool
    let visibleViewportSupported: Bool

    init(
        boardState: CanvasBoardState,
        documentTitle: String,
        selectedElementIDs: Set<UUID>,
        viewportSnapshot: CanvasInsertionViewportSnapshot?
    ) {
        self.boardState = boardState
        self.documentTitle = documentTitle
        self.fileNameBase = CanvasExportService.defaultFileName(documentTitle: documentTitle)
        var initialOptions = CanvasExportService.Options.default
        initialOptions.selectedElementIDs = selectedElementIDs
        initialOptions.viewportSnapshot = viewportSnapshot
        initialOptions.includeGrid = boardState.viewport.showGrid

        let availability = CanvasExportService.availability(
            boardState: boardState,
            selectedElementIDs: selectedElementIDs,
            viewportSnapshot: viewportSnapshot
        )
        selectedOnlySupported = availability.selectedOnlyEnabled
        visibleViewportSupported = availability.visibleViewportEnabled
        self.options = initialOptions
        refreshPreview()
    }

    func refreshPreview() {
        if options.scope == .selectedOnly, !selectedOnlySupported {
            options.scope = .entireCanvas
        }
        if options.scope == .visibleViewport, !visibleViewportSupported {
            options.scope = .entireCanvas
        }
        if !options.includeBackground {
            options.includeGrid = false
        }
        if options.format != .png {
            options.transparentBackground = false
        }
        if options.transparentBackground {
            options.includeBackground = false
            options.includeGrid = false
        }
        if options.scope == .selectedOnly, options.selectedElementIDs.isEmpty {
            errorMessage = "Selected objects export is unavailable because no objects are selected."
            return
        }

        switch CanvasExportService.renderPreview(boardState: boardState, options: options) {
        case .success(let preview):
            previewImage = preview.image
            previewPixelLabel = "\(Int(preview.pixelSize.width)) × \(Int(preview.pixelSize.height)) px"
            errorMessage = nil
        case .failure(let error):
            previewImage = nil
            previewPixelLabel = ""
            errorMessage = error.errorDescription ?? "Unable to generate export preview."
        }
    }

    func exportNow() {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        let result = CanvasExportService.exportWithSavePanel(
            boardState: boardState,
            documentTitle: documentTitle,
            options: options
        )
        switch result {
        case .success(let success):
            successMessage = "Export complete"
            exportedURL = success.url
            errorMessage = nil
        case .failure(let error):
            if case .userCancelled = error {
                return
            }
            successMessage = nil
            exportedURL = nil
            errorMessage = error.errorDescription ?? "Something went wrong while exporting."
        }
    }

    func revealInFinder() {
        guard let url = exportedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

struct CanvasExportSheet: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: CanvasExportSheetViewModel

    private var featureGate: FeatureGate {
        FeatureGate(purchaseManager: purchaseManager)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            HStack(alignment: .top, spacing: 16) {
                optionsCard
                previewCard
            }
            footer
        }
        .padding(20)
        .frame(minWidth: 900, idealWidth: 940, maxWidth: 980, minHeight: 580)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxLarge, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xxLarge, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme), lineWidth: 1)
                )
                .flowDeskDepthShadows(FlowDeskDepth.modalChrome)
        )
        .onChange(of: viewModel.options.format) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.scope) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.includeBackground) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.transparentBackground) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.includeGrid) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.quality) { _, _ in viewModel.refreshPreview() }
        .onChange(of: viewModel.options.quality) { _, quality in
            guard quality != .standard else { return }
            guard featureGate.canUse(.highResExport) else {
                _ = featureGate.requirePro(.highResExport, source: "export_quality_\(quality.rawValue)")
                viewModel.options.quality = .standard
                return
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Export board")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            Text("Choose format, scope, and quality before saving.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Export options")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)

            Picker("Format", selection: $viewModel.options.format) {
                Text("PNG").tag(CanvasExportService.Format.png)
                Text("PDF").tag(CanvasExportService.Format.pdf)
                Text("JPEG").tag(CanvasExportService.Format.jpeg)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Scope")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                HStack(spacing: 8) {
                    scopeButton(title: "Entire canvas", scope: .entireCanvas, enabled: true)
                    scopeButton(title: "Selected only", scope: .selectedOnly, enabled: viewModel.selectedOnlySupported)
                    scopeButton(title: "Visible viewport", scope: .visibleViewport, enabled: viewModel.visibleViewportSupported)
                }
            }

            if !viewModel.selectedOnlySupported {
                Text("Selected objects export is unavailable right now. Select one or more objects to enable it.")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            if !viewModel.visibleViewportSupported {
                Text("Visible viewport export is unavailable until the board viewport is fully initialized.")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Divider()

            Toggle("Include background", isOn: $viewModel.options.includeBackground)
                .toggleStyle(.switch)
            Toggle("Transparent background (PNG)", isOn: $viewModel.options.transparentBackground)
                .toggleStyle(.switch)
                .disabled(viewModel.options.format != .png)
            Toggle("Include grid", isOn: $viewModel.options.includeGrid)
                .toggleStyle(.switch)
                .disabled(!viewModel.options.includeBackground || viewModel.options.transparentBackground)

            Divider()

            Picker("Quality", selection: $viewModel.options.quality) {
                Text("Standard").tag(CanvasExportService.Quality.standard)
                Text("High (Pro)").tag(CanvasExportService.Quality.high)
                Text("Retina / 2x (Pro)").tag(CanvasExportService.Quality.retina)
            }
            .pickerStyle(.segmented)
            if !featureGate.canUse(.highResExport) {
                Text("High-resolution export is available in Pro.")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                )
        )
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DS.Color.appBackground.opacity(colorScheme == .dark ? 0.44 : 0.72))
                if let previewImage = viewModel.previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("Preview unavailable")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 330, maxHeight: 330)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
            )

            if !viewModel.previewPixelLabel.isEmpty {
                Text(viewModel.previewPixelLabel)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            if let successMessage = viewModel.successMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(successMessage)
                        .font(DS.Typography.body.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    if let exportedURL = viewModel.exportedURL {
                        Text(exportedURL.path)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.destructive)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                )
        )
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(FlowDeskToolbarButtonStyle())

            if viewModel.exportedURL != nil {
                Button("Reveal in Finder") {
                    viewModel.revealInFinder()
                }
                .buttonStyle(FlowDeskToolbarButtonStyle())
            }

            Spacer()

            Button {
                viewModel.exportNow()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isExporting {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 16, height: 16)
                            .flowDeskSkeletonShimmer()
                            .overlay {
                                ProgressView()
                                    .controlSize(.small)
                            }
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Export")
                        .font(DS.Typography.toolLabel.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DS.Color.premiumBlueGradient)
                )
                .foregroundStyle(Color.white)
            }
            .buttonStyle(FlowDeskToolbarButtonStyle())
            .disabled(viewModel.previewImage == nil || viewModel.isExporting)
        }
    }

    private func scopeButton(title: String, scope: CanvasExportService.Scope, enabled: Bool) -> some View {
        let selected = viewModel.options.scope == scope
        return Button {
            guard enabled else { return }
            viewModel.options.scope = scope
        } label: {
            Text(title)
                .font(DS.Typography.caption.weight(.semibold))
                .foregroundStyle(enabled ? (selected ? Color.white : DS.Color.textPrimary) : DS.Color.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            selected
                                ? AnyShapeStyle(DS.Color.premiumBlueGradient)
                                : AnyShapeStyle(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.8)
                )
        }
        .buttonStyle(FlowDeskToolbarButtonStyle())
        .disabled(!enabled)
    }
}
