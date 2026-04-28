import SwiftUI

struct CommandPaletteCommand: Identifiable {
    let id: String
    let title: String
    let icon: String
    let shortcut: String
    let category: String?
    let handler: () -> Void
}

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    let commands: [CommandPaletteCommand]

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedRowID: String?

    private var filteredCommands: [CommandPaletteCommand] {
        guard !query.isEmpty else { return commands }
        return commands.filter { command in
            command.title.localizedCaseInsensitiveContains(query)
                || (command.category?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("Command")
                    .font(DS.Typography.sectionTitle)
                    .foregroundStyle(.primary)

                TextField("Search actions…", text: $query)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .focused($isSearchFocused)
                    .accessibilityLabel("Search commands")
                    .onSubmit {
                        executeSelection()
                    }

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                            Button(action: {
                                selectedIndex = index
                                executeSelection()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: command.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(width: 18)
                                        .foregroundStyle(.secondary)

                                    Text(command.title)
                                        .font(DS.Typography.body)
                                        .foregroundStyle(.primary)

                                    Spacer(minLength: 8)

                                    if !command.shortcut.isEmpty {
                                        Text(command.shortcut)
                                            .font(DS.Typography.caption.weight(.medium))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(minHeight: 40)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(rowBackground(isSelected: index == selectedIndex))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(FlowDeskPlainInteractionStyle())
                            .focusable(true)
                            .focused($focusedRowID, equals: command.id)
                            .accessibilityLabel(command.title)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
            .padding(16)
            .frame(width: 560)
            .flowDeskFloatingPanelChrome(
                cornerRadius: 16,
                shadowStyle: .modalPanel,
                lightTintOpacity: 0.14,
                darkTintOpacity: 0.10
            )
        }
        .onAppear {
            selectedIndex = 0
            focusedRowID = filteredCommands.first?.id
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
        .onChange(of: query) { _, _ in
            selectedIndex = 0
            focusedRowID = filteredCommands.first?.id
        }
        .onMoveCommand(perform: handleMove)
        .onKeyPress(.escape) {
            close()
            return .handled
        }
        .onKeyPress(.return) {
            executeSelection()
            return .handled
        }
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.38), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        }
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        guard !filteredCommands.isEmpty else { return }
        switch direction {
        case .down:
            selectedIndex = min(selectedIndex + 1, filteredCommands.count - 1)
        case .up:
            selectedIndex = max(selectedIndex - 1, 0)
        default:
            break
        }
        focusedRowID = filteredCommands[selectedIndex].id
    }

    private func executeSelection() {
        guard filteredCommands.indices.contains(selectedIndex) else { return }
        filteredCommands[selectedIndex].handler()
        close()
    }

    private func close() {
        isPresented = false
        query = ""
    }
}
