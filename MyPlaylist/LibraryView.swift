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
    @AppStorage("librarySortOrder") private var sortOrder = "newest"

    @State private var trackToRename: AudioTrack?
    @State private var renameText = ""

    @State private var isSelecting = false
    @State private var selectedTrackIDs = Set<UUID>()
    @State private var showBulkAddToPlaylist = false
    @State private var showBulkDeleteConfirm = false

    private var displayedTracks: [AudioTrack] {
        let sorted: [AudioTrack]
        switch sortOrder {
        case "title":    sorted = library.tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case "duration": sorted = library.tracks.sorted { $0.duration < $1.duration }
        case "oldest":   sorted = library.tracks
        default:         sorted = Array(library.tracks.reversed())
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if library.tracks.isEmpty {
                emptyState
            } else if displayedTracks.isEmpty {
                noResultsState
            } else {
                trackList
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isSelecting {
                bulkActionBar
            } else if player.currentTrack != nil, selectedTab != 1 {
                MiniPlayerBar(selectedTab: $selectedTab)
            }
        }
        .navigationTitle(isSelecting ? "\(selectedTrackIDs.count) Selected" : "Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search tracks")
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isSelecting = false
                        selectedTrackIDs = []
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(selectedTrackIDs.count == displayedTracks.count && !displayedTracks.isEmpty ? "Deselect All" : "Select All") {
                        if selectedTrackIDs.count == displayedTracks.count {
                            selectedTrackIDs = []
                        } else {
                            selectedTrackIDs = Set(displayedTracks.map { $0.id })
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            Text("Newest First").tag("newest")
                            Text("Oldest First").tag("oldest")
                            Text("Title A–Z").tag("title")
                            Text("Duration").tag("duration")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Select") { isSelecting = true }
                        .disabled(library.tracks.isEmpty)
                }
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
        .alert("Rename Track", isPresented: Binding(
            get: { trackToRename != nil },
            set: { if !$0 { trackToRename = nil } }
        )) {
            TextField("Title", text: $renameText)
            Button("Save") {
                if let track = trackToRename { library.renameTrack(track, to: renameText) }
                trackToRename = nil
            }
            Button("Cancel", role: .cancel) { trackToRename = nil }
        }
        .confirmationDialog(
            "Delete \(selectedTrackIDs.count) track\(selectedTrackIDs.count == 1 ? "" : "s")?",
            isPresented: $showBulkDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                for id in selectedTrackIDs {
                    guard let track = library.tracks.first(where: { $0.id == id }) else { continue }
                    if player.currentTrack?.id == track.id { player.stop() }
                    playlistManager.removeFromAllPlaylists(track)
                    library.deleteTrack(track)
                }
                isSelecting = false
                selectedTrackIDs = []
            }
        }
        .sheet(isPresented: $showBulkAddToPlaylist) {
            NavigationStack {
                List(playlistManager.playlists) { playlist in
                    Button(playlist.name) {
                        for id in selectedTrackIDs {
                            guard let track = library.tracks.first(where: { $0.id == id }) else { continue }
                            playlistManager.addTrack(track, to: playlist)
                        }
                        showBulkAddToPlaylist = false
                        isSelecting = false
                        selectedTrackIDs = []
                    }
                    .foregroundStyle(.primary)
                }
                .navigationTitle("Add to Playlist")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showBulkAddToPlaylist = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Tracks Yet")
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
            Text("No tracks match \"\(searchText)\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var bulkActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                Button {
                    showBulkAddToPlaylist = true
                } label: {
                    Label("Add to Playlist", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .disabled(selectedTrackIDs.isEmpty || playlistManager.playlists.isEmpty)

                Divider().frame(height: 24)

                Button(role: .destructive) {
                    showBulkDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .disabled(selectedTrackIDs.isEmpty)
            }
            .font(.subheadline.weight(.medium))
        }
        .background(.ultraThinMaterial)
    }

    private var trackList: some View {
        List {
            if isSelecting {
                ForEach(displayedTracks) { track in
                    Button {
                        if selectedTrackIDs.contains(track.id) {
                            selectedTrackIDs.remove(track.id)
                        } else {
                            selectedTrackIDs.insert(track.id)
                        }
                    } label: {
                        TrackRow(
                            track: track,
                            isCurrentTrack: false,
                            isPlaying: false,
                            isSelected: selectedTrackIDs.contains(track.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ForEach(displayedTracks) { track in
                    Button {
                        if player.currentTrack?.id != track.id { ads.recordManualPlay() }
                        player.play(track: track, in: displayedTracks)
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
                        Button {
                            renameText = track.title
                            trackToRename = track
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
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
                        let track = displayedTracks[index]
                        if player.currentTrack?.id == track.id { player.stop() }
                        playlistManager.removeFromAllPlaylists(track)
                        library.deleteTrack(track)
                    }
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
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                ArtworkImage(track: track, size: 44)
                if isSelected {
                    RoundedRectangle(cornerRadius: 44 * 0.18)
                        .fill(Color.blue.opacity(0.85))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else if isPlaying {
                    RoundedRectangle(cornerRadius: 44 * 0.18)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 44, height: 44)
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
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
