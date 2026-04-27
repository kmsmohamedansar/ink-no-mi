import AppKit
import SwiftUI

struct DocumentSidebarView: View {
    @Environment(\.flowDeskTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    let documents: [FlowDocument]
    @Binding var selection: FlowDocument?
    var onNewBoard: () -> Void
    var onOpenTemplates: () -> Void
    var onDelete: (IndexSet) -> Void
    var onRenameRequest: (FlowDocument) -> Void

    @State private var hoveredDocumentID: UUID?

    private var sectionHeaderForeground: Color {
        DS.Color.textSecondary.opacity(colorScheme == .dark ? 0.74 : 0.72)
    }

    var body: some View {
        Group {
            if documents.isEmpty {
                sidebarEmptyLibrary
            } else {
                sidebarDocumentsList
            }
        }
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tokens.sidebarListTint)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(DS.Color.hover.opacity(colorScheme == .dark ? 1.2 : 0.52))
                            }
                    }
            .padding(.horizontal, DS.Spacing.sm - 2)
            .padding(.vertical, DS.Spacing.sm)

                HStack {
                    Spacer()
                    Rectangle()
                        .fill(DS.Color.border.opacity(colorScheme == .dark ? 1.7 : 0.58))
                        .frame(width: 1)
                        .padding(.vertical, DS.Spacing.md - 2)
                }
                .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onNewBoard) {
                    Image(systemName: "plus")
                }
                .help("New canvas")
                .buttonStyle(FlowDeskToolbarButtonStyle())
            }
        }
    }

    private var sidebarDocumentsList: some View {
        List(selection: $selection) {
            Section {
                ForEach(documents, id: \.persistentModelID) { document in
                    sidebarRow(for: document)
                }
                .onDelete(perform: onDelete)
            } header: {
                boardsSectionHeader
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 40)
    }

    @ViewBuilder
    private func sidebarRow(for document: FlowDocument) -> some View {
        let isSelected = selection?.persistentModelID == document.persistentModelID
        let isHovered = hoveredDocumentID == document.id

        Label {
            Text(document.title)
                .font(sidebarRowTitleFont(isSelected: isSelected))
                .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.92))
                .lineLimit(2)
        } icon: {
            Image(systemName: "rectangle.stack.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.callout.weight(.medium))
                .foregroundStyle(
                    isSelected
                        ? tokens.selectionStrokeColor.opacity(0.92)
                        : Color.secondary.opacity(0.88)
                )
        }
        .labelStyle(.titleAndIcon)
        .contextMenu {
            Button("Rename…") {
                onRenameRequest(document)
            }
            Divider()
            Button("Delete", role: .destructive) {
                if let index = documents.firstIndex(where: { $0.id == document.id }) {
                    onDelete(IndexSet(integer: index))
                }
            }
        }
        .tag(Optional(document))
        .listRowInsets(
            EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        )
        .listRowBackground(
            sidebarRowBackground(isSelected: isSelected, isHovered: isHovered)
        )
        .listRowSeparator(.hidden)
        .contentShape(RoundedRectangle(cornerRadius: FlowDeskLayout.sidebarRowSelectionCornerRadius, style: .continuous))
        .onHover { inside in
            withAnimation(FlowDeskMotion.standardEaseOut) {
                hoveredDocumentID = inside ? document.id : nil
            }
            if inside {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    private func sidebarRowTitleFont(isSelected: Bool) -> Font {
        FlowDeskTypography.sidebarRowTitle.weight(isSelected ? .semibold : .regular)
    }

    private var boardsSectionHeader: some View {
        Text("Boards")
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(sectionHeaderForeground)
            .tracking(0.85)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, FlowDeskLayout.sidebarSectionHeaderLeadingPadding)
            .padding(.trailing, FlowDeskLayout.sidebarRowTrailingInset)
            .padding(.top, FlowDeskLayout.spaceS)
            .padding(.bottom, FlowDeskLayout.spaceXS + 2)
            .accessibilityAddTraits(.isHeader)
    }

    private func sidebarRowBackground(isSelected: Bool, isHovered: Bool) -> some View {
        let corner = FlowDeskLayout.sidebarRowSelectionCornerRadius
        return RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(rowFill(isSelected: isSelected, isHovered: isHovered))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tokens.selectionStrokeColor.opacity(isHovered && !isSelected ? 0.10 : 0),
                                Color.white.opacity(isHovered && !isSelected ? 0.05 : 0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(
                        isSelected ? tokens.selectionStrokeColor.opacity(colorScheme == .dark ? 0.42 : 0.36) : Color.clear,
                        lineWidth: isSelected ? 1 : 0
                    )
            }
            .scaleEffect(isHovered && !isSelected ? 1.006 : 1)
            .padding(.vertical, 0.5)
            .padding(.horizontal, 6)
            .animation(FlowDeskMotion.standardEaseOut, value: isSelected)
            .animation(FlowDeskMotion.standardEaseOut, value: isHovered)
    }

    private func rowFill(isSelected: Bool, isHovered: Bool) -> Color {
        if isSelected {
            return tokens.selectionStrokeColor.opacity(colorScheme == .dark ? 0.24 : 0.12)
        }
        if isHovered {
            return FlowDeskTheme.hoverNeutral.opacity(0.82)
        }
        return Color.clear
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
                .frame(height: 1)
                .allowsHitTesting(false)
            Button(action: onNewBoard) {
                Label("New canvas", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(FlowDeskPlainCardButtonStyle())
            .padding(.horizontal, FlowDeskLayout.sidebarFooterHorizontalPadding)
            .padding(.vertical, FlowDeskLayout.sidebarFooterVerticalPadding + FlowDeskLayout.spaceXS / 2)
        }
        .flowDeskSidebarFooterBackground(tokens)
    }

    private var sidebarEmptyLibrary: some View {
        VStack(spacing: FlowDeskLayout.spaceL) {
            Spacer(minLength: 0)
            FlowDeskSheetsStackMark(size: 84)
            VStack(spacing: FlowDeskLayout.spaceS) {
                Text("Create your first workspace")
                    .font(FlowDeskTypography.sidebarEmptyTitle)
                    .foregroundStyle(.primary)
                Text("Capture ideas, plan work, and visualize thinking.")
                    .font(FlowDeskTypography.sidebarEmptyBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FlowDeskLayout.spaceM)
            }
            HStack(spacing: 8) {
                Button("Blank canvas", action: onNewBoard)
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .font(.system(size: 13, weight: .semibold))
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

                Button("Template picker", action: onOpenTemplates)
                    .buttonStyle(FlowDeskHomeCardButtonStyle())
                    .font(.system(size: 13, weight: .medium))
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
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, FlowDeskLayout.sidebarEmptyHorizontalPadding)
    }
}
