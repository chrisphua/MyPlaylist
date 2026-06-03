import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayer
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlaylistsView(selectedTab: $selectedTab)
                .tabItem { Label("Playlist", systemImage: "music.note.list") }
                .tag(0)
            NowPlayingView()
                .tabItem { Label("Now Playing", systemImage: "play.circle") }
                .tag(1)
            SettingsView(selectedTab: $selectedTab)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .alert("Playback Error", isPresented: Binding(
            get: { player.playbackError != nil },
            set: { if !$0 { player.playbackError = nil } }
        )) {
            Button("OK") { player.playbackError = nil }
        } message: {
            Text(player.playbackError ?? "")
        }
    }
}

// MARK: - MiniPlayerBar

struct MiniPlayerBar: View {
    @EnvironmentObject private var player: AudioPlayer
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            progressBar
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.title ?? "")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(player.state == .playing ? "Playing" : "Paused")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { selectedTab = 1 }

                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Button {
                    player.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let pct = player.duration > 0 ? CGFloat(player.currentTime / player.duration) : 0
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: pct * geo.size.width, height: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 2)
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioLibrary())
        .environmentObject(AudioPlayer())
}
