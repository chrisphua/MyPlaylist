import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var library: AudioLibrary
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var ads: AdManager

    @Binding var selectedTab: Int
    @State private var showCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            Group {
                if playlistManager.playlists.isEmpty {
                    emptyState
                } else {
                    playlistList
                }
            }
            .navigationTitle("My Playlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newName = ""
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Playlist")
                }
            }
            .alert("New Playlist", isPresented: $showCreate) {
                TextField("Name", text: $newName)
                Button("Create") { playlistManager.create(name: newName) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Playlists Yet")
                .font(.title2.weight(.semibold))
            Text("Tap + to create your first playlist.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var playlistList: some View {
        List {
            ForEach(playlistManager.playlists) { playlist in
                NavigationLink {
                    PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.body)
                        Text("\(playlist.trackIDs.count) songs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete { indexSet in
                for idx in indexSet { playlistManager.delete(playlistManager.playlists[idx]) }
            }
        }
    }
}
