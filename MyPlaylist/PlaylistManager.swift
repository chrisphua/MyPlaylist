import Foundation
import SwiftUI
import Combine

@MainActor
class PlaylistManager: ObservableObject {
    @Published private(set) var playlists: [Playlist] = []

    private let key = "savedPlaylists"

    init() { load() }

    // MARK: - CRUD

    func create(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playlists.append(Playlist(name: trimmed))
        save()
    }

    func delete(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    func rename(playlistID: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[idx].name = trimmed
        save()
    }

    // MARK: - Track management

    func addTrack(_ track: AudioTrack, to playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }),
              !playlists[idx].trackIDs.contains(track.id) else { return }
        playlists[idx].trackIDs.append(track.id)
        save()
    }

    func removeTrack(_ track: AudioTrack, from playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[idx].trackIDs.removeAll { $0 == track.id }
        save()
    }

    func removeFromAllPlaylists(_ track: AudioTrack) {
        for idx in playlists.indices {
            playlists[idx].trackIDs.removeAll { $0 == track.id }
        }
        save()
    }

    func moveTracks(in playlist: Playlist, from source: IndexSet, to destination: Int) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[idx].trackIDs.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func tracks(in playlist: Playlist, from library: AudioLibrary) -> [AudioTrack] {
        playlist.trackIDs.compactMap { id in library.tracks.first { $0.id == id } }
    }

    func live(_ playlist: Playlist) -> Playlist {
        playlists.first { $0.id == playlist.id } ?? playlist
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode([Playlist].self, from: data)
        else { return }
        playlists = saved
    }
}
