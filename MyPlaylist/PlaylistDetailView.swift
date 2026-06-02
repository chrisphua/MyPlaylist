import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @Binding var selectedTab: Int

    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var library: AudioLibrary
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var ads: AdManager

    @State private var showAddSongs = false
    @State private var showRename = false
    @State private var newName = ""
    @State private var editMode: EditMode = .inactive

    private var live: Playlist { playlistManager.live(playlist) }
    private var tracks: [AudioTrack] { playlistManager.tracks(in: live, from: library) }

    var body: some View {
        Group {
            if tracks.isEmpty {
                emptyState
            } else {
                trackList
            }
        }
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.large)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showAddSongs = true } label: {
                        Label("Add Songs", systemImage: "plus")
                    }
                    Button {
                        newName = live.name
                        showRename = true
                    } label: {
                        Label("Rename Playlist", systemImage: "pencil")
                    }
                    Button {
                        editMode = editMode == .active ? .inactive : .active
                    } label: {
                        Label(editMode == .active ? "Done" : "Reorder / Remove",
                              systemImage: editMode == .active ? "checkmark" : "arrow.up.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddSongs) {
            AddSongsView(playlist: live)
        }
        .alert("Rename Playlist", isPresented: $showRename) {
            TextField("Name", text: $newName)
            Button("Save") { playlistManager.rename(playlistID: live.id, to: newName) }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Songs Yet")
                .font(.title2.weight(.semibold))
            Button("Add Songs") { showAddSongs = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var trackList: some View {
        List {
            Button {
                guard let first = tracks.first else { return }
                ads.recordManualPlay()
                player.play(track: first, in: tracks)
                selectedTab = 1
            } label: {
                Label("Play All", systemImage: "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
            }

            ForEach(tracks) { track in
                Button {
                    if player.currentTrack?.id != track.id { ads.recordManualPlay() }
                    player.play(track: track, in: tracks)
                    selectedTab = 1
                } label: {
                    TrackRow(
                        track: track,
                        isCurrentTrack: player.currentTrack?.id == track.id,
                        isPlaying: player.currentTrack?.id == track.id && player.state == .playing
                    )
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for idx in indexSet { playlistManager.removeTrack(tracks[idx], from: live) }
            }
            .onMove { from, to in
                playlistManager.moveTracks(in: live, from: from, to: to)
            }
        }
    }
}

// MARK: - Add Songs Sheet

struct AddSongsView: View {
    let playlist: Playlist

    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var library: AudioLibrary
    @Environment(\.dismiss) private var dismiss

    private var live: Playlist { playlistManager.live(playlist) }

    var body: some View {
        NavigationStack {
            List(library.tracks) { track in
                let inPlaylist = live.trackIDs.contains(track.id)
                Button {
                    if inPlaylist {
                        playlistManager.removeTrack(track, from: live)
                    } else {
                        playlistManager.addTrack(track, to: live)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .foregroundStyle(Color.primary)
                            if track.duration > 0 {
                                Text(TimeFormatter.format(track.duration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: inPlaylist ? "checkmark.circle.fill" : "plus.circle")
                            .foregroundStyle(inPlaylist ? .blue : .secondary)
                            .font(.title3)
                    }
                }
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
