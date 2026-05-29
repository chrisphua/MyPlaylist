import Foundation

enum PlaybackMode: String, CaseIterable, Codable {
    case next = "Next"
    case repeatOne = "Repeat One"
    case shuffle = "Shuffle"

    var systemImage: String {
        switch self {
        case .next:      return "arrow.right"
        case .repeatOne: return "repeat.1"
        case .shuffle:   return "shuffle"
        }
    }
}
