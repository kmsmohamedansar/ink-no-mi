import SwiftUI

struct NewBoardDraft: Equatable {
    enum StartMode: String, CaseIterable, Identifiable {
        case blank
        case template

        var id: String { rawValue }
        var title: String {
            switch self {
            case .blank: return "Start blank"
            case .template: return "Start from template"
            }
        }
    }

    enum BackgroundStyle: String, CaseIterable, Identifiable {
        case classicGrid
        case minimal
        case focus

        var id: String { rawValue }
        var title: String {
            switch self {
            case .classicGrid: return "Classic Grid"
            case .minimal: return "Minimal"
            case .focus: return "Focus"
            }
        }
    }

    var name: String
    var boardType: BoardType
    var startMode: StartMode
    var backgroundStyle: BackgroundStyle
    var selectedTemplateID: String?
}

struct NewBoardSheetView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    @State private var draft = NewBoardDraft(
        name: "",
        boardType: .whiteboard,
        startMode: .blank,
        backgroundStyle: .classicGrid,
        selectedTemplateID: nil
    )

    let onCancel: () -> Void
    let onCreate: (NewBoardDraft) -> Void

    private var suggestedTemplates: [WorkspaceTemplate] {
        WorkspaceTemplate.gallery.filter { $0.boardType == draft.boardType }
    }

    private var defaultName: String {
        "Untitled \(draft.boardType.displayName)"
    }

    private var resolvedName: String {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultName : trimmed
    }

    private var selectedTemplate: WorkspaceTemplate? {
        guard let id = draft.selectedTemplateID else { return nil }
        return WorkspaceTemplate.gallery.first(where: { $0.id == id })
    }

    private var isCreateDisabled: Bool {
        draft.startMode == .template && selectedTemplate == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.35)
            HStack(spacing: 0) {
                leftColumn
                Divider().opacity(0.3)
                rightColumn
            }
            .frame(minHeight: 430)
            footer
        }
        .frame(width: 860)
        .background(tokens.workspaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onChange(of: draft.boardType) { _, _ in
            if draft.startMode == .template {
                draft.selectedTemplateID = suggestedTemplates.first?.id
            }
        }
        .onChange(of: draft.startMode) { _, mode in
            if mode == .template, draft.selectedTemplateID == nil {
                draft.selectedTemplateID = suggestedTemplates.first?.id
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Workspace")
                    .font(.system(size: 24, weight: .bold))
                Text("Choose how you want to start this board.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.4 : 0.22))
    }

    private var leftColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                fieldTitle("Workspace name")
                TextField(defaultName, text: $draft.name)
                    .textFieldStyle(.roundedBorder)

                fieldTitle("Board type")
                Picker("Board type", selection: $draft.boardType) {
                    ForEach([BoardType.whiteboard, .flowchart, .notes, .roadmap, .mindMap, .kanban], id: \.id) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)

                fieldTitle("Start mode")
                HStack(spacing: 10) {
                    ForEach(NewBoardDraft.StartMode.allCases) { mode in
                        Button {
                            draft.startMode = mode
                        } label: {
                            Text(mode.title)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(draft.startMode == mode ? tokens.accent.opacity(0.14) : Color.primary.opacity(0.06))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(draft.startMode == mode ? tokens.accent.opacity(0.4) : Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                fieldTitle("Theme / background")
                Picker("Theme", selection: $draft.backgroundStyle) {
                    ForEach(NewBoardDraft.BackgroundStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                if draft.startMode == .template {
                    fieldTitle("Suggested templates")
                    if suggestedTemplates.isEmpty {
                        Text("No templates for this type yet. Switch to blank or pick another type.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(suggestedTemplates) { template in
                                Button {
                                    draft.selectedTemplateID = template.id
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: template.icon)
                                            .frame(width: 18)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(template.title)
                                                    .font(.system(size: 13, weight: .semibold))
                                                if template.isProTemplate && !purchaseManager.isProUser {
                                                    Text("PRO")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            Capsule(style: .continuous)
                                                                .fill(tokens.accent.opacity(0.14))
                                                        )
                                                        .foregroundStyle(tokens.accent)
                                                }
                                            }
                                            Text(templateRowSubtitle(template))
                                                .font(.system(size: 11, weight: .regular))
                                                .lineLimit(1)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(draft.selectedTemplateID == template.id ? tokens.accent.opacity(0.12) : Color.primary.opacity(0.05))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tokens.homeCardFill, Color.white.opacity(colorScheme == .dark ? 0.03 : 0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resolvedName)
                            .font(.system(size: 20, weight: .bold))
                        Text(draft.boardType.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(tokens.accent)
                        Text(draft.startMode == .template ? (selectedTemplate?.title ?? "Pick a template") : "Blank board")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            tag("Theme: \(draft.backgroundStyle.title)")
                            if let selectedTemplate {
                                tag(selectedTemplate.category.displayName)
                            }
                        }
                    }
                    .padding(16)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var footer: some View {
        HStack {
            Text("This workspace will open immediately after creation.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Create Workspace") {
                onCreate(draft)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreateDisabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.28 : 0.2))
    }

    private func fieldTitle(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.7)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.08)))
    }

    private func templateRowSubtitle(_ template: WorkspaceTemplate) -> String {
        if template.isProTemplate && !purchaseManager.isProUser {
            return "\(template.description) - Requires Pro"
        }
        return template.description
    }
}
