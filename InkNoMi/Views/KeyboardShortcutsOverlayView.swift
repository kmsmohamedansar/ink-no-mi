import SwiftUI

struct KeyboardShortcutsOverlayView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.46 : 0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(DS.Typography.sectionTitle)
                        .foregroundStyle(DS.Color.textPrimary)
                    Spacer(minLength: 12)
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(DS.Color.hover.opacity(0.75))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(DS.Typography.label.weight(.semibold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.65)

                        VStack(spacing: 8) {
                            ForEach(section.rows) { row in
                                shortcutRow(title: row.title, keys: row.keys)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(width: 560)
            .flowDeskFloatingPanelChrome(
                cornerRadius: 18,
                shadowStyle: .toolPalette,
                lightTintOpacity: 0.13,
                darkTintOpacity: 0.09
            )
        }
        .onKeyPress(.escape) {
            close()
            return .handled
        }
    }

    private func shortcutRow(title: String, keys: [String]) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer(minLength: 10)
            HStack(spacing: 6) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(DS.Typography.caption.weight(.semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(FlowDeskTheme.surfaceGradient(for: .elevated, colorScheme: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(FlowDeskTheme.borderColor(for: .elevated, colorScheme: colorScheme), lineWidth: 0.9)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DS.Color.hover.opacity(colorScheme == .dark ? 0.44 : 0.86))
        )
    }

    private var sections: [ShortcutSection] {
        [
            ShortcutSection(
                title: "Tools",
                rows: [
                    .init(title: "Select", keys: ["V"]),
                    .init(title: "Hand / Pan", keys: ["H"]),
                    .init(title: "Pen", keys: ["P"]),
                    .init(title: "Note", keys: ["N"]),
                    .init(title: "Text", keys: ["T"]),
                    .init(title: "Rectangle", keys: ["R"]),
                    .init(title: "Line", keys: ["L"]),
                    .init(title: "Arrow", keys: ["A"])
                ]
            ),
            ShortcutSection(
                title: "Editing",
                rows: [
                    .init(title: "Undo", keys: ["Cmd", "Z"]),
                    .init(title: "Redo", keys: ["Cmd", "Shift", "Z"])
                ]
            ),
            ShortcutSection(
                title: "View",
                rows: [
                    .init(title: "Command Palette", keys: ["Cmd", "K"]),
                    .init(title: "Export", keys: ["Cmd", "E"]),
                    .init(title: "Settings", keys: ["Cmd", ","])
                ]
            ),
            ShortcutSection(
                title: "Navigation",
                rows: [
                    .init(title: "Shortcut Help", keys: ["?"])
                ]
            )
        ]
    }

    private func close() {
        isPresented = false
    }
}

private struct ShortcutSection: Identifiable {
    let id = UUID()
    let title: String
    let rows: [ShortcutRow]
}

private struct ShortcutRow: Identifiable {
    let id = UUID()
    let title: String
    let keys: [String]
}
