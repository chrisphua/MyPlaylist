import SwiftUI

struct ArtworkImage: View {
    let track: AudioTrack
    let size: CGFloat

    @EnvironmentObject private var library: AudioLibrary
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
            } else {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: track.id) {
            image = await library.artwork(for: track)
        }
    }
}
