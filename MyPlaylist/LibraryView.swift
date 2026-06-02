import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var library: AudioLibrary
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var ads: AdManager
    @EnvironmentObject private var playlistManager: PlaylistManager

    @Binding var selectedTab: Int
    @State private var showImporter = false
    @State private var searchText = ""

    private var filteredTracks: [AudioTrack] {
        if searchText.isEmpty { return library.tracks }
        return library.tracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.tracks.isEmpty {
                    emptyState
                } else if filteredTracks.isEmpty {
                    noResultsState
                } else {
                    trackList
                }
            }
            .navigationTitle("Playlist")
            .searchable(text: $searchText, prompt: "Search songs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if library.isImporting {
                        ProgressView()
                    } else {
                        Button {
                            showImporter = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Import audio file")
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.audio, .mpeg4Movie, .movie],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls { library.importFile(from: url) }
                case .failure:
                    library.importError = "Could not access the selected file."
                }
            }
            .alert("Import Error", isPresented: Binding(
                get: { library.importError != nil },
                set: { if !$0 { library.importError = nil } }
            )) {
                Button("OK") { library.importError = nil }
            } message: {
                Text(library.importError ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Songs Yet")
                .font(.title2.weight(.semibold))
            Text("Tap + to import audio files from the Files app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Results")
                .font(.title3.weight(.semibold))
            Text("No songs match \"\(searchText)\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var trackList: some View {
        List {
            ForEach(filteredTracks) { track in
                Button {
                    if player.currentTrack?.id != track.id { ads.recordManualPlay() }
                    player.play(track: track, in: library.tracks)
                    selectedTab = 1
                } label: {
                    TrackRow(
                        track: track,
                        isCurrentTrack: player.currentTrack?.id == track.id,
                        isPlaying: player.currentTrack?.id == track.id && player.state == .playing
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if !playlistManager.playlists.isEmpty {
                        Menu("Add to Playlist") {
                            ForEach(playlistManager.playlists) { playlist in
                                Button(playlist.name) {
                                    playlistManager.addTrack(track, to: playlist)
                                }
                            }
                        }
                    } else {
                        Button("No Playlists — create one in My Playlists") {}
                            .disabled(true)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let track = filteredTracks[index]
                    if player.currentTrack?.id == track.id { player.stop() }
                    library.deleteTrack(track)
                }
            }
        }
    }
}

// MARK: - TrackRow (internal so PlaylistDetailView can reuse it)

struct TrackRow: View {
    let track: AudioTrack
    let isCurrentTrack: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "music.note")
                .foregroundStyle(isCurrentTrack ? .blue : .secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.body)
                    .foregroundStyle(isCurrentTrack ? Color.blue : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if track.duration > 0 {
                    Text(TimeFormatter.format(track.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
