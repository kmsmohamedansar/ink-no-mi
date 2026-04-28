import SwiftUI

/// Shared spacing, radii, and structural measures so surfaces feel like one product.
enum FlowDeskLayout {
    // MARK: - Spacing scale (4pt rhythm)

    static let spaceXS: CGFloat = DS.Spacing.xs
    static let spaceS: CGFloat = DS.Spacing.sm
    static let spaceM: CGFloat = DS.Spacing.md
    static let spaceL: CGFloat = DS.Spacing.lg
    static let spaceXL: CGFloat = DS.Spacing.xl
    static let spaceXXL: CGFloat = 32

    // MARK: - Home / dashboard

    static let homePageMaxContentWidth: CGFloat = 960
    static let homePageHorizontalPadding: CGFloat = 32
    static let homePageVerticalPadding: CGFloat = 32
    static let homeMajorSectionSpacing: CGFloat = 32
    /// Space between a section label block and its first card (keeps vertical rhythm with grid gaps).
    static let homeSubsectionSpacing: CGFloat = 16
    static let homeHeadlineToBodySpacing: CGFloat = 10
    static let homeCreationGridSpacing: CGFloat = 16
    /// Caps width of the secondary “Blank board” tile so the hero canvas card dominates.
    static let homeBlankCreationMaxWidth: CGFloat = 380
    static let homeRecentRowSpacing: CGFloat = 8
    /// Vertical gap between “Smart canvas” and “Blank board” (tighter than major section rhythm).
    static let homeCreationCardsVerticalSpacing: CGFloat = 24

    // MARK: - Cards (same family as canvas framed elements)

    /// Primary corner radius for home cards, text blocks, charts, and sticky notes.
    static let cardCornerRadius: CGFloat = DS.Radius.medium

    static let cardBorderLineWidth: CGFloat = 1
    static let cardBorderLineWidthHover: CGFloat = 1.25

    static let cardShadowYNormal: CGFloat = 6
    static let cardShadowYHover: CGFloat = 8

    static let homeCreationCardMinHeight: CGFloat = 144
    /// Primary “Smart canvas” tile on Home (secondary blank uses `homeCreationCardMinHeight`).
    static let homeCreationCardHeroMinHeight: CGFloat = 196
    static let homeCreationCardInnerSpacing: CGFloat = 14
    static let homeCreationCardTitleSubtitleSpacing: CGFloat = 6

    static let homeContinueMinHeight: CGFloat = 108
    /// Unified internal card padding across Home + canvas framed cards.
    static let unifiedCardPadding: CGFloat = 16
    static let homeCardPadding: CGFloat = unifiedCardPadding

    static let homeRecentRowHorizontalPadding: CGFloat = unifiedCardPadding
    static let homeRecentRowVerticalPadding: CGFloat = unifiedCardPadding

    /// Uniform insets for `cardContainer` on creation / continue cards.
    static var homeCardContentInsets: EdgeInsets {
        EdgeInsets(
            top: homeCardPadding,
            leading: homeCardPadding,
            bottom: homeCardPadding,
            trailing: homeCardPadding
        )
    }

    /// Insets for `cardContainer` on recent-board rows (same rhythm as other cards).
    static var homeRecentRowContentInsets: EdgeInsets {
        EdgeInsets(
            top: homeRecentRowVerticalPadding,
            leading: homeRecentRowHorizontalPadding,
            bottom: homeRecentRowVerticalPadding,
            trailing: homeRecentRowHorizontalPadding
        )
    }

    /// Interior padding for text blocks and chart bodies (aligned with home cards).
    static let canvasCardContentPadding = EdgeInsets(
        top: unifiedCardPadding,
        leading: unifiedCardPadding,
        bottom: unifiedCardPadding,
        trailing: unifiedCardPadding
    )

    static let chartTitleElementSpacing: CGFloat = 12

    // MARK: - Selection chrome (geometry only; colors from tokens)

    static let shapeSelectionCornerRadius: CGFloat = 12
    static let strokeSelectionCornerRadius: CGFloat = 8

    // MARK: - Sidebar

    static let sidebarRowVerticalInset: CGFloat = 6
    static let sidebarRowLeadingInset: CGFloat = 10
    static let sidebarRowTrailingInset: CGFloat = 10
    static let sidebarFooterHorizontalPadding: CGFloat = 14
    static let sidebarFooterVerticalPadding: CGFloat = 10
    static let sidebarEmptyHorizontalPadding: CGFloat = 12

    /// Sidebar row pill; matches home-adjacent rounded language (continuous curve).
    static let sidebarRowSelectionCornerRadius: CGFloat = DS.Radius.small
    /// Leading inset for the “BOARDS”-style section label (aligns with row content).
    static let sidebarSectionHeaderLeadingPadding: CGFloat = 18

    // MARK: - Inspector

    static let inspectorHorizontalPadding: CGFloat = 12
    static let inspectorSectionHeaderBottomSpacing: CGFloat = 8

    // MARK: - Canvas

    /// Hairline-adjacent; paired with low-opacity ink so the grid stays supportive.
    static let gridLineWidth: CGFloat = 0.22
    /// Every Nth grid interval reads slightly stronger (spatial hierarchy).
    static let gridMajorLineStride: Int = 5

    // MARK: - Floating panels (palette, selection bar, tips)

    static let floatingPanelCornerRadius: CGFloat = DS.Radius.medium
    static let floatingPanelContentPadding: CGFloat = 8
    /// Contextual toolbars anchored to the selection (compact footprint).
    static let floatingPanelToolbarPaddingH: CGFloat = 8
    static let floatingPanelToolbarPaddingV: CGFloat = 6
    static let floatingPanelToolbarInnerSpacing: CGFloat = 6
    /// Multi-select alignment bar outer insets.
    static let floatingPanelMultiSelectPaddingH: CGFloat = 8
    static let floatingPanelMultiSelectPaddingV: CGFloat = 8
    static let floatingPanelMultiSelectOuterStackSpacing: CGFloat = 7

    /// HUD chips, rail icon wells, template rows, placeholder element chrome (step below card radius).
    static let chromeCompactCornerRadius: CGFloat = DS.Radius.small
    /// Inset rows inside context panels (shape picker, etc.); aligns with stroke selection handle chrome.
    static let chromeInsetCornerRadius: CGFloat = DS.Radius.small
    /// Dashed placement preview on the board.
    static let chromePlacementPreviewCornerRadius: CGFloat = 3
    /// Bar marks inside Swift Charts.
    static let chartBarMarkCornerRadius: CGFloat = 4

    /// Home creation / recent row icon wells (hero / standard / list).
    static let homeIconWellCornerHero: CGFloat = 15
    static let homeIconWellCornerStandard: CGFloat = 12
    static let homeIconWellCornerRecent: CGFloat = 12

    /// Canvas overlay margins (onboarding callout, zoom HUD).
    static let canvasOverlayTrailingInset: CGFloat = 16
    static let canvasOverlayBottomInset: CGFloat = 14
    static let canvasOnboardingCalloutTopInset: CGFloat = 10
    static let canvasOnboardingCalloutTrailingInset: CGFloat = 14

    /// Interior padding for the templates/shapes/draw context column.
    static let canvasContextPanelPadding: CGFloat = 12
    static let canvasContextTemplateRowPadding: CGFloat = 10
    static let canvasToolRailPaddingV: CGFloat = 8
    static let canvasToolRailPaddingH: CGFloat = 6
    static let canvasToolRailStackSpacing: CGFloat = 6
    static let canvasToolRailUndoStackSpacing: CGFloat = 4

    /// Shared hairline on floating chrome (toolbars, palette, HUD).
    static let chromeHairlineBorderWidth: CGFloat = 0.75

    /// Inset around resize / selection affordances on framed canvas items.
    static let canvasSelectionChromeInset: CGFloat = 8

    /// macOS sheet content (rename, etc.).
    static let sheetStandardPadding: CGFloat = 20

    // MARK: - Canvas tool rail & context column

    /// Primary tool rail (Miro-style); icons sit in this width including padding.
    static let canvasToolRailWidth: CGFloat = 48

    /// `CanvasBoardView` inner board layer (logical canvas coords) for `DragGesture(coordinateSpace:)`.
    static let canvasInnerCoordinateSpaceName = "flowdesk.canvas.inner"
    /// Progressive context panel beside the rail.
    static let canvasContextPanelWidth: CGFloat = 268
    static let canvasChromeLeadingPadding: CGFloat = 10
    static let canvasChromeInterColumnSpacing: CGFloat = 8

    /// Tool rail icon hit target (width × height).
    static let canvasRailIconSize: CGFloat = 36

    // MARK: - Shared chrome

    /// Subtle pill/chip behind template labels (home, sidebar metadata).
    static let chipBackgroundOpacity: Double = 0.07

    // MARK: - Window toolbar (canvas editor)

    /// Space between major leading items (back, title field, status cluster).
    static let windowToolbarLeadingClusterSpacing: CGFloat = 14
    /// Between save badge, relative time, and tool chip.
    static let windowToolbarMetaClusterSpacing: CGFloat = 10
    /// Outer padding of the unified Edit | View | Export bar.
    static let windowToolbarPrimaryClusterPaddingH: CGFloat = 5
    static let windowToolbarPrimaryClusterPaddingV: CGFloat = 5
    static let windowToolbarPrimaryClusterCornerRadius: CGFloat = 10
    /// Interior padding for each labeled segment inside the cluster.
    static let windowToolbarSegmentPaddingH: CGFloat = 11
    static let windowToolbarSegmentPaddingV: CGFloat = 6
    /// Vertical rule between toolbar segments (optical center with label cap height).
    static let windowToolbarSegmentDividerHeight: CGFloat = 15
    /// Inline board title field in the window toolbar (document-style).
    static let windowToolbarBoardTitleMinWidth: CGFloat = 200
    static let windowToolbarBoardTitleIdealWidth: CGFloat = 300
    static let windowToolbarBoardTitleMaxWidth: CGFloat = 420
}
