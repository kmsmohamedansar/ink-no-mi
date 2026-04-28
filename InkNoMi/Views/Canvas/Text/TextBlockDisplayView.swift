import SwiftUI

struct TextBlockDisplayView: View {
    let payload: TextBlockPayload

    var body: some View {
        Group {
            if payload.text.isEmpty {
                Text("Double-click to edit")
                    .font(payload.swiftUIFont)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: payload.alignment.frameAlignment)
            } else {
                Text(payload.text)
                    .font(payload.swiftUIFont)
                    .foregroundStyle(payload.color.swiftUIColor)
                    .multilineTextAlignment(payload.alignment.multilineTextAlignment)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: payload.alignment.frameAlignment)
            }
        }
    }
}
