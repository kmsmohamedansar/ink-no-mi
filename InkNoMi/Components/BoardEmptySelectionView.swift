import SwiftUI

struct BoardEmptySelectionView: View {
    var onNewBoard: () -> Void

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: FlowDeskLayout.spaceM + FlowDeskLayout.spaceXS / 2) {
                Image(systemName: "square.dashed")
                    .font(.system(size: 40, weight: .ultraLight))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                Text("Choose a canvas")
                    .font(.title3.weight(.semibold))
            }
        } description: {
            Text("Select a canvas in the sidebar, or create a new canvas to start shaping ideas, notes, and diagrams.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
        } actions: {
            Button("New Canvas", action: onNewBoard)
                .keyboardShortcut("n", modifiers: [.command])
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(FlowDeskLayout.spaceXXL)
    }
}
