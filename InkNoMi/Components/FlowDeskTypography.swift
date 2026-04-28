import SwiftUI

// MARK: - Scale (pt)

/// App-wide type scale. Headings sit in the requested bands; body pairs with SF Pro Text.
enum FlowDeskTypeScale {
    /// H1 band (28–32): heroes, creation prompts.
    static let h1: CGFloat = 30
    /// H2 band (20–22): section titles, major secondary headings.
    static let h2: CGFloat = 21
    /// Body band (14–16): primary reading / UI sentences.
    static let body: CGFloat = 15
    /// Dense UI body (lists, chips, inspector rows).
    static let bodyCompact: CGFloat = 14
    /// Toolbar & row labels.
    static let label: CGFloat = 13
    /// Secondary labels, shortcuts.
    static let caption: CGFloat = 11.5
    /// Uppercase eyebrows, inspector section labels.
    static let micro: CGFloat = 10.5
}

// MARK: - Tracking (em-ish, applied via `.tracking`)

enum FlowDeskTypeTracking {
    /// Display headlines: slightly tight for an intentional editorial feel.
    static let displayH1: CGFloat = -0.72
    static let displayH2: CGFloat = -0.52
    static let displayTight: CGFloat = -0.34
    /// Running body & supporting lines.
    static let body: CGFloat = -0.06
    /// Uppercase micro-labels (still airy for legibility).
    static let labelUppercase: CGFloat = 0.78
}

// MARK: - Font pairing (SF Pro Display + SF Pro Text)

/// **Headings / display moments** → SF Pro Display. **Body & UI chrome** → SF Pro Text.
/// Falls back to system sans if custom families are unavailable on the installation.
enum FlowDeskFont {
    static func display(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        Font.custom("SF Pro Display", size: size).weight(weight)
    }

    static func uiText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("SF Pro Text", size: size).weight(weight)
    }
}

// MARK: - Semantic styles (Home, sidebar, cards, inspector)

/// Named text styles shared across Home, sidebar, inspector, and chrome.
enum FlowDeskTypography {
    // MARK: - Home / dashboard

    /// Small editorial label above the hero line.
    static let pageEyebrow = FlowDeskFont.uiText(size: FlowDeskTypeScale.micro, weight: .semibold)
    static let pageSubtitle = FlowDeskFont.uiText(size: FlowDeskTypeScale.h2, weight: .regular)
    /// Primary home headline.
    static let homeHeroTitle = FlowDeskFont.display(size: FlowDeskTypeScale.h1, weight: .semibold)
    static let homeIntroBody = FlowDeskFont.uiText(size: FlowDeskTypeScale.body, weight: .regular)
    static let sectionTitle = FlowDeskFont.display(size: FlowDeskTypeScale.h2 + 1, weight: .bold)
    static let sectionCaption = FlowDeskFont.uiText(size: FlowDeskTypeScale.caption, weight: .medium)
    static let homeSectionKicker = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .regular)

    // MARK: - Cards

    static let cardIconPointSize: CGFloat = 26
    static let heroCardIconPointSize: CGFloat = 34
    static let cardTitle = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .bold)
    static let heroCardTitle = FlowDeskFont.display(size: FlowDeskTypeScale.body, weight: .semibold)
    static let cardSubtitle = FlowDeskFont.uiText(size: FlowDeskTypeScale.caption, weight: .regular)
    static let continueTitle = FlowDeskFont.display(size: FlowDeskTypeScale.body, weight: .semibold)
    static let continueMeta = FlowDeskFont.uiText(size: FlowDeskTypeScale.caption, weight: .regular)
    static let recentTitle = FlowDeskFont.uiText(size: FlowDeskTypeScale.body, weight: .medium)
    static let recentMeta = FlowDeskFont.uiText(size: 10.5, weight: .regular)

    // MARK: - Sidebar

    static let sidebarSectionHeader = FlowDeskFont.uiText(size: FlowDeskTypeScale.micro, weight: .semibold)
    static let sidebarRowTitle = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .regular)
    static let sidebarEmptyTitle = FlowDeskFont.display(size: FlowDeskTypeScale.h2, weight: .semibold)
    static let sidebarEmptyBody = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .regular)

    // MARK: - Inspector & panels

    static let inspectorEyebrow = FlowDeskFont.uiText(size: FlowDeskTypeScale.micro, weight: .semibold)
    static let inspectorLabel = FlowDeskFont.uiText(size: FlowDeskTypeScale.label, weight: .medium)
    static let inspectorBody = FlowDeskFont.uiText(size: FlowDeskTypeScale.bodyCompact, weight: .regular)
    static let inspectorMetric = FlowDeskFont.uiText(size: FlowDeskTypeScale.bodyCompact, weight: .regular)
    static let inspectorValueMonospace = FlowDeskFont.uiText(size: FlowDeskTypeScale.caption, weight: .medium)
}

// MARK: - Title / subtitle hierarchy (color)

extension View {
    /// Primary line in a title + subtitle stack (`DS.Color.textPrimary`).
    func flowDeskTitleForeground() -> some View {
        foregroundStyle(DS.Color.textPrimary)
    }

    /// Supporting line under a title — clearly subordinate (`DS.Color.textSecondary`).
    func flowDeskSubtitleForeground() -> some View {
        foregroundStyle(DS.Color.textSecondary)
    }

    /// Tertiary / hint copy (`DS.Color.textTertiary`).
    func flowDeskTertiaryForeground() -> some View {
        foregroundStyle(DS.Color.textTertiary)
    }
}
