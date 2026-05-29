import Foundation

struct AudioTrack: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var filename: String  // filename only; file lives in the app's AudioFiles directory
    var duration: TimeInterval

    init(id: UUID = UUID(), title: String, filename: String, duration: TimeInterval = 0) {
        self.id = id
        self.title = title
        self.filename = filename
        self.duration = duration
    }

    var fileURL: URL {
        AudioLibrary.audioFilesDirectory.appendingPathComponent(filename)
    }
}
