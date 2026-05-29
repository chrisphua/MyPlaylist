import Foundation

enum TimeFormatter {
    static func format(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "0:00" }
        let t = Int(time)
        let minutes = t / 60
        let seconds = t % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
