import SwiftUI

struct HomeView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("InkNoMi.ProHintDismissed") private var proHintDismissed = false

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
            case .trash: return "trash"
            case .settings: return "gearshape"
            }
        }
    }
    enum HomeFilter: String, CaseIterable, Identifiable {
        case whiteboards = "Whiteboards"
        case templates = "Templates"
        case recents = "Recents"
        var id: String { rawValue }
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
    @State private var hoveredIntentChip: String?
    @State private var hoveredStarterTemplateID: String?
    @State private var hoveredWorkflowID: String?
    @State private var selectedFilter: HomeFilter = .whiteboards
    @State private var hoveredFilter: HomeFilter?
    @State private var creationPromptText = ""

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
        if selectedFilter == .templates {
            return WorkspaceTemplate.gallery
        }
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
        ZStack {
            creationBackground
            HStack(spacing: DS.Spacing.grid) {
                sidebar
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.section) {
                        topFilterChips
                        creationPromptCard
                        quickActions
                        if selectedSection == .home || selectedSection == .recent || selectedFilter == .recents { recentSection }
                        if selectedSection == .home || selectedSection == .allBoards || selectedSection == .favorites || selectedFilter == .whiteboards {
                            boardsSection
                        }
                        if !selectedTemplates.isEmpty { templatesSection }
                        if selectedSection == .trash { trashSection }
                        if selectedSection == .settings { settingsPlaceholder }
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.vertical, DS.Spacing.section)
                    .frame(maxWidth: 1220, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Ink no Mi")
    }
}

private extension HomeView {
    var creationBackground: some View {
        ZStack {
            DS.Color.homeMainBackground
            RadialGradient(
                colors: [
                    Color.white.opacity(0.92),
                    DS.Color.homeMainBackground.opacity(0.98),
                    DS.Color.homeMainBackgroundEdge.opacity(0.92)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 940
            )
            Circle()
                .fill(DS.Color.homeGlowBlue)
                .blur(radius: 70)
                .frame(width: 380, height: 380)
                .offset(x: -250, y: -160)
            Circle()
                .fill(DS.Color.homeGlowPurple)
                .blur(radius: 80)
                .frame(width: 420, height: 420)
                .offset(x: 340, y: -120)
            RadialGradient(
                colors: [DS.Color.accent.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.52, y: 0.43),
                startRadius: 0,
                endRadius: 360
            )
            RadialGradient(
                colors: [
                    Color.clear,
                    DS.Color.backgroundVignette.opacity(0.55)
                ],
                center: .center,
                startRadius: 380,
                endRadius: 980
            )
            creationGridOverlay
        }
        .ignoresSafeArea()
    }

    var creationGridOverlay: some View {
        GeometryReader { geometry in
            Path { path in
                let step: CGFloat = 34
                var x: CGFloat = 0
                while x <= geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += step
                }
            }
            .stroke(DS.Color.homeMainGrid, lineWidth: 0.72)
        }
        .opacity(0.30)
        .allowsHitTesting(false)
    }

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

            if !purchaseManager.isProUser {
                Button {
                    purchaseManager.requestedFeature = nil
                    purchaseManager.isPaywallPresented = true
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Upgrade")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                            .fill(DS.Color.active)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.accent)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.lg)
        .frame(width: 240, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            DS.Color.homeSidebarSurface
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(DS.Color.homeSidebarBorder)
                        .frame(width: 1)
                }
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        )
    }

    var topFilterChips: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(HomeFilter.allCases) { filter in
                let active = selectedFilter == filter
                let hovered = hoveredFilter == filter
                Button {
                    withAnimation(FlowDeskMotion.quickEaseOut) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(active ? DS.Color.accent : DS.Color.textSecondary)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(active ? DS.Color.homeChipActive : (hovered ? DS.Color.homeChipHover : DS.Color.homeChipFill))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(active ? DS.Color.accent.opacity(0.32) : DS.Color.borderSubtle.opacity(0.35))
                                )
                        )
                        .scaleEffect(hovered ? 1.02 : 1)
                }
                .buttonStyle(.plain)
                .onHover { inside in
                    hoveredFilter = inside ? filter : nil
                }
            }
        }
    }

    var creationPromptCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Start creating")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-0.6)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Capture an idea, pick a template, then jump straight into your board.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(DS.Color.accent)
                TextField("What do you want to map out?", text: $creationPromptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                Button {
                    onCreateBlank()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(creationPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? DS.Color.textTertiary : .white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(creationPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? DS.Color.homeChipHover : DS.Color.accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(creationPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DS.Color.homePromptInputFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(DS.Color.accent.opacity(0.24), lineWidth: 1.1)
                    )
                        .shadow(color: DS.Color.accent.opacity(0.10), radius: 14, x: 0, y: 5)
            )

            HStack(spacing: DS.Spacing.md) {
                Label("Whiteboard", systemImage: "square.on.square")
                Label("Flow", systemImage: "point.3.connected.trianglepath.dotted")
                Label("Notes", systemImage: "note.text")
                Label("Wireframe", systemImage: "rectangle.3.group")
            }
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Spacing.sm) {
                intentChip("Brainstorm", templateID: "brainstorm-board")
                intentChip("Flowchart", templateID: "flowchart")
                intentChip("Planning", templateID: "product-roadmap")
                intentChip("Meeting notes", templateID: "meeting-notes")
            }

            HStack(spacing: DS.Spacing.sm) {
                Button("Start blank canvas") {
                    onCreateBlank()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(DS.Color.accent)
                )
                .shadow(color: DS.Color.accent.opacity(0.33), radius: 10, x: 0, y: 4)

                Button("Use template") {
                    selectedSection = .templates
                }
                .buttonStyle(.plain)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxLarge, style: .continuous)
                .fill(DS.Color.homePromptFill)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xxLarge, style: .continuous)
                        .stroke(DS.Color.accent.opacity(0.16))
                )
                .shadow(color: Color.black.opacity(0.10), radius: 24, x: 0, y: 11)
        )
    }

    func intentChip(_ title: String, templateID: String) -> some View {
        let hovered = hoveredIntentChip == templateID
        return Button {
            if let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
                onCreateTemplate(template)
            }
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary.opacity(0.85))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .overlay(Capsule(style: .continuous).stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(hovered ? 0.10 : 0.06), radius: hovered ? 10 : 6, x: 0, y: hovered ? 4 : 2)
                )
                .scaleEffect(hovered ? 1.02 : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .animation(.easeOut(duration: 0.18), value: hovered)
        .onHover { inside in
            hoveredIntentChip = inside ? templateID : nil
        }
    }

    var quickActions: some View {
        HStack(spacing: DS.Spacing.grid) {
            quickActionCard(
                id: "new",
                title: "Start a new workspace",
                subtitle: "Open a fresh board and shape your ideas your way.",
                icon: "square",
                action: onCreateBlank
            )
            quickActionCard(
                id: "template",
                title: "Start from Template",
                subtitle: "Launch with ready-made layouts for real work. Advanced templates (Pro).",
                icon: "square.grid.2x2",
                action: { selectedSection = .templates }
            )
            quickActionCard(
                id: "open",
                title: "Open Recent",
                subtitle: recentDocuments.isEmpty ? "Create your first board to start building momentum." : "Continue where you left off.",
                icon: "clock.arrow.circlepath",
                enabled: !recentDocuments.isEmpty,
                action: {
                    if let first = recentDocuments.first {
                        onOpenDocument(first)
                    }
                }
            )
        }
        .padding(.top, -4)
    }

    func quickActionCard(
        id: String,
        title: String,
        subtitle: String,
        icon: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        let hovered = hoveredQuickAction == id
        return Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
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
                if id == "new" {
                    HStack(spacing: 6) {
                        Text("Start now")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.white.opacity(0.95))
                }
            }
            .padding(DS.Spacing.cardPadding + 1)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(
                        id == "new"
                            ? LinearGradient(
                                colors: [Color(red: 0.30, green: 0.58, blue: 1.0), Color(red: 0.18, green: 0.42, blue: 0.98)],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.92), Color.white.opacity(0.80)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .stroke(id == "new" ? DS.Color.accent.opacity(0.52) : DS.Color.borderSubtle.opacity(0.24))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .fill(hovered ? DS.Color.hover.opacity(0.16) : Color.clear)
                    )
                    .shadow(
                        color: Color.black.opacity(id == "new" ? (hovered ? 0.27 : 0.22) : (hovered ? 0.14 : 0.10)),
                        radius: id == "new" ? (hovered ? 40 : 33) : (hovered ? 19 : 13),
                        x: 0,
                        y: id == "new" ? (hovered ? 19 : 15) : (hovered ? 7 : 4)
                    )
            )
            .brightness(hovered ? 0.016 : 0)
            .offset(y: hovered ? -2.2 : 0)
            .scaleEffect(enabled && hovered ? (id == "new" ? 1.028 : 1.02) : 1.0)
            .opacity(enabled ? 1 : 0.64)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .disabled(!enabled)
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.18)) {
                hoveredQuickAction = inside && enabled ? id : nil
            }
        }
    }

    var recentSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Recent", subtitle: purchaseManager.isProUser ? "Jump back in quickly." : "Jump back in quickly. Unlimited boards (Pro).")
            if recentDocuments.isEmpty {
                compactEmptyState(
                    title: "No recent boards yet.",
                    detail: "Start blank or use a template to create your first board."
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DS.Spacing.grid)], spacing: DS.Spacing.grid) {
                    ForEach(recentDocuments, id: \.persistentModelID) {
                        boardCard($0)
                    }
                }
            }
        }
    }

    var starterWorkspacesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Start your first workspace", subtitle: "Pick a starting point and jump straight into creation.")
            HStack(spacing: DS.Spacing.grid) {
                starterTemplateCard(
                    title: "Brainstorm ideas",
                    subtitle: "Capture fast thoughts and connect concepts instantly.",
                    templateID: "brainstorm-board",
                    icon: "bolt.fill"
                )
                starterTemplateCard(
                    title: "Plan a project",
                    subtitle: "Set priorities, milestones, and next actions quickly.",
                    templateID: "product-roadmap",
                    icon: "calendar"
                )
                starterTemplateCard(
                    title: "Create a flowchart",
                    subtitle: "Map decisions and process paths with clear structure.",
                    templateID: "flowchart",
                    icon: "point.3.connected.trianglepath.dotted"
                )
            }
            Text("Create your first board to unlock more templates.")
                .font(DS.Typography.label)
                .tracking(DS.Typography.labelTracking)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.xs)
        }
    }

    func starterTemplateCard(title: String, subtitle: String, templateID: String, icon: String) -> some View {
        Button {
            if let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
                onCreateTemplate(template)
            }
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DS.Color.accent)
                    Text(title)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("Open template")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
            }
            .padding(DS.Spacing.cardPadding)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.creationCardSurface, DS.Color.creationCardSurface.opacity(0.86)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.creationCardBorder.opacity(0.22)))
                    .shadow(color: Color.black.opacity(0.09), radius: 12, x: 0, y: 5)
            )
            .brightness((hoveredStarterTemplateID == templateID) ? 0.012 : 0)
            .offset(y: (hoveredStarterTemplateID == templateID) ? -2 : 0)
            .scaleEffect((hoveredStarterTemplateID == templateID) ? 1.02 : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .animation(.easeOut(duration: 0.18), value: hoveredStarterTemplateID == templateID)
        .onHover { inside in
            hoveredStarterTemplateID = inside ? templateID : nil
        }
    }

    var workflowsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Recommended workflows", subtitle: "Start from proven structures for common work.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: DS.Spacing.grid)], spacing: DS.Spacing.grid) {
                workflowCard("Brainstorm ideas", templateID: "brainstorm-board", icon: "bolt.fill")
                workflowCard("Plan product work", templateID: "product-roadmap", icon: "calendar")
                workflowCard("Create flowcharts", templateID: "flowchart", icon: "point.3.connected.trianglepath.dotted")
                workflowCard("Organize notes", templateID: "meeting-notes", icon: "note.text")
                workflowCard("Map systems", templateID: "mind-map", icon: "circle.hexagongrid")
                workflowCard("Design wireframes", templateID: "app-wireframe", icon: "iphone.gen3")
            }
        }
    }

    var proHintBanner: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Go further with InkNoMi Pro")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Unlimited boards and advanced templates when you need them.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            Button("Upgrade") {
                purchaseManager.requestedFeature = nil
                purchaseManager.isPaywallPresented = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(DS.Color.accent)

            Button {
                proHintDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme))
                )
        )
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
            .padding(DS.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.creationCardSurface, DS.Color.creationCardSurface.opacity(0.86)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.creationCardBorder.opacity(0.2)))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .brightness(hoveredWorkflowID == templateID ? 0.01 : 0)
            .offset(y: hoveredWorkflowID == templateID ? -1.6 : 0)
            .scaleEffect(hoveredWorkflowID == templateID ? 1.02 : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .animation(.easeOut(duration: 0.18), value: hoveredWorkflowID == templateID)
        .onHover { inside in
            hoveredWorkflowID = inside ? templateID : nil
        }
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
                    title: "No boards in this view",
                    detail: "Try another filter or create a new board."
                )
            } else if gridMode {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DS.Spacing.grid)], spacing: DS.Spacing.grid) {
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
            sectionHeader("Template Library", subtitle: "Pick a structured starting point and customize fast.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: DS.Spacing.grid)], spacing: DS.Spacing.grid) {
                ForEach(selectedTemplates) { template in
                    let hovered = hoveredTemplateID == template.id
                    Button {
                        onCreateTemplate(template)
                    } label: {
                        VStack(alignment: .leading, spacing: DS.Spacing.md) {
                            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.91, green: 0.95, blue: 1.0), Color(red: 0.96, green: 0.98, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 90)
                                .overlay {
                                    templatePreview(for: template)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                        .stroke(DS.Color.accent.opacity(0.12))
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
                        .padding(DS.Spacing.cardPadding + 1)
                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.large)
                                .fill(
                                    LinearGradient(
                                        colors: [DS.Color.creationCardSurface, DS.Color.creationCardSurface.opacity(0.94)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.large)
                                        .fill(hovered ? DS.Color.hover.opacity(0.2) : Color.clear)
                                )
                                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.creationCardBorder.opacity(hovered ? 0.30 : 0.24)))
                                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.accent.opacity(hovered ? 0.14 : 0.07)))
                                .shadow(color: Color.black.opacity(hovered ? 0.13 : 0.10), radius: hovered ? 17 : 13, x: 0, y: hovered ? 7 : 5)
                        )
                        .brightness(hovered ? 0.016 : 0)
                        .offset(y: hovered ? -2 : 0)
                        .scaleEffect(hovered ? 1.022 : 1)
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .onHover { inside in
                        withAnimation(.easeOut(duration: 0.18)) {
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
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.accent.opacity(0.30)).frame(width: 30, height: 17)
                Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textSecondary.opacity(0.72))
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.secondaryAccent.opacity(0.28)).frame(width: 30, height: 17)
                Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textSecondary.opacity(0.72))
                RoundedRectangle(cornerRadius: 6).fill(DS.Color.accent.opacity(0.16)).frame(width: 24, height: 17)
            }
        case .notes:
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.accent.opacity(0.24)).frame(width: 90, height: 6)
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.20)).frame(width: 76, height: 6)
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.15)).frame(width: 62, height: 6)
                RoundedRectangle(cornerRadius: 4).fill(DS.Color.textSecondary.opacity(0.11)).frame(width: 48, height: 6)
            }
        case .mindMap:
            HStack(spacing: 6) {
                Circle().fill(DS.Color.accent.opacity(0.30)).frame(width: 17, height: 17)
                RoundedRectangle(cornerRadius: 1).fill(DS.Color.textSecondary.opacity(0.45)).frame(width: 12, height: 1)
                Circle().fill(DS.Color.secondaryAccent.opacity(0.22)).frame(width: 12, height: 12)
                Circle().fill(DS.Color.accent.opacity(0.17)).frame(width: 12, height: 12)
                Circle().fill(DS.Color.accent.opacity(0.12)).frame(width: 12, height: 12)
            }
        default:
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.26)).frame(width: 22, height: 14)
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.secondaryAccent.opacity(0.21)).frame(width: 22, height: 14)
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.15)).frame(width: 22, height: 14)
                RoundedRectangle(cornerRadius: 5).fill(DS.Color.accent.opacity(0.11)).frame(width: 22, height: 14)
            }
        }
    }

    var settingsPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Workspace Settings", subtitle: "Appearance and workspace behavior")
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Open app settings to adjust appearance and your working environment.")
                    .font(DS.Typography.body)
                    .lineSpacing(DS.Typography.bodyLineSpacing - 1.5)
                    .foregroundStyle(DS.Color.textSecondary)
                #if os(macOS)
                SettingsLink {
                    Text("Open Settings")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                #endif
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme))
                    )
            )
        }
    }

    var trashSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Trash", subtitle: "Deleted boards appear here before permanent removal.")
            compactEmptyState(
                title: "Trash is empty.",
                detail: "Deleted boards will appear here when available."
            )
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
                        .font(DS.Typography.label.weight(.medium))
                    .tracking(0.45)
                        .foregroundStyle(DS.Color.textTertiary)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs - 1)
                    .background(Capsule().fill(DS.Color.hover))
            }
            .padding(DS.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.large)
                            .fill(hovered ? DS.Color.hover.opacity(0.22) : Color.clear)
                    )
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme).opacity(1.08)))
                    .shadow(color: Color.black.opacity(hovered ? 0.12 : 0.09), radius: hovered ? 14 : 10, x: 0, y: hovered ? 6 : 4)
            )
            .brightness(hovered ? 0.014 : 0)
            .offset(y: hovered ? -2 : 0)
            .scaleEffect(hovered ? 1.016 : 1)
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
            withAnimation(FlowDeskMotion.premiumLiftEaseOut.delay(0.02)) {
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
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                Text(document.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme).opacity(1.08)))
                    .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
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
                .font(DS.Typography.sectionTitle)
                .tracking(DS.Typography.sectionTracking)
                .foregroundStyle(DS.Color.textPrimary)
            Text(subtitle)
                .font(DS.Typography.body)
                .lineSpacing(DS.Typography.bodyLineSpacing - 1.5)
                .foregroundStyle(DS.Color.textSecondary.opacity(0.68))
        }
        .padding(.top, DS.Typography.sectionTopSpacing)
    }

    func emptyState(title: String, detail: String) -> some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.accent.opacity(0.2), DS.Color.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.accent.opacity(0.9))
            }
            Text(title)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(detail)
                .font(DS.Typography.body)
                .lineSpacing(DS.Typography.bodyLineSpacing - 1)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .padding(DS.Spacing.section)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(
                    LinearGradient(
                        colors: [DS.Color.creationCardSurface, DS.Color.creationCardSurface.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.creationCardBorder.opacity(0.16)))
                .shadow(color: Color.black.opacity(0.05), radius: 9, x: 0, y: 4)
        )
    }

    func compactEmptyState(title: String, detail: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.65)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            Button("Start blank") {
                onCreateBlank()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(DS.Color.accent)
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .stroke(DS.Color.borderSubtle.opacity(0.16))
                )
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
                    .fill(active ? DS.Color.homeChipActive.opacity(0.95) : (hovered ? DS.Color.homeChipHover.opacity(0.72) : .clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium)
                            .stroke(active ? DS.Color.accent.opacity(0.32) : Color.clear, lineWidth: 0.9)
                    )
            )
            .brightness(hovered ? 0.01 : 0)
            .scaleEffect(hovered ? 1.014 : 1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? DS.Color.accent : DS.Color.textPrimary.opacity(0.8))
        .onHover { inside in
            withAnimation(FlowDeskMotion.premiumLiftEaseOut.delay(0.02)) {
                hoveredSidebarSection = inside ? section : nil
            }
        }
    }
}
