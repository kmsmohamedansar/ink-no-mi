import SwiftUI

struct HomeView: View {
    var documents: [FlowDocument]
    var onOpenDocument: (FlowDocument) -> Void
    var onCreateTemplate: (WorkspaceTemplate) -> Void
    var onCreateBlank: () -> Void
    var onDuplicate: (FlowDocument) -> Void
    var onRename: (FlowDocument) -> Void
    var onDelete: (FlowDocument) -> Void

    enum SidebarSection: String, CaseIterable, Identifiable {
        case home
        case recent
        case templates
        case allBoards
        case favorites
        case trash
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .recent: return "Recent"
            case .templates: return "Templates"
            case .allBoards: return "All Boards"
            case .favorites: return "Favorites"
            case .trash: return "Trash"
            case .settings: return "Settings"
            }
        }

        var symbol: String {
            switch self {
            case .home: return "house"
            case .recent: return "clock"
            case .templates: return "square.grid.2x2"
            case .allBoards: return "square.stack.3d.up"
            case .favorites: return "star"
            case .trash: return "archivebox"
            case .settings: return "gearshape"
            }
        }
    }
    enum BoardSort: String, CaseIterable, Identifiable {
        case updated = "Last Edited"
        case title = "Name"
        var id: String { rawValue }
    }

    @State private var selectedSection: SidebarSection = .home
    @State private var searchQuery = ""
    @State private var boardSort: BoardSort = .updated
    @State private var gridMode = true
    @State private var hoveredQuickAction: String?
    @State private var hoveredSidebarSection: SidebarSection?
    @State private var hoveredBoardID: UUID?
    @State private var hoveredTemplateID: String?

    private var filteredDocuments: [FlowDocument] {
        let base = documents.filter {
            searchQuery.isEmpty
            || $0.title.localizedCaseInsensitiveContains(searchQuery)
            || $0.boardType.displayName.localizedCaseInsensitiveContains(searchQuery)
        }
        switch boardSort {
        case .updated: return base.sorted { $0.updatedAt > $1.updatedAt }
        case .title: return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    private var recentDocuments: [FlowDocument] {
        Array(filteredDocuments.prefix(6))
    }

    private var selectedTemplates: [WorkspaceTemplate] {
        switch selectedSection {
        case .templates:
            return WorkspaceTemplate.gallery
        case .home:
            return Array(WorkspaceTemplate.gallery.prefix(8))
        default:
            return []
        }
    }

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    heroSection
                    quickActions
                    if selectedSection == .home || selectedSection == .recent { recentSection }
                    if selectedSection == .home || selectedSection == .allBoards || selectedSection == .favorites { boardsSection }
                    if !selectedTemplates.isEmpty { templatesSection }
                    if selectedSection == .home { workflowsSection }
                    if selectedSection == .settings { settingsPlaceholder }
                }
                .padding(.horizontal, DS.Spacing.xl + DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xl)
                .frame(maxWidth: 1180, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [DS.Color.appBackground, DS.Color.canvasBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Ink no Mi")
    }
}

private extension HomeView {
    var sidebar: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
                Text("InkNoMi")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
            }
            .padding(.bottom, DS.Spacing.sm)

            ForEach(SidebarSection.allCases) { section in
                sidebarRow(section)
            }

            Spacer()
        }
        .padding(DS.Spacing.lg)
        .frame(width: 220, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large)
                        .stroke(DS.Color.border)
                )
                .shadow(color: DS.Shadow.soft.color, radius: DS.Shadow.soft.radius, x: 0, y: DS.Shadow.soft.y)
                .padding(.vertical, DS.Spacing.md)
                .padding(.leading, DS.Spacing.md)
        )
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Think visually. Create clearly.")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            Text("Sketch ideas, plan projects, map systems, and turn thoughts into structured visual workspaces.")
                .font(.system(size: 15.5))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(maxWidth: 700, alignment: .leading)

            HStack(spacing: DS.Spacing.sm) {
                ForEach(["Whiteboards", "Flowcharts", "Notes", "Planning", "Mind Maps"], id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11.5, weight: .semibold))
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(Capsule(style: .continuous).fill(DS.Color.hover))
                }
            }
            .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.Color.textSecondary)
                TextField("Search boards, templates, and ideas", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(DS.Color.panel)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border))
                    .shadow(color: DS.Shadow.soft.color.opacity(0.7), radius: 7, x: 0, y: 2)
            )
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.panel, DS.Color.canvas.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border))
            )
        }
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.xs)
    }

    var quickActions: some View {
        HStack(spacing: DS.Spacing.md) {
            quickActionCard(
                id: "new",
                title: "New Blank Canvas",
                subtitle: "Open a clean workspace and start immediately.",
                icon: "square",
                action: onCreateBlank
            )
            quickActionCard(
                id: "template",
                title: "Start from Template",
                subtitle: "Launch with ready-made layouts for real work.",
                icon: "square.grid.2x2",
                action: { selectedSection = .templates }
            )
            quickActionCard(
                id: "open",
                title: "Open Recent",
                subtitle: "Continue where you left off.",
                icon: "clock.arrow.circlepath",
                action: {
                    if let first = recentDocuments.first {
                        onOpenDocument(first)
                    }
                }
            )
        }
    }

    func quickActionCard(id: String, title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        let hovered = hoveredQuickAction == id
        return Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(id == "new" ? Color.white.opacity(0.95) : DS.Color.accent)
                    if id == "new" {
                        Text("Recommended")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, 3)
                            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.18)))
                    }
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(id == "new" ? Color.white : DS.Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(id == "new" ? Color.white.opacity(0.85) : DS.Color.textSecondary)
                    .lineLimit(2)
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(
                        id == "new"
                            ? LinearGradient(
                                colors: [DS.Color.accent.opacity(0.92), DS.Color.accent.opacity(0.76)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [DS.Color.panel], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .stroke(id == "new" ? DS.Color.accent.opacity(0.35) : DS.Color.border)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .fill(hovered ? DS.Color.hover.opacity(0.24) : Color.clear)
                    )
                    .shadow(color: DS.Shadow.soft.color.opacity(hovered ? 1.2 : 0.75), radius: hovered ? 12 : 8, x: 0, y: hovered ? 4 : 2)
            )
            .scaleEffect(hovered ? 1.015 : 1.0)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .onHover { inside in
            withAnimation(FlowDeskMotion.quickEaseOut) {
                hoveredQuickAction = inside ? id : nil
            }
        }
    }

    var recentSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Recent Canvases", subtitle: "Resume active work instantly.")
            if recentDocuments.isEmpty {
                emptyState(
                    title: "No recent boards yet",
                    detail: "Create a canvas or start from a template to begin building your visual workspace."
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                    ForEach(recentDocuments, id: \.persistentModelID) {
                        boardCard($0)
                    }
                }
            }
        }
    }

    var workflowsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Recommended workflows", subtitle: "Start from proven structures for common work.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                workflowCard("Brainstorm ideas", templateID: "brainstorm-board", icon: "bolt.fill")
                workflowCard("Plan product work", templateID: "product-roadmap", icon: "calendar")
                workflowCard("Create flowcharts", templateID: "flowchart", icon: "point.3.connected.trianglepath.dotted")
                workflowCard("Organize notes", templateID: "meeting-notes", icon: "note.text")
                workflowCard("Map systems", templateID: "mind-map", icon: "circle.hexagongrid")
                workflowCard("Design wireframes", templateID: "app-wireframe", icon: "iphone.gen3")
            }
        }
    }

    func workflowCard(_ title: String, templateID: String, icon: String) -> some View {
        Button {
            if let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
                onCreateTemplate(template)
            }
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(DS.Color.accent)
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(DS.Color.panel)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border))
            )
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
    }

    var boardsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                sectionHeader(
                    selectedSection == .favorites ? "Favorites" : "All Boards",
                    subtitle: "Search, sort, and reopen your work."
                )
                Spacer()
                Picker("Sort", selection: $boardSort) {
                    ForEach(BoardSort.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)
                Button {
                    withAnimation(FlowDeskMotion.quickEaseOut) {
                        gridMode.toggle()
                    }
                } label: {
                    Image(systemName: gridMode ? "list.bullet" : "square.grid.2x2")
                }
                .buttonStyle(.plain)
            }

            let source = selectedSection == .favorites ? filteredDocuments.filter(\.isFavorite) : filteredDocuments
            if source.isEmpty {
                emptyState(
                    title: "No canvases in this view",
                    detail: "Try another filter or create a new canvas from the quick actions above."
                )
            } else if gridMode {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                    ForEach(source, id: \.persistentModelID) {
                        boardCard($0)
                    }
                }
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    ForEach(source, id: \.persistentModelID) {
                        boardListRow($0)
                    }
                }
            }
        }
    }

    var templatesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Template Library", subtitle: "Start from polished structures, not an empty page.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                ForEach(selectedTemplates) { template in
                    let hovered = hoveredTemplateID == template.id
                    Button {
                        onCreateTemplate(template)
                    } label: {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [DS.Color.active.opacity(0.82), DS.Color.panel.opacity(0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 82)
                                .overlay {
                                    templatePreview(for: template)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                        .stroke(DS.Color.accent.opacity(0.2))
                                )

                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(DS.Color.accent)
                                Text(template.category.displayName.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(0.7)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                            Text(template.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text(template.description)
                                .font(.system(size: 12.5))
                                .foregroundStyle(DS.Color.textSecondary)
                                .lineLimit(2)
                            Text("Use this template")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Color.accent)
                        }
                        .padding(DS.Spacing.lg)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.large)
                                .fill(DS.Color.panel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.large)
                                        .fill(hovered ? DS.Color.hover.opacity(0.2) : Color.clear)
                                )
                                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border))
                                .shadow(color: DS.Shadow.soft.color.opacity(hovered ? 1.2 : 0.8), radius: hovered ? 10 : 7, x: 0, y: hovered ? 4 : 2)
                        )
                        .scaleEffect(hovered ? 1.014 : 1)
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .onHover { inside in
                        withAnimation(FlowDeskMotion.quickEaseOut) {
                            hoveredTemplateID = inside ? template.id : nil
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func templatePreview(for template: WorkspaceTemplate) -> some View {
        switch template.boardType {
        case .flowchart, .diagram:
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.accent.opacity(0.28)).frame(width: 26, height: 16)
                Image(systemName: "arrow.right").font(.system(size: 9, weight: .semibold)).foregroundStyle(DS.Color.textSecondary.opacity(0.7))
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.accent.opacity(0.2)).frame(width: 30, height: 16)
                Image(systemName: "arrow.right").font(.system(size: 9, weight: .semibold)).foregroundStyle(DS.Color.textSecondary.opacity(0.7))
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.accent.opacity(0.16)).frame(width: 26, height: 16)
            }
        case .notes:
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.18)).frame(width: 90, height: 6)
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.14)).frame(width: 74, height: 6)
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.11)).frame(width: 58, height: 6)
            }
        case .mindMap:
            HStack(spacing: 7) {
                Circle().fill(DS.Color.accent.opacity(0.28)).frame(width: 16, height: 16)
                Circle().fill(DS.Color.accent.opacity(0.2)).frame(width: 12, height: 12)
                Circle().fill(DS.Color.accent.opacity(0.16)).frame(width: 12, height: 12)
                Circle().fill(DS.Color.accent.opacity(0.12)).frame(width: 12, height: 12)
            }
        default:
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.22)).frame(width: 22, height: 14)
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.17)).frame(width: 22, height: 14)
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.12)).frame(width: 22, height: 14)
            }
        }
    }

    var settingsPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Workspace Settings", subtitle: "Appearance and workspace behavior")
            Text("Open app settings to adjust appearance and your working environment.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.textSecondary)
                .padding(DS.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DS.Radius.large).fill(DS.Color.panel))
        }
    }

    func boardCard(_ document: FlowDocument) -> some View {
        let hovered = hoveredBoardID == document.id
        return Button {
            onOpenDocument(document)
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.accent.opacity(0.14), DS.Color.panel],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 106)
                    .overlay {
                        Image(systemName: "scribble.variable")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Color.accent.opacity(0.85))
                    }

                HStack {
                    Text(document.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if document.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(DS.Color.accent)
                    }
                }
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11.5))
                    .foregroundStyle(DS.Color.textSecondary)
                Text(document.boardType.displayName)
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.45)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs - 1)
                    .background(Capsule().fill(DS.Color.hover))
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(DS.Color.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .fill(hovered ? DS.Color.hover.opacity(0.22) : Color.clear)
                    )
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border))
                    .shadow(color: DS.Shadow.soft.color.opacity(hovered ? 1.15 : 0.85), radius: hovered ? 11 : 7, x: 0, y: hovered ? 4 : 2)
            )
            .scaleEffect(hovered ? 1.014 : 1)
        }
        .contextMenu {
            Button("Open") { onOpenDocument(document) }
            Button("Duplicate") { onDuplicate(document) }
            Button("Rename…") { onRename(document) }
            Divider()
            Button("Delete", role: .destructive) { onDelete(document) }
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .onHover { inside in
            withAnimation(FlowDeskMotion.quickEaseOut) {
                hoveredBoardID = inside ? document.id : nil
            }
        }
    }

    func boardListRow(_ document: FlowDocument) -> some View {
        Button {
            onOpenDocument(document)
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(DS.Color.accent.opacity(0.85))
                Text(document.title)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Text(document.boardType.displayName)
                    .font(.system(size: 11.5))
                    .foregroundStyle(DS.Color.textSecondary)
                Text(document.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11.5))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(DS.Color.panel)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") { onOpenDocument(document) }
            Button("Duplicate") { onDuplicate(document) }
            Button("Rename…") { onRename(document) }
            Divider()
            Button("Delete", role: .destructive) { onDelete(document) }
        }
    }

    func sectionHeader(_ text: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(text)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(subtitle)
                .font(.system(size: 12.5))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    func emptyState(title: String, detail: String) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(DS.Color.textSecondary.opacity(0.75))
            Text(title)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(DS.Color.panel)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border))
        )
    }

    func sidebarRow(_ section: SidebarSection) -> some View {
        let active = selectedSection == section
        let hovered = hoveredSidebarSection == section
        return Button {
            withAnimation(FlowDeskMotion.smoothEaseOut) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: section.symbol)
                    .frame(width: 16)
                Text(section.title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(active ? DS.Color.accent.opacity(0.12) : (hovered ? DS.Color.hover.opacity(0.82) : .clear))
            )
            .scaleEffect(hovered ? 1.014 : 1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? DS.Color.accent : DS.Color.textPrimary.opacity(0.86))
        .onHover { inside in
            withAnimation(FlowDeskMotion.quickEaseOut) {
                hoveredSidebarSection = inside ? section : nil
            }
        }
    }
}
