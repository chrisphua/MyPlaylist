import Foundation
import AVFoundation
import Combine

class AudioLibrary: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = []
    @Published var importError: String?
    @Published private(set) var isImporting = false

    private let persistenceKey = "savedTracks"

    // Shared directory where imported audio files are copied for offline playback.
    static let audioFilesDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("AudioFiles")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    init() {
        let directory = Self.audioFilesDirectory
        let key = persistenceKey
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            guard
                let data = UserDefaults.standard.data(forKey: key),
                let saved = try? JSONDecoder().decode([AudioTrack].self, from: data)
            else { return }
            let existing = saved.filter {
                FileManager.default.fileExists(atPath: directory.appendingPathComponent($0.filename).path)
            }
            await MainActor.run {
                self.tracks = existing
                if existing.count != saved.count { self.saveTracks() }
            }
        }
    }

    // MARK: - Import

    // Fire-and-forget convenience used by callers that don't need the result.
    func importFile(from url: URL) {
        Task { await performImport(from: url) }
    }

    // Returns the imported track on success so callers can add it to a playlist.
    @MainActor @discardableResult
    func performImport(from url: URL) async -> AudioTrack? {
        isImporting = true
        defer { isImporting = false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        let supported = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "caf", "flac",
                         "mp4", "m4v", "3gp", "3g2", "opus"]
        guard supported.contains(ext) else {
            importError = "Unsupported format. Supported: MP3, AAC, M4A, WAV, AIFF, FLAC, MP4, CAF, OPUS."
            return nil
        }

        let filename = UUID().uuidString + "." + ext
        let destination = Self.audioFilesDirectory.appendingPathComponent(filename)

        do {
            // NSFileCoordinator downloads iCloud Drive placeholders before copying.
            try await coordinatedCopy(from: url, to: destination)
            let duration = audioDuration(for: destination)
            let title = url.deletingPathExtension().lastPathComponent
            let track = AudioTrack(title: title, filename: filename, duration: duration)
            tracks.append(track)
            saveTracks()
            return track
        } catch {
            importError = "Could not import the file. If it's stored in iCloud, make sure it has finished downloading and try again."
            return nil
        }
    }

    // Coordinates file access so iOS downloads iCloud files before we copy them.
    private func coordinatedCopy(from source: URL, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var coordinatorError: NSError?
                var blockCalled = false
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(
                    readingItemAt: source,
                    options: .withoutChanges,
                    error: &coordinatorError
                ) { localURL in
                    blockCalled = true
                    do {
                        try FileManager.default.copyItem(at: localURL, to: destination)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                if !blockCalled, let error = coordinatorError {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Delete

    func deleteTrack(_ track: AudioTrack) {
        tracks.removeAll { $0.id == track.id }
        try? FileManager.default.removeItem(at: track.fileURL)
        saveTracks()
    }

    // MARK: - Persistence

    private func saveTracks() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }


    // MARK: - Helpers

    private func audioDuration(for url: URL) -> TimeInterval {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        return player.duration
    }
}
