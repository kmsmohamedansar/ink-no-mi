import SwiftData
import SwiftUI

@main
struct InkNoMiApp: App {
    private let modelContainer = ModelContainerFactory.makeDefault()
    @StateObject private var appearanceStore = AppearanceManager()

    var body: some Scene {
        // Native window chrome: minimize / zoom / full screen (no custom window styles).
        WindowGroup {
            FlowDeskRootView(appearanceStore: appearanceStore)
        }
        .modelContainer(modelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NotificationCenter.default.post(name: .flowDeskBoardUndo, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command])

                Button("Redo") {
                    NotificationCenter.default.post(name: .flowDeskBoardRedo, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandGroup(after: .appInfo) {
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: .flowDeskOpenCommandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Export…") {
                    NotificationCenter.default.post(name: .flowDeskExportBoard, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])

                #if os(macOS)
                SettingsLink {
                    Text("Settings…")
                }
                .keyboardShortcut(",", modifiers: [.command])
                #endif
            }

            CommandMenu("View") {
                Button("Toggle Focus Mode") {
                    NotificationCenter.default.post(name: .flowDeskToggleFocusMode, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            CommandMenu("Help") {
                Button("Keyboard Shortcuts") {
                    NotificationCenter.default.post(name: .flowDeskOpenShortcutHelp, object: nil)
                }
                .keyboardShortcut("/", modifiers: [.shift])
            }
        }

        #if os(macOS)
        Settings {
            FlowDeskAppearanceSettingsView()
                .environmentObject(appearanceStore)
        }
        #endif
    }
}
