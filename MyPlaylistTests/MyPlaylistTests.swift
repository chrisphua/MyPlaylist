import Testing
@testable import MyPlaylist

// MARK: - TimeFormatter

struct TimeFormatterTests {
    @Test func formatZero() { #expect(TimeFormatter.format(0) == "0:00") }
    @Test func formatSeconds() { #expect(TimeFormatter.format(45) == "0:45") }
    @Test func formatMinutesAndSeconds() { #expect(TimeFormatter.format(90) == "1:30") }
    @Test func formatLargeDuration() { #expect(TimeFormatter.format(3665) == "61:05") }
    @Test func formatNaN() { #expect(TimeFormatter.format(.nan) == "0:00") }
    @Test func formatInfinity() { #expect(TimeFormatter.format(.infinity) == "0:00") }
    @Test func formatNegative() { #expect(TimeFormatter.format(-1) == "0:00") }
}

// MARK: - PlaybackMode

struct PlaybackModeTests {
    @Test func allCasesExist() {
        #expect(PlaybackMode.allCases.count == 3)
    }

    @Test func caseOrder() {
        let cases = PlaybackMode.allCases
        #expect(cases[0] == .next)
        #expect(cases[1] == .repeatOne)
        #expect(cases[2] == .shuffle)
    }

    @Test func systemImages() {
        #expect(PlaybackMode.next.systemImage == "arrow.right")
        #expect(PlaybackMode.repeatOne.systemImage == "repeat.1")
        #expect(PlaybackMode.shuffle.systemImage == "shuffle")
    }

    @Test func rawValues() {
        #expect(PlaybackMode.next.rawValue == "Next")
        #expect(PlaybackMode.repeatOne.rawValue == "Repeat One")
        #expect(PlaybackMode.shuffle.rawValue == "Shuffle")
    }
}

// MARK: - AudioPlayer.nextIndex (Next mode)

struct NextModeTests {
    @Test func advancesForward() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 3, mode: .next) == 1)
    }

    @Test func advancesFromMiddle() {
        #expect(AudioPlayer.nextIndex(current: 1, count: 3, mode: .next) == 2)
    }

    @Test func stopsAtEndOfList() {
        #expect(AudioPlayer.nextIndex(current: 2, count: 3, mode: .next) == nil)
    }

    @Test func emptyLibrary() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 0, mode: .next) == nil)
    }

    @Test func singleTrack() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 1, mode: .next) == nil)
    }
}

// MARK: - AudioPlayer.nextIndex (Repeat One mode)

struct RepeatOneModeTests {
    @Test func replaysCurrentTrack() {
        #expect(AudioPlayer.nextIndex(current: 1, count: 3, mode: .repeatOne) == 1)
    }

    @Test func replaysFirstTrack() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 1, mode: .repeatOne) == 0)
    }

    @Test func replaysLastTrack() {
        #expect(AudioPlayer.nextIndex(current: 4, count: 5, mode: .repeatOne) == 4)
    }

    @Test func emptyLibrary() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 0, mode: .repeatOne) == nil)
    }
}

// MARK: - AudioPlayer.nextIndex (Shuffle mode)

struct ShuffleModeTests {
    @Test func neverReturnsCurrentWithMultipleTracks() {
        for _ in 0..<50 {
            let idx = AudioPlayer.nextIndex(current: 2, count: 5, mode: .shuffle)
            #expect(idx != 2)
        }
    }

    @Test func returnsDifferentTracksOverTime() {
        var seen = Set<Int>()
        for _ in 0..<30 {
            if let idx = AudioPlayer.nextIndex(current: 0, count: 5, mode: .shuffle) {
                seen.insert(idx)
            }
        }
        // With 4 possible choices, we expect variety
        #expect(seen.count > 1)
    }

    @Test func singleTrackReturnsSelf() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 1, mode: .shuffle) == 0)
    }

    @Test func emptyLibrary() {
        #expect(AudioPlayer.nextIndex(current: 0, count: 0, mode: .shuffle) == nil)
    }

    @Test func resultAlwaysInBounds() {
        for _ in 0..<50 {
            if let idx = AudioPlayer.nextIndex(current: 1, count: 4, mode: .shuffle) {
                #expect(idx >= 0)
                #expect(idx < 4)
            }
        }
    }
}

// MARK: - AudioTrack

struct AudioTrackTests {
    @Test func equalityById() {
        let id = UUID()
        let t1 = AudioTrack(id: id, title: "Song A", filename: "a.mp3", duration: 120)
        let t2 = AudioTrack(id: id, title: "Song A", filename: "a.mp3", duration: 120)
        #expect(t1 == t2)
    }

    @Test func inequalityDifferentIds() {
        let t1 = AudioTrack(title: "Song A", filename: "a.mp3")
        let t2 = AudioTrack(title: "Song A", filename: "a.mp3")
        #expect(t1 != t2)
    }

    @Test func codableRoundTrip() throws {
        let track = AudioTrack(title: "Test Song", filename: "song.mp3", duration: 180)
        let data = try JSONEncoder().encode(track)
        let decoded = try JSONDecoder().decode(AudioTrack.self, from: data)
        #expect(decoded.id == track.id)
        #expect(decoded.title == track.title)
        #expect(decoded.filename == track.filename)
        #expect(decoded.duration == track.duration)
    }

    @Test func fileURLContainsFilename() {
        let track = AudioTrack(title: "Test", filename: "test.mp3")
        #expect(track.fileURL.lastPathComponent == "test.mp3")
    }
}
