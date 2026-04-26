import SwiftUI

/// Text styles shared across Home, sidebar, inspector, and chrome.
enum FlowDeskTypography {
    // MARK: - Home / dashboard

    /// Small editorial label above the hero line (premium restraint).
    static let pageEyebrow = Font.system(size: 10.5, weight: .semibold, design: .default)
    static let pageSubtitle = Font.title3.weight(.regular)
    /// Primary home headline — heavier than body copy for clear editorial hierarchy (Notion-like calm, not shouty).
    static let homeHeroTitle = Font.title.weight(.semibold)
    static let homeIntroBody = Font.body.weight(.regular)
    static let sectionTitle = Font.title3.weight(.semibold)
    static let sectionCaption = Font.footnote
    /// Short supporting line under major home headings.
    static let homeSectionKicker = Font.subheadline.weight(.regular)

    // MARK: - Cards

    static let cardIconPointSize: CGFloat = 26
    static let heroCardIconPointSize: CGFloat = 34
    static let cardTitle = Font.subheadline.weight(.semibold)
    static let heroCardTitle = Font.headline.weight(.semibold)
    /// Supporting copy under card titles—regular weight so titles read as the anchor.
    static let cardSubtitle = Font.footnote.weight(.regular)
    static let continueTitle = Font.headline.weight(.semibold)
    static let continueMeta = Font.footnote
    static let recentTitle = Font.body.weight(.medium)
    static let recentMeta = Font.caption2

    // MARK: - Sidebar

    static let sidebarSectionHeader = Font.caption2.weight(.semibold)
    static let sidebarRowTitle = Font.subheadline
    static let sidebarEmptyTitle = Font.title3.weight(.semibold)
    static let sidebarEmptyBody = Font.subheadline
}
