import WidgetKit
import SwiftUI

struct TimesPlate<Content: View>: View {
    let corner: CGFloat
    @ViewBuilder var content: () -> Content

    init(corner: CGFloat = 14, @ViewBuilder content: @escaping () -> Content) {
        self.corner = corner
        self.content = content
    }

    var body: some View {
        content()
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.white.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: corner, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

