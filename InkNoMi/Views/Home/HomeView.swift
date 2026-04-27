import SwiftUI
import AppKit
import Foundation

struct HomeView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @Environment(\.flowDeskTokens) private var tokens
    @AppStorage("InkNoMi.ProHintDismissed") private var proHintDismissed = false

    var documents: [FlowDocument]
    var onOpenDocument: (FlowDocument) -> Void
    var onCreateTemplate: (WorkspaceTemplate) -> Void
    var onCreateTemplateWithTitle: (WorkspaceTemplate, String) -> Void
    var onCreateBlankBoardWithTitle: (String) -> Void
    var onNewWorkspace: () -> Void
    var onDuplicate: (FlowDocument) -> Void
    var onRename: (FlowDocument) -> Void
    var onDelete: (FlowDocument) -> Void
    var onToggleFavorite: (FlowDocument) -> Void
    var onExport: (FlowDocument) -> Void
    #if DEBUG
    var onLoadScreenshotDemoData: (() -> Void)?
    var onSelectScreenshotScene: ((ScreenshotModeService.Scene) -> Void)?
    var selectedScreenshotScene: ScreenshotModeService.Scene = .homeTemplates
    var showScreenshotControls = true
    var showExampleWorkflows = false
    var suppressMonetizationUpsell = false
    #endif

    enum SidebarSection: String, CaseIterable, Identifiable {
        case home
        case recent
        case templates
        case allBoards

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .recent: return "Recent"
            case .templates: return "Templates"
            case .allBoards: return "All Boards"
            }
        }

        var symbol: String {
            switch self {
            case .home: return "house"
            case .recent: return "clock"
            case .templates: return "square.grid.2x2"
            case .allBoards: return "square.stack.3d.up"
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
        case type = "Type"
        case created = "Created Date"
        var id: String { rawValue }
    }
    enum BoardTypeFilter: String, CaseIterable, Identifiable {
        case whiteboard = "Whiteboard"
        case flowchart = "Flowchart"
        case notes = "Notes"
        case mindMap = "Mind Map"
        case roadmap = "Roadmap"
        case kanban = "Kanban"

        var id: String { rawValue }
    }

    @State private var selectedSection: SidebarSection = .home
    @State private var searchQuery = ""
    @State private var boardSort: BoardSort = .updated
    @State private var gridMode = true
    @State private var favoriteOnly = false
    @State private var selectedBoardTypeFilters = Set<BoardTypeFilter>()
    @State private var hoveredQuickAction: String?
    @State private var hoveredSidebarSection: SidebarSection?
    @State private var hoveredBoardID: UUID?
    @State private var selectedBoardID: UUID?
    @State private var hoveredTemplateID: String?
    @State private var hoveredIntentChip: String?
    @State private var hoveredCommandIcon: String?
    @State private var hoveredStarterTemplateID: String?
    @State private var hoveredWorkflowID: String?
    @FocusState private var isCreationPromptFocused: Bool
    @State private var selectedFilter: HomeFilter = .whiteboards
    @State private var hoveredFilter: HomeFilter?
    @State private var creationPromptText = ""
    @State private var selectedSuggestionIndex = 0
    @State private var heroHasAppeared = false
    @State private var hasShownBoardContent = false

    private var featureGate: FeatureGate {
        FeatureGate(purchaseManager: purchaseManager)
    }

    private var shouldReduceMotion: Bool {
        reduceMotion || appearanceManager.settings.motionLevel != .full
    }

    private var smartStartSuggestions: [SmartStartSuggestion] {
        SmartStartIntentMatcher.suggestions(for: creationPromptText)
    }

    private var shouldShowSmartStartSuggestions: Bool {
        isCreationPromptFocused && !smartStartSuggestions.isEmpty
    }

    private var isFirstBoardJourney: Bool {
        documents.isEmpty
    }

    private var boardLibraryDocuments: [FlowDocument] {
        let base = documents.filter {
            searchQuery.isEmpty
            || $0.title.localizedCaseInsensitiveContains(searchQuery)
            || $0.boardType.displayName.localizedCaseInsensitiveContains(searchQuery)
            || (documentTypeLabel($0).localizedCaseInsensitiveContains(searchQuery))
        }
        let typeFiltered = base.filter { matchesTypeFilters($0) }
        let favoritesFiltered = typeFiltered.filter { !favoriteOnly || $0.isFavorite }
        switch boardSort {
        case .updated: return favoritesFiltered.sorted { $0.updatedAt > $1.updatedAt }
        case .title: return favoritesFiltered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .type:
            return favoritesFiltered.sorted {
                let lhsType = documentTypeLabel($0)
                let rhsType = documentTypeLabel($1)
                if lhsType == rhsType {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return lhsType.localizedCaseInsensitiveCompare(rhsType) == .orderedAscending
            }
        case .created:
            return favoritesFiltered.sorted { $0.createdAt > $1.createdAt }
        }
    }
    private var recentDocuments: [FlowDocument] {
        Array(boardLibraryDocuments.prefix(6))
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
            HStack(spacing: 0) {
                sidebar
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.section + 2) {
                        topFilterChips
                        creationPromptCard
                        quickActions
                        #if DEBUG
                        if showExampleWorkflows { workflowsSection }
                        #endif
                        if selectedSection == .home || selectedSection == .recent || selectedFilter == .recents { recentSection }
                        if selectedSection == .home || selectedSection == .allBoards || selectedFilter == .whiteboards {
                            boardsSection
                        }
                        if selectedSection == .home || selectedSection == .templates || selectedFilter == .templates {
                            templatesSection
                        }
                    }
                    .frame(maxWidth: 1100, alignment: .leading)
                    .padding(.top, 44)
                    .padding(.horizontal, 40)
                    .padding(.trailing, 18)
                    .padding(.bottom, 80)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("InkNoMi")
        .onAppear {
            if !heroHasAppeared {
                heroHasAppeared = true
            }
            hasShownBoardContent = !documents.isEmpty
        }
        .onChange(of: documents.isEmpty) { _, isEmpty in
            if !isEmpty {
                hasShownBoardContent = true
            }
        }
    }
}

private struct TemplatePreviewView: View {
    let templateID: String
    let isHovered: Bool

    private var visualOpacity: Double { isHovered ? 1.0 : 0.88 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F8FAFF"), Color(hex: "#EEF4FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            content.padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06)))
    }

    @ViewBuilder private var content: some View {
        switch templateID {
        case "brainstorm-board": brainstormPreview
        case "flowchart": flowchartPreview
        case "product-roadmap": roadmapPreview
        case "meeting-notes": meetingNotesPreview
        case "mind-map": mindMapPreview
        case "kanban-board": kanbanPreview
        case "app-wireframe": wireframePreview
        case "swot-analysis": swotPreview
        default: flowchartPreview
        }
    }

    private var brainstormPreview: some View {
        ZStack {
            sticky("#FFE58A", -34, -18); sticky("#B7DCFF", -8, -22); sticky("#CFEFBC", 21, -14); sticky("#FFC8A7", -23, -2)
            sticky("#D8CCFF", 2, 6); sticky("#BEEAD9", 30, 9); sticky("#B3D5FF", -6, 18); sticky("#C9BCFF", 21, 18)
        }
    }
    private func sticky(_ hex: String, _ x: CGFloat, _ y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(hex: hex).opacity(visualOpacity))
            .frame(width: 24, height: 14)
            .shadow(color: .black.opacity(0.08), radius: 2.5, x: 0, y: 1.5)
            .offset(x: x, y: y)
    }

    private var flowchartPreview: some View {
        GeometryReader { g in
            let y = g.size.height * 0.44
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: g.size.width * 0.20, y: y)); p.addLine(to: CGPoint(x: g.size.width * 0.83, y: y))
                    p.move(to: CGPoint(x: g.size.width * 0.68, y: y)); p.addLine(to: CGPoint(x: g.size.width * 0.68, y: g.size.height * 0.72))
                }.stroke(Color(hex: "#57627B").opacity(visualOpacity), lineWidth: 1.25)
                node("#8CC5FF", 0.14, 0.44, g); node("#B7A2FF", 0.30, 0.44, g); diamond("#FFD58E", 0.52, 0.44, g)
                node("#A6D6FF", 0.68, 0.44, g); node("#BFE7C5", 0.68, 0.72, g)
            }
        }
    }
    private func node(_ hex: String, _ x: CGFloat, _ y: CGFloat, _ g: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color(hex: hex).opacity(visualOpacity))
            .frame(width: 18, height: 12)
            .position(x: g.size.width * x, y: g.size.height * y)
    }
    private func diamond(_ hex: String, _ x: CGFloat, _ y: CGFloat, _ g: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color(hex: hex).opacity(visualOpacity))
            .frame(width: 12, height: 12)
            .rotationEffect(.degrees(45))
            .position(x: g.size.width * x, y: g.size.height * y)
    }

    private var roadmapPreview: some View {
        HStack(spacing: 7) { roadmapColumn("Now", "#96C8FF"); roadmapColumn("Next", "#C3B4FF"); roadmapColumn("Later", "#BFE5C7") }
    }
    private func roadmapColumn(_ title: String, _ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 6.5, weight: .semibold)).foregroundStyle(Color(hex: "#4A556D").opacity(visualOpacity))
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: hex).opacity(visualOpacity)).frame(height: 8)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: hex).opacity(max(0.85, visualOpacity - 0.05))).frame(height: 8)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: hex).opacity(max(0.85, visualOpacity - 0.10))).frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var meetingNotesPreview: some View {
        VStack(alignment: .leading, spacing: 3.5) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#2E3A59").opacity(visualOpacity)).frame(width: 82, height: 6)
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#5D6A84").opacity(max(0.85, visualOpacity - (Double(i) * 0.02)))).frame(width: CGFloat(92 - (i * 8)), height: 4)
            }
            HStack(spacing: 5) { bullet("#8CBFFF", 20); bullet("#B9ACFF", 18); bullet("#9FDDB0", 16) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    private func bullet(_ hex: String, _ width: CGFloat) -> some View {
        HStack(spacing: 3) {
            Circle().fill(Color(hex: hex).opacity(visualOpacity)).frame(width: 3.5, height: 3.5)
            RoundedRectangle(cornerRadius: 2.5).fill(Color(hex: "#4F5C76").opacity(visualOpacity)).frame(width: width, height: 3.5)
        }
    }

    private var mindMapPreview: some View {
        GeometryReader { g in
            let c = CGPoint(x: g.size.width * 0.5, y: g.size.height * 0.5)
            let pts: [CGPoint] = [CGPoint(x: g.size.width * 0.50, y: g.size.height * 0.16), CGPoint(x: g.size.width * 0.78, y: g.size.height * 0.32), CGPoint(x: g.size.width * 0.78, y: g.size.height * 0.70), CGPoint(x: g.size.width * 0.50, y: g.size.height * 0.84), CGPoint(x: g.size.width * 0.24, y: g.size.height * 0.53)]
            ZStack {
                Path { p in for pt in pts { p.move(to: c); p.addLine(to: pt) } }.stroke(Color(hex: "#637191").opacity(visualOpacity), lineWidth: 1.2)
                Circle().fill(Color(hex: "#88BEFF").opacity(visualOpacity)).frame(width: 16, height: 16).position(c)
                ForEach(Array(pts.enumerated()), id: \.offset) { i, pt in Circle().fill(mindColor(i).opacity(visualOpacity)).frame(width: 10, height: 10).position(pt) }
            }
        }
    }
    private func mindColor(_ index: Int) -> Color {
        [Color(hex: "#C4B6FF"), Color(hex: "#A0D4FF"), Color(hex: "#AEE5BC"), Color(hex: "#F7D59D"), Color(hex: "#D8B9FF")][index % 5]
    }

    private var kanbanPreview: some View {
        HStack(spacing: 6) { kanbanColumn("#97C8FF"); kanbanColumn("#C6B8FF"); kanbanColumn("#BFE5C7") }
    }
    private func kanbanColumn(_ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 2.5).fill(Color(hex: "#4E5A75").opacity(visualOpacity)).frame(width: 18, height: 4)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: hex).opacity(visualOpacity)).frame(width: 20, height: 11)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: hex).opacity(max(0.85, visualOpacity - 0.06))).frame(width: 20, height: 11)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var wireframePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(hex: "#6EA8FF").opacity(visualOpacity), lineWidth: 1.8).frame(width: 46, height: 74)
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#A9CCFF").opacity(visualOpacity)).frame(width: 30, height: 7)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#C1DBFF").opacity(visualOpacity)).frame(width: 30, height: 10)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#D5E6FF").opacity(visualOpacity)).frame(width: 30, height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#7FB3FF").opacity(visualOpacity)).frame(width: 18, height: 8)
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#7EAFFF").opacity(visualOpacity)).frame(width: 4, height: 4)
                    Circle().fill(Color(hex: "#B0CCF8").opacity(visualOpacity)).frame(width: 4, height: 4)
                    Circle().fill(Color(hex: "#D3E3FA").opacity(visualOpacity)).frame(width: 4, height: 4)
                }
            }
        }
    }

    private var swotPreview: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) { swotQuadrant("#DDEBFF"); swotQuadrant("#DDF5E5") }
            HStack(spacing: 5) { swotQuadrant("#FFF3D8"); swotQuadrant("#FFE4EE") }
        }
    }
    private func swotQuadrant(_ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            RoundedRectangle(cornerRadius: 2.5).fill(Color(hex: "#5A667E").opacity(visualOpacity)).frame(width: 15, height: 3.5)
            RoundedRectangle(cornerRadius: 2.5).fill(Color(hex: "#73819D").opacity(visualOpacity)).frame(width: 18, height: 3)
            RoundedRectangle(cornerRadius: 2.5).fill(Color(hex: "#8794AD").opacity(max(0.85, visualOpacity - 0.04))).frame(width: 14, height: 3)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color(hex: hex).opacity(visualOpacity)))
    }
}

private extension HomeView {
    var premiumCardFill: Color {
        tokens.homeCardFill
    }

    var premiumCardBorder: Color {
        Color.black.opacity(0.045)
    }

    var premiumCardRadius: CGFloat {
        max(10, tokens.corners.card - 2)
    }

    var premiumCardHoverLift: CGFloat {
        -1
    }

    var premiumCardHoverScale: CGFloat {
        1.008
    }

    var shouldShowUpgradeCTA: Bool {
        #if DEBUG
        !purchaseManager.isProUser && !suppressMonetizationUpsell
        #else
        !purchaseManager.isProUser
        #endif
    }

    func premiumCardShadow(hovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: premiumCardRadius, style: .continuous)
            .fill(Color.clear)
            .shadow(
                color: .black.opacity(hovered ? 0.08 : 0.04),
                radius: hovered ? 14 : 8,
                x: 0,
                y: hovered ? 6 : 2
            )
    }

    func floatingShadow() -> some View {
        RoundedRectangle(cornerRadius: premiumCardRadius, style: .continuous)
            .fill(Color.clear)
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
    }

    var creationBackground: some View {
        ZStack {
            tokens.workspaceBackground
            RadialGradient(
                colors: [Color.white.opacity(0.82), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.04),
                startRadius: 20,
                endRadius: 520
            )
            Circle()
                .fill(tokens.accentSoft)
                .blur(radius: 120)
                .frame(width: 380, height: 380)
                .offset(x: -250, y: -160)
                .opacity(0.45)
            Circle()
                .fill(tokens.accentGradientEnd.opacity(0.15))
                .blur(radius: 160)
                .frame(width: 420, height: 420)
                .offset(x: 340, y: -120)
                .opacity(0.45)
            creationGridOverlay
        }
        .ignoresSafeArea()
    }

    var creationGridOverlay: some View {
        GeometryReader { geometry in
            Path { path in
                let step: CGFloat = 32
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
            .stroke(tokens.canvasGridInk.opacity(0.08), lineWidth: 0.5)
        }
        .opacity(1)
        .allowsHitTesting(false)
    }

    var sidebar: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#EEF4FF"), Color(hex: "#DDE8FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DS.Color.accent)
                        .foregroundStyle(tokens.accent)
                }
                Text("InkNoMi")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#111827"))
            }
            .padding(.bottom, DS.Spacing.xs)

            ForEach(SidebarSection.allCases) { section in
                sidebarRow(section)
            }

            Spacer()

            if shouldShowUpgradeCTA {
                Rectangle()
                    .fill(DS.Color.homeSidebarBorder.opacity(0.9))
                    .frame(height: 1)
                    .padding(.bottom, DS.Spacing.sm)
                Button {
                    _ = featureGate.requirePro(.advancedTemplates, source: "home_sidebar_upgrade")
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Upgrade")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.medium + 1, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#EEF4FF"), Color(hex: "#DFEAFF")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.medium + 1, style: .continuous)
                                    .stroke(DS.Color.accent.opacity(0.26), lineWidth: 1)
                            )
                            .background(premiumCardShadow(hovered: false))
                    )
                }
                .buttonStyle(FlowDeskHomeCardButtonStyle())
                .foregroundStyle(DS.Color.accent)
                .foregroundStyle(tokens.accent)
            }

            #if DEBUG
            if showScreenshotControls, let onLoadScreenshotDemoData {
                Rectangle()
                    .fill(DS.Color.homeSidebarBorder.opacity(0.9))
                    .frame(height: 1)
                    .padding(.top, DS.Spacing.sm)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshot Scene")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                    ForEach(ScreenshotModeService.Scene.allCases) { scene in
                        Button {
                            onSelectScreenshotScene?(scene)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: scene == selectedScreenshotScene ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(scene.title)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                            }
                            .foregroundStyle(scene == selectedScreenshotScene ? DS.Color.accent : DS.Color.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(scene == selectedScreenshotScene ? DS.Color.homeChipActive : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button("Load Screenshot Demo Data", action: onLoadScreenshotDemoData)
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.88))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            #endif
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(active ? DS.Color.accent : DS.Color.textSecondary)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(active ? DS.Color.homeChipActive : (hovered ? DS.Color.homeChipHover : DS.Color.homeChipFill))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(active ? DS.Color.accent.opacity(0.36) : DS.Color.borderSubtle.opacity(0.45))
                                )
                        )
                        .scaleEffect(hovered ? 1.016 : 1)
                }
                .buttonStyle(FlowDeskHomeCardButtonStyle())
                .onHover { inside in
                    withAnimation(FlowDeskMotion.premiumLiftEaseOut) {
                        hoveredFilter = inside ? filter : nil
                    }
                }
            }
        }
    }

    var creationPromptCard: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(isFirstBoardJourney ? "Create your first board" : "Start creating")
                    .font(.system(size: 36, weight: .bold))
                    .tracking(-0.2)
                    .lineSpacing(1.05)
                    .foregroundStyle(Color(hex: "#111827"))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(isFirstBoardJourney ? "Pick a starter board or template and be creating in seconds." : "Capture an idea, pick a template, then jump straight into your board.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(hex: "#4B5563"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 8) {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(DS.Color.accent)
                            .opacity(0.72)
                        TextField(
                            "",
                            text: $creationPromptText,
                            prompt: Text("I want to create...")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color(hex: "#9CA3AF"))
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .focused($isCreationPromptFocused)
                        .onSubmit {
                            applyPrimarySmartStartSuggestion()
                        }
                        .onChange(of: creationPromptText) { _, _ in
                            selectedSuggestionIndex = 0
                        }
                        .onMoveCommand { direction in
                            handleSuggestionMove(direction)
                        }
                        .onExitCommand {
                            dismissSmartStartSuggestions()
                        }

                        Button {
                            applyPrimarySmartStartSuggestion()
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [DS.Color.accent, DS.Color.accent.opacity(0.9)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(creationPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                                )
                        }
                        .buttonStyle(FlowDeskHomeCardButtonStyle())
                        .disabled(creationPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    HStack {
                        commandInputIcon(symbol: "bolt.fill", id: "brainstorm")
                        Spacer()
                        commandInputIcon(symbol: "point.3.connected.trianglepath.dotted", id: "flowchart")
                        Spacer()
                        commandInputIcon(symbol: "note.text", id: "notes")
                        Spacer()
                        commandInputIcon(symbol: "rectangle.3.group", id: "wireframe")
                        Spacer()
                        commandInputIcon(symbol: "tablecells", id: "table")
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, shouldShowSmartStartSuggestions ? 14 : 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.995))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    isCreationPromptFocused ? DS.Color.accent.opacity(0.52) : Color.black.opacity(0.12),
                                    lineWidth: isCreationPromptFocused ? 1.1 : 1
                                )
                        )
                        .shadow(
                            color: .black.opacity(isCreationPromptFocused ? 0.14 : 0.08),
                            radius: isCreationPromptFocused ? 22 : 12,
                            x: 0,
                            y: isCreationPromptFocused ? 12 : 5
                        )
                )
                .animation(FlowDeskMotion.premiumLiftEaseOut, value: isCreationPromptFocused)

                if shouldShowSmartStartSuggestions {
                    smartStartSuggestionPanel
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 8) {
                    intentChip("Brainstorm", templateID: "brainstorm-board")
                    intentChip("Flowchart", templateID: "flowchart")
                    intentChip("Planning", templateID: "product-roadmap")
                    intentChip("Meeting notes", templateID: "meeting-notes")
                }

                HStack(spacing: 8) {
                    Button(isFirstBoardJourney ? "Start now" : "New Board") {
                        if isFirstBoardJourney {
                            createTemplateFromID("brainstorm-board")
                        } else {
                            onNewWorkspace()
                        }
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.accent, DS.Color.accent.opacity(0.88)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )

                    Button("Use template") {
                        selectedSection = .templates
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.82))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    )
                }

                if isFirstBoardJourney {
                    Text("Recommended: Brainstorm Board (free) opens with a polished starter layout.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#6B7280"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: 700, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.white.opacity(0)],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(premiumCardBorder, lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: false))
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .opacity(heroHasAppeared ? 1 : 0)
        .offset(y: heroHasAppeared ? 0 : 8)
        .animation(shouldReduceMotion ? nil : .easeOut(duration: 0.25), value: heroHasAppeared)
    }

    var smartStartSuggestionPanel: some View {
        VStack(spacing: 8) {
            ForEach(Array(smartStartSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                let isSelected = index == selectedSuggestionIndex
                Button {
                    applySmartStartSuggestion(suggestion)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: suggestion.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.accent)
                            .frame(width: 20, height: 20)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#111827"))
                            Text(suggestion.description)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color(hex: "#5E6878"))
                            if let structureHint = suggestion.structureHint {
                                Text("Hint: \(structureHint)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(DS.Color.accent.opacity(0.9))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? Color(hex: "#EEF4FF") : Color.white.opacity(0.84))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? DS.Color.accent.opacity(0.34) : Color.black.opacity(0.06), lineWidth: 1)
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(FlowDeskHomeCardButtonStyle())
                .accessibilityLabel(suggestion.title)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme))
                )
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
        )
        .animation(shouldReduceMotion ? nil : .easeOut(duration: 0.16), value: selectedSuggestionIndex)
    }

    func applyPrimarySmartStartSuggestion() {
        guard !smartStartSuggestions.isEmpty else {
            onNewWorkspace()
            return
        }
        let safeIndex = max(0, min(selectedSuggestionIndex, smartStartSuggestions.count - 1))
        applySmartStartSuggestion(smartStartSuggestions[safeIndex])
    }

    func applySmartStartSuggestion(_ suggestion: SmartStartSuggestion) {
        switch suggestion.action {
        case .template(let template):
            if let title = suggestion.resolvedTitle {
                onCreateTemplateWithTitle(template, title)
            } else {
                onCreateTemplate(template)
            }
        case .blankWithTitle(let title):
            onCreateBlankBoardWithTitle(title)
        }
        creationPromptText = ""
        selectedSuggestionIndex = 0
        isCreationPromptFocused = false
    }

    func handleSuggestionMove(_ direction: MoveCommandDirection) {
        guard shouldShowSmartStartSuggestions else { return }
        switch direction {
        case .down:
            selectedSuggestionIndex = min(selectedSuggestionIndex + 1, smartStartSuggestions.count - 1)
        case .up:
            selectedSuggestionIndex = max(selectedSuggestionIndex - 1, 0)
        default:
            break
        }
    }

    func dismissSmartStartSuggestions() {
        selectedSuggestionIndex = 0
    }

    func intentChip(_ title: String, templateID: String) -> some View {
        let hovered = hoveredIntentChip == templateID
        return Button {
            if let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
                onCreateTemplate(template)
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#111827"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .overlay(Capsule(style: .continuous).stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .background(premiumCardShadow(hovered: hovered))
                )
                .scaleEffect(hovered ? 1.02 : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .accessibilityLabel("\(title) template")
        .animation(shouldReduceMotion ? nil : .easeOut(duration: 0.18), value: hovered)
        .onHover { inside in
            hoveredIntentChip = inside ? templateID : nil
        }
    }

    func commandInputIcon(symbol: String, id: String) -> some View {
        let isHovered = hoveredCommandIcon == id
        return Image(systemName: symbol)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color(hex: "#6B7280"))
            .opacity(isHovered ? 1 : 0.6)
            .onHover { inside in
                withAnimation(.easeOut(duration: 0.15)) {
                    hoveredCommandIcon = inside ? id : nil
                }
            }
    }

    var quickActions: some View {
        HStack(spacing: DS.Spacing.grid) {
            quickActionCard(
                id: "new",
                title: isFirstBoardJourney ? "Start from Starter Board" : "New Board",
                subtitle: isFirstBoardJourney ? "Create instantly with a polished layout so the board looks great from the first second." : "Open a fresh board and shape your ideas your way.",
                icon: isFirstBoardJourney ? "sparkles.rectangle.stack.fill" : "square",
                action: {
                    if isFirstBoardJourney {
                        createTemplateFromID("brainstorm-board")
                    } else {
                        onNewWorkspace()
                    }
                }
            )
            quickActionCard(
                id: "template",
                title: "Start from Template",
                subtitle: isFirstBoardJourney ? "Free templates are ready to use. Pro templates are clearly labeled." : "Launch with ready-made layouts for real work. Advanced templates (Pro).",
                icon: "square.grid.2x2",
                action: { selectedSection = .templates }
            )
            if !isFirstBoardJourney {
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
        let isPrimary = id == "new"
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(DS.Color.accent)
                    if isPrimary {
                        Text("Recommended")
                            .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#4B5563"))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, 3)
                                    .background(Capsule(style: .continuous).fill(Color.white.opacity(0.82)))
                    }
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#111827"))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#4B5563"))
                    .lineLimit(2)
                if isPrimary {
                    HStack(spacing: 6) {
                        Text("Start now")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(DS.Color.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: premiumCardRadius, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: premiumCardRadius, style: .continuous)
                            .stroke(premiumCardBorder, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: premiumCardRadius, style: .continuous)
                            .stroke(DS.Color.accent.opacity(hovered ? 0.1 : 0), lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: hovered))
            )
            .offset(y: hovered ? premiumCardHoverLift : 0)
            .scaleEffect(
                enabled
                    ? (hovered ? premiumCardHoverScale : 1.0)
                    : 0.986
            )
            .opacity(enabled ? 1 : 0.74)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .disabled(!enabled)
        .onHover { inside in
            withAnimation(FlowDeskMotion.hoverGlow) {
                hoveredQuickAction = inside && enabled ? id : nil
            }
        }
    }

    var recentSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("Recent", subtitle: shouldShowUpgradeCopy ? "Jump back in quickly. Unlimited boards (Pro)." : "Jump back in quickly.")
            if recentDocuments.isEmpty {
                intelligentEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "Nothing here yet",
                    detail: "Your recent boards will appear here once you start creating.",
                    actions: recentEmptyStateActions
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                    ForEach(recentDocuments, id: \.persistentModelID) {
                        boardCard($0)
                    }
                }
            }
        }
    }

    var recentEmptyStateActions: [EmptyStateAction] {
        var actions: [EmptyStateAction] = [
            .init(title: "Start a new board", icon: "plus", action: onNewWorkspace),
            .init(title: "Use a template", icon: "square.grid.2x2", action: { selectedSection = .templates })
        ]
        #if DEBUG
        if onLoadScreenshotDemoData != nil {
            actions.append(
                .init(title: "Load demo board", icon: "wand.and.stars", action: { onLoadScreenshotDemoData?() })
            )
        }
        #endif
        return actions
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
                .font(.system(size: 11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(Color(hex: "#9CA3AF"))
                .padding(.top, DS.Spacing.xs)
        }
    }

    func starterTemplateCard(title: String, subtitle: String, templateID: String, icon: String) -> some View {
        Button {
            if let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) {
                onCreateTemplate(template)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DS.Color.accent)
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#111827"))
                }
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("Open template")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.accent)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(premiumCardBorder, lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: hoveredStarterTemplateID == templateID))
            )
            .offset(y: (hoveredStarterTemplateID == templateID) ? premiumCardHoverLift : 0)
            .scaleEffect((hoveredStarterTemplateID == templateID) ? premiumCardHoverScale : 1)
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#111827"))
                Text("Unlimited boards and advanced templates when you need them.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
            }
            Spacer()
            Button("Upgrade") {
                _ = featureGate.requirePro(.advancedTemplates, source: "home_banner_upgrade")
            }
            .buttonStyle(FlowDeskHomeCardButtonStyle())
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(DS.Color.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.84))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            )

            Button {
                UserDefaults.standard.set(true, forKey: "InkNoMi.ProHintDismissed")
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(FlowDeskHomeCardButtonStyle())
            .accessibilityLabel("Dismiss Pro hint")
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(FlowDeskTheme.surfaceGradient(for: .floating, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .stroke(FlowDeskTheme.borderColor(for: .floating, colorScheme: colorScheme))
                )
                .background(premiumCardShadow(hovered: false))
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#111827"))
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(premiumCardBorder, lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: hoveredWorkflowID == templateID))
            )
            .offset(y: hoveredWorkflowID == templateID ? premiumCardHoverLift : 0)
            .scaleEffect(hoveredWorkflowID == templateID ? premiumCardHoverScale : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .animation(.easeOut(duration: 0.18), value: hoveredWorkflowID == templateID)
        .onHover { inside in
            hoveredWorkflowID = inside ? templateID : nil
        }
    }

    var boardsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                sectionHeader("All Boards", subtitle: "Search, sort, and reopen your work.")
                Spacer()
            }
            boardLibraryToolbar
            boardTypeFilters

            let source = boardLibraryDocuments
            if source.isEmpty {
                if documents.isEmpty {
                    intelligentEmptyState(
                        icon: "square.stack.3d.up",
                        title: "Create your first workspace",
                        detail: "Capture ideas, plan work, and visualize thinking.",
                        actions: [
                            .init(title: "Blank canvas", icon: "plus.square", action: onNewWorkspace),
                            .init(title: "Template picker", icon: "square.grid.2x2", action: { selectedSection = .templates })
                        ]
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else if favoriteOnly {
                    intelligentEmptyState(
                        icon: "star.slash",
                        title: "No favorites yet",
                        detail: "Mark boards as favorites to keep your key workspaces handy.",
                        actions: [
                            .init(title: "Show all boards", icon: "line.3.horizontal.decrease.circle", action: { favoriteOnly = false }),
                            .init(title: "Template picker", icon: "square.grid.2x2", action: { selectedSection = .templates }),
                            .init(title: "Blank canvas", icon: "plus.square", action: onNewWorkspace)
                        ]
                    )
                    .transition(.opacity)
                } else {
                    intelligentEmptyState(
                        icon: "magnifyingglass",
                        title: "No boards match yet",
                        detail: "Try a broader search, clear filters, or start a new board.",
                        actions: [
                            .init(title: "Clear search", icon: "xmark.circle", action: { searchQuery = "" }),
                            .init(title: "Reset filters", icon: "line.3.horizontal.decrease.circle", action: {
                                favoriteOnly = false
                                selectedBoardTypeFilters.removeAll()
                            }),
                            .init(title: "Blank canvas", icon: "plus.square", action: onNewWorkspace)
                        ]
                    )
                    .transition(.opacity)
                }
            } else if gridMode {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                    ForEach(source, id: \.persistentModelID) {
                        boardCard($0)
                    }
                }
                .transition(
                    hasShownBoardContent
                        ? .opacity
                        : .opacity.combined(with: .scale(scale: 0.988))
                )
            } else {
                VStack(spacing: DS.Spacing.xs + 2) {
                    ForEach(source, id: \.persistentModelID) {
                        boardListRow($0)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(FlowDeskMotion.standardEaseOut, value: boardLibraryDocuments.isEmpty)
    }

    var templatesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("Template Library", subtitle: "Pick a structured starting point and customize fast.")
            if selectedTemplates.isEmpty {
                intelligentEmptyState(
                    icon: "square.grid.2x2",
                    title: "Start with structure",
                    detail: "Templates help you move faster.",
                    actions: [
                        .init(title: "Brainstorm ideas", icon: "bolt.fill", action: { createTemplateFromID("brainstorm-board") }),
                        .init(title: "Plan a roadmap", icon: "calendar", action: { createTemplateFromID("product-roadmap") }),
                        .init(title: "Map a flow", icon: "point.3.connected.trianglepath.dotted", action: { createTemplateFromID("flowchart") })
                    ]
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(minimum: 220), spacing: 22), count: 4),
                    spacing: 22
                ) {
                    ForEach(selectedTemplates) { template in
                        let hovered = hoveredTemplateID == template.id
                        Button {
                            onCreateTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                homeTemplatePreview(templateID: template.id, hovered: hovered)
                                    .frame(height: 108)
                                .brightness(hovered ? 0.028 : 0)
                                    .scaleEffect(hovered ? 1.01 : 1)
                                .animation(FlowDeskMotion.hoverGlow, value: hovered)

                                HStack {
                                    Image(systemName: template.icon)
                                        .foregroundStyle(DS.Color.accent)
                                    Text(template.category.displayName.uppercased())
                                        .font(.system(size: 11, weight: .medium))
                                        .tracking(0.6)
                                        .foregroundStyle(Color(hex: "#9CA3AF"))
                                    Spacer()
                                    if template.isProTemplate && !purchaseManager.isProUser && !isScreenshotPolishMode {
                                        proBadge
                                    }
                                }
                                Text(template.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color(hex: "#111827"))
                                Text(template.description)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(hex: "#6B7280"))
                                    .lineLimit(2)
                                Text(template.isProTemplate && !purchaseManager.isProUser && !isScreenshotPolishMode ? "Use this template (Pro)" : "Use this template")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(DS.Color.accent)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, minHeight: 250, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(premiumCardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(premiumCardBorder, lineWidth: 1)
                                    )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(DS.Color.accent.opacity(hovered ? 0.12 : 0), lineWidth: 1)
                                )
                                    .background(premiumCardShadow(hovered: hovered))
                            )
                        }
                        .buttonStyle(FlowDeskHomeCardButtonStyle())
                        .accessibilityLabel("Template \(template.title)")
                        .onHover { inside in
            withAnimation(FlowDeskMotion.hoverGlow) {
                                hoveredTemplateID = inside ? template.id : nil
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func templatePreview(for template: WorkspaceTemplate, hovered: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F3F7FF"), Color(hex: "#E3EBFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(DS.Color.accent.opacity(hovered ? 0.46 : 0.36))
                    .frame(width: 24, height: 14)
                RoundedRectangle(cornerRadius: 5)
                    .fill(DS.Color.secondaryAccent.opacity(hovered ? 0.36 : 0.28))
                    .frame(width: 24, height: 14)
                RoundedRectangle(cornerRadius: 5)
                    .fill(DS.Color.accent.opacity(hovered ? 0.28 : 0.2))
                    .frame(width: 24, height: 14)
                RoundedRectangle(cornerRadius: 5)
                    .fill(DS.Color.accent.opacity(hovered ? 0.22 : 0.14))
                    .frame(width: 24, height: 14)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06))
        )
    }

    var settingsPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader("Workspace Settings", subtitle: "Appearance and workspace behavior")
            VStack(alignment: .leading, spacing: 8) {
                    Text("Open app settings to adjust appearance and board behavior.")
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(DS.Typography.bodyLineSpacing - 1.5)
                    .foregroundStyle(Color(hex: "#6B7280"))
                #if os(macOS)
                SettingsLink {
                    Text("Open Settings")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(FlowDeskHomeCardButtonStyle())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.accent, DS.Color.accent.opacity(0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                #endif
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(premiumCardBorder, lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: false))
            )
        }
    }

    @ViewBuilder
    func homeTemplatePreview(templateID: String, hovered: Bool) -> some View {
        TemplatePreviewView(templateID: templateID, isHovered: hovered)
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
        let selected = selectedBoardID == document.id
        return Button {
            selectedBoardID = document.id
            onOpenDocument(document)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                boardPreview(for: document)
                    .frame(height: 96)
                HStack {
                    Text(document.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#111827"))
                        .lineLimit(1)
                    Spacer()
                    favoriteButton(for: document)
                }
                HStack(spacing: 6) {
                    boardTypeChip(document)
                    Spacer()
                    Menu {
                        boardContextMenu(for: document)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#6B7280"))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .overlay(Circle().stroke(Color.black.opacity(0.08)))
                            )
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.plain)
                }
                Text("Edited \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? DS.Color.accent.opacity(0.42) : premiumCardBorder, lineWidth: selected ? 1.35 : 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(DS.Color.accent.opacity(hovered ? 0.09 : 0), lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: hovered))
            )
            .offset(y: hovered ? premiumCardHoverLift : 0)
            .scaleEffect(shouldReduceMotion ? 1 : (hovered ? premiumCardHoverScale : 1))
            .brightness(selected ? 0.012 : 0)
        }
        .contextMenu { boardContextMenu(for: document) }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .accessibilityLabel("Board \(document.title)")
        .focusable()
        .onHover { inside in
            withAnimation(FlowDeskMotion.premiumLiftEaseOut.delay(0.02)) {
                hoveredBoardID = inside ? document.id : nil
            }
        }
    }

    func boardListRow(_ document: FlowDocument) -> some View {
        let hovered = hoveredBoardID == document.id
        let selected = selectedBoardID == document.id
        return Button {
            selectedBoardID = document.id
            onOpenDocument(document)
        } label: {
            HStack(spacing: 8) {
                boardPreview(for: document)
                    .frame(width: 80, height: 52)
                Text(document.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#111827"))
                    .lineLimit(1)
                Spacer()
                boardTypeChip(document)
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
                favoriteButton(for: document)
                Menu {
                    boardContextMenu(for: document)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6B7280"))
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(premiumCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? DS.Color.accent.opacity(0.42) : premiumCardBorder, lineWidth: selected ? 1.35 : 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(DS.Color.accent.opacity(hovered ? 0.09 : 0), lineWidth: 1)
                    )
                    .background(premiumCardShadow(hovered: hovered))
            )
            .offset(y: hovered ? premiumCardHoverLift : 0)
            .scaleEffect(shouldReduceMotion ? 1 : (hovered ? premiumCardHoverScale : 1))
            .brightness(selected ? 0.012 : 0)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .accessibilityLabel("Board row \(document.title)")
        .contextMenu { boardContextMenu(for: document) }
        .focusable()
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.18)) {
                hoveredBoardID = inside ? document.id : nil
            }
        }
    }

    var boardLibraryToolbar: some View {
        HStack(spacing: DS.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(hex: "#6B7280"))
                TextField("Search boards", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            )

            Picker("Sort", selection: $boardSort) {
                ForEach(BoardSort.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.menu)

            Toggle(isOn: $favoriteOnly) {
                Label("Favorites", systemImage: favoriteOnly ? "star.fill" : "star")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.button)
            .tint(DS.Color.accent)
            .animation(FlowDeskMotion.standardEaseOut, value: favoriteOnly)

            Spacer()

            Button {
                withAnimation(FlowDeskMotion.quickEaseOut) {
                    gridMode.toggle()
                }
            } label: {
                Image(systemName: gridMode ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(FlowDeskToolbarButtonStyle())
        }
    }

    var boardTypeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs + 2) {
                ForEach(BoardTypeFilter.allCases) { filter in
                    let active = selectedBoardTypeFilters.contains(filter)
                    Button {
                        withAnimation(FlowDeskMotion.quickEaseOut) {
                            if active {
                                selectedBoardTypeFilters.remove(filter)
                            } else {
                                selectedBoardTypeFilters.insert(filter)
                            }
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(active ? DS.Color.accent : Color(hex: "#6B7280"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(active ? DS.Color.homeChipActive : Color.white.opacity(0.86))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(active ? DS.Color.accent.opacity(0.34) : Color.black.opacity(0.06), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    func boardPreview(for document: FlowDocument) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#F8FAFF"), Color(hex: "#EEF4FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if let image = previewImage(for: document) {
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    TemplatePreviewView(templateID: documentTemplateID(for: document), isHovered: false)
                        .padding(6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipped()
    }

    func boardTypeChip(_ document: FlowDocument) -> some View {
        Text(documentTypeLabel(document))
            .font(.system(size: 11, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(Color(hex: "#9CA3AF"))
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs - 1)
            .background(Capsule().fill(DS.Color.hover))
    }

    func favoriteButton(for document: FlowDocument) -> some View {
        Button {
            onToggleFavorite(document)
        } label: {
            Image(systemName: document.isFavorite ? "star.fill" : "star")
                .foregroundStyle(document.isFavorite ? DS.Color.accent : Color(hex: "#9CA3AF"))
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(0.86)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func boardContextMenu(for document: FlowDocument) -> some View {
        Button("Rename") { onRename(document) }
        Button("Duplicate") { onDuplicate(document) }
        Button(document.isFavorite ? "Unfavorite" : "Favorite") { onToggleFavorite(document) }
        Button("Export") { onExport(document) }
        Divider()
        Button("Delete", role: .destructive) { onDelete(document) }
    }

    func documentTypeLabel(_ document: FlowDocument) -> String {
        if document.title.localizedCaseInsensitiveContains("kanban") {
            return BoardTypeFilter.kanban.rawValue
        }
        return document.boardType.displayName
    }

    func matchesTypeFilters(_ document: FlowDocument) -> Bool {
        guard !selectedBoardTypeFilters.isEmpty else { return true }
        let boardLabel = documentTypeLabel(document)
        return selectedBoardTypeFilters.contains(where: { $0.rawValue == boardLabel })
    }

    func elementCount(for document: FlowDocument) -> Int {
        CanvasBoardCoding.decode(from: document.canvasPayload).elements.count
    }

    func documentTemplateID(for document: FlowDocument) -> String {
        if let template = document.resolvedBoardTemplate {
            switch template {
            case .flowDiagram:
                return "flowchart"
            case .document:
                return "meeting-notes"
            case .whiteboard:
                return "brainstorm-board"
            case .smartCanvas, .blankBoard:
                break
            }
        }
        switch document.boardType {
        case .flowchart:
            return "flowchart"
        case .notes:
            return "meeting-notes"
        case .mindMap:
            return "mind-map"
        case .roadmap:
            return "product-roadmap"
        case .diagram:
            return "app-wireframe"
        case .whiteboard:
            return "brainstorm-board"
        }
    }

    func previewImage(for document: FlowDocument) -> Image? {
        guard let data = document.thumbnailData, let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
    }

    func createTemplateFromID(_ templateID: String) {
        guard let template = WorkspaceTemplate.gallery.first(where: { $0.id == templateID }) else { return }
        onCreateTemplate(template)
    }

    func sectionHeader(_ text: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(text)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "#111827"))
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(DS.Typography.bodyLineSpacing - 1.5)
                .foregroundStyle(Color(hex: "#6B7280"))
        }
        .padding(.top, DS.Typography.sectionTopSpacing)
    }

    struct EmptyStateAction: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let action: () -> Void
    }

    func intelligentEmptyState(
        icon: String,
        title: String,
        detail: String,
        actions: [EmptyStateAction]
    ) -> some View {
        VStack(spacing: 12) {
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
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.accent.opacity(0.9))
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#111827"))
            Text(detail)
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(DS.Typography.bodyLineSpacing - 1)
                .foregroundStyle(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            HStack(spacing: 8) {
                ForEach(actions.prefix(3)) { action in
                    Button {
                        action.action()
                    } label: {
                        Label(action.title, systemImage: action.icon)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .foregroundStyle(DS.Color.accent)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(premiumCardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(premiumCardBorder, lineWidth: 1)
                )
                .background(premiumCardShadow(hovered: false))
        )
    }

    func emptyState(title: String, detail: String) -> some View {
        intelligentEmptyState(
            icon: "sparkles",
            title: title,
            detail: detail,
            actions: [
                .init(title: "Blank canvas", icon: "plus.square", action: onNewWorkspace),
                .init(title: "Use a template", icon: "square.grid.2x2", action: { selectedSection = .templates })
            ]
        )
    }

    func compactEmptyState(title: String, detail: String) -> some View {
        intelligentEmptyState(
            icon: "square.stack.3d.up.slash",
            title: title,
            detail: detail,
            actions: [
                .init(title: "Blank canvas", icon: "plus.square", action: onNewWorkspace),
                .init(title: "Use a template", icon: "square.grid.2x2", action: { selectedSection = .templates })
            ]
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
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(DS.Color.accent.opacity(active ? 0.95 : 0))
                    .frame(width: 3, height: 16)
                Image(systemName: section.symbol)
                    .frame(width: 16)
                Text(section.title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.vertical, DS.Spacing.sm + 1)
            .padding(.horizontal, DS.Spacing.sm + 1)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .fill(active ? DS.Color.homeChipActive : (hovered ? DS.Color.homeChipHover.opacity(0.65) : .clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.medium)
                            .stroke(active ? DS.Color.accent.opacity(0.42) : (hovered ? Color.black.opacity(0.06) : Color.clear), lineWidth: 1)
                    )
            )
            .brightness(hovered ? 0.012 : 0)
            .scaleEffect(hovered ? 1.01 : 1)
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .foregroundStyle(active ? DS.Color.accent : DS.Color.textPrimary.opacity(0.8))
        .onHover { inside in
            withAnimation(FlowDeskMotion.premiumLiftEaseOut) {
                hoveredSidebarSection = inside ? section : nil
            }
        }
    }
}

private enum SmartStartSuggestionAction {
    case template(WorkspaceTemplate)
    case blankWithTitle(String)
}

private struct SmartStartSuggestion: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let structureHint: String?
    let action: SmartStartSuggestionAction
    let resolvedTitle: String?
}

private enum SmartStartIntentMatcher {
    static func suggestions(for input: String) -> [SmartStartSuggestion] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var suggestions: [SmartStartSuggestion] = []
        if let templateSuggestion = mappedTemplateSuggestion(from: trimmed) {
            suggestions.append(templateSuggestion)
        }
        suggestions.append(
            SmartStartSuggestion(
                id: "blank-\(trimmed.lowercased())",
                icon: "square",
                title: "Create blank board with this title",
                description: "\"\(trimmed)\"",
                structureHint: nil,
                action: .blankWithTitle(trimmed),
                resolvedTitle: trimmed
            )
        )
        return suggestions
    }

    private static func mappedTemplateSuggestion(from prompt: String) -> SmartStartSuggestion? {
        let tokens = prompt
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let keywordMap: [(keyword: String, templateID: String, label: String, hint: String, icon: String)] = [
            ("plan", "product-roadmap", "Suggested template: Roadmap", "Milestones, owners, and timeline lanes.", "calendar"),
            ("brainstorm", "brainstorm-board", "Suggested template: Brainstorm board", "Use clusters and color tags for idea grouping.", "bolt.fill"),
            ("flow", "flowchart", "Suggested template: Flowchart", "Start with a decision node, then branch outcomes.", "point.3.connected.trianglepath.dotted"),
            ("notes", "meeting-notes", "Suggested template: Meeting notes", "Agenda, highlights, and action items sections.", "note.text"),
            ("kanban", "kanban-board", "Suggested template: Kanban board", "Track work with To Do, Doing, Done columns.", "rectangle.3.group")
        ]

        guard let match = keywordMap.first(where: { tokens.contains($0.keyword) }) else {
            return nil
        }
        guard let template = WorkspaceTemplate.gallery.first(where: { $0.id == match.templateID }) else {
            return nil
        }

        let cleanedTitle = cleanedPromptTitle(prompt, removing: match.keyword)
        return SmartStartSuggestion(
            id: "template-\(template.id)-\(prompt.lowercased())",
            icon: match.icon,
            title: match.label,
            description: "Create \"\(template.title)\" from your input",
            structureHint: match.hint,
            action: .template(template),
            resolvedTitle: cleanedTitle
        )
    }

    private static func cleanedPromptTitle(_ prompt: String, removing keyword: String) -> String? {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return prompt
        }
        let range = NSRange(prompt.startIndex..<prompt.endIndex, in: prompt)
        let stripped = regex.stringByReplacingMatches(in: prompt, options: [], range: range, withTemplate: "")
        let normalized = stripped.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? prompt : normalized
    }
}

private extension HomeView {
    var isScreenshotPolishMode: Bool {
        #if DEBUG
        suppressMonetizationUpsell
        #else
        false
        #endif
    }

    var shouldShowUpgradeCopy: Bool {
        !purchaseManager.isProUser && !isScreenshotPolishMode
    }

    var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(DS.Color.accent.opacity(0.16))
            )
            .foregroundStyle(DS.Color.accent)
    }
}
