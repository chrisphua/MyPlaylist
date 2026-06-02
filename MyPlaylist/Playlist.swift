import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var trackIDs: [UUID] = []
}
