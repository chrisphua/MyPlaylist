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
            List {
                Section {
                    NavigationLink {
                        LibraryView(selectedTab: $selectedTab)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Library")
                                .font(.body)
                            Text("\(library.tracks.count) tracks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("My Playlists") {
                    if playlistManager.playlists.isEmpty {
                        Text("Tap + to create your first playlist.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(playlistManager.playlists) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .font(.body)
                                    Text("\(playlistManager.tracks(in: playlist, from: library).count) tracks")
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
            .navigationTitle("Playlist")
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if player.currentTrack != nil, selectedTab != 1 {
                    MiniPlayerBar(selectedTab: $selectedTab)
                }
            }
            .alert("New Playlist", isPresented: $showCreate) {
                TextField("Name", text: $newName)
                Button("Create") { playlistManager.create(name: newName) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
