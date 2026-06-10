import Foundation

enum PlaybackMode: String, CaseIterable, Codable {
    case next = "Next"
    case repeatAll = "Repeat All"
    case repeatOne = "Repeat One"
    case shuffle = "Shuffle"

    var systemImage: String {
        switch self {
        case .next:      return "arrow.right"
        case .repeatAll: return "repeat"
        case .repeatOne: return "repeat.1"
        case .shuffle:   return "shuffle"
        }
    }
}
