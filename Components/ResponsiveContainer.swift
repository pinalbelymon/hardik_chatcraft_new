import SwiftUI

struct ResponsiveContainer<Content: View>: View {
    let maxWidth: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content

    init(maxWidth: CGFloat = 920, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.maxWidth = maxWidth
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let verticalPadding = DeviceSize.verticalPadding(
                for: geometry.size.width,
                height: geometry.size.height
            )

            ScrollView {
                content(geometry.size.width)
                    .padding(.horizontal, DeviceSize.horizontalPadding(for: geometry.size.width))
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: min(maxWidth, geometry.size.width), alignment: .top)
                    .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
