import SwiftUI

// Two distinct keys so text-width and container-width don't collide.
private struct MarqueeTextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct MarqueeContainerWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct MarqueeText: View {
    let text: String
    var font: Font = .body
    var color: Color = .primary

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var animTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .leading) {
            // Hidden probe to measure the text's full intrinsic width
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .hidden()
                .background(GeometryReader { geo in
                    Color.clear.preference(key: MarqueeTextWidthKey.self, value: geo.size.width)
                })

            // Visible scrolling text
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: offset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .background(GeometryReader { geo in
            Color.clear.preference(key: MarqueeContainerWidthKey.self, value: geo.size.width)
        })
        .onPreferenceChange(MarqueeTextWidthKey.self) { textWidth = $0; restart() }
        .onPreferenceChange(MarqueeContainerWidthKey.self) { containerWidth = $0; restart() }
        .onChange(of: text) { _ in offset = 0; restart() }
        .onDisappear { animTask?.cancel(); offset = 0 }
    }

    // MARK: - Animation

    private func restart() {
        animTask?.cancel()
        offset = 0
        let travel = textWidth - containerWidth
        guard travel > 1 else { return }
        animTask = Task { await scroll(travel: travel) }
    }

    private func scroll(travel: CGFloat) async {
        let duration = Double(travel) / 40.0  // 40 pts/sec

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1.5))   // pause at start
            guard !Task.isCancelled else { break }
            withAnimation(.linear(duration: duration)) { offset = -travel }

            try? await Task.sleep(for: .seconds(duration + 1.5))  // pause at end
            guard !Task.isCancelled else { break }
            withAnimation(.easeIn(duration: 0.35)) { offset = 0 }

            try? await Task.sleep(for: .seconds(0.5))
        }
    }
}
