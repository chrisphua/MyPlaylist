import Foundation
import AVFoundation
import MediaPlayer
import Combine

enum PlayerState {
    case stopped, playing, paused
}

class AudioPlayer: NSObject, ObservableObject {
    @Published private(set) var currentTrack: AudioTrack?
    @Published private(set) var state: PlayerState = .stopped
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var playbackMode: PlaybackMode = .next
    @Published private(set) var audioLevel: Float = 0
    @Published var playbackError: String?

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var tracks: [AudioTrack] = []
    private var currentIndex: Int = 0
    private var isSeeking = false

    private let modeKey = "playbackMode"

    override init() {
        super.init()
        if let raw = UserDefaults.standard.string(forKey: modeKey),
           let saved = PlaybackMode(rawValue: raw) {
            playbackMode = saved
        }
        setupRemoteControls()
        setupAudioSessionObservers()
    }

    // MARK: - Public API

    func play(track: AudioTrack, in tracks: [AudioTrack]) {
        self.tracks = tracks
        self.currentIndex = tracks.firstIndex(of: track) ?? 0
        if track == currentTrack {
            if state == .paused { togglePlayPause() }
        } else {
            load(track: track)
        }
    }

    func togglePlayPause() {
        switch state {
        case .playing:
            player?.pause()
            state = .paused
            stopTimer()
        case .paused:
            player?.play()
            state = .playing
            startTimer()
        case .stopped:
            if let track = currentTrack { load(track: track) }
        }
        updateNowPlayingInfo()
    }

    func stop() {
        stopTimer()        // stop first so timer can't fire during teardown
        player?.stop()
        player = nil
        state = .stopped
        currentTime = 0
        audioLevel = 0
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }

    // Timer keeps running the whole time — no start/stop during drag.
    // seekValue in the view takes display priority over currentTime while non-nil.
    func beginSeeking() {
        isSeeking = true
    }

    func endSeeking(to time: TimeInterval) {
        isSeeking = false
        let clamped = max(0, min(time, duration))
        let atEdge = (duration > 0) && (clamped <= 0.1 || clamped >= duration - 0.1)
        if atEdge {
            stop()
        } else {
            player?.currentTime = clamped
            currentTime = clamped
            updateNowPlayingInfo()
        }
    }

    func playNext() {
        guard let idx = Self.nextIndex(current: currentIndex, count: tracks.count, mode: playbackMode) else {
            stop()
            return
        }
        currentIndex = idx
        load(track: tracks[idx])
    }

    func playPrevious() {
        // Restart current track if within first 3 seconds or at the first track
        if currentTime > 3 || currentIndex == 0 {
            seek(to: 0)
            if state == .paused { player?.play(); state = .playing; startTimer() }
        } else {
            currentIndex -= 1
            load(track: tracks[currentIndex])
        }
    }

    func setPlaybackMode(_ mode: PlaybackMode) {
        playbackMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
    }

    // MARK: - Next-index logic (internal for testability)

    static func nextIndex(current: Int, count: Int, mode: PlaybackMode) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .next:
            let next = current + 1
            return next < count ? next : nil
        case .repeatOne:
            return current
        case .shuffle:
            guard count > 1 else { return 0 }
            var next = Int.random(in: 0..<count)
            // Avoid immediate repeat when more than one track exists
            while next == current { next = Int.random(in: 0..<count) }
            return next
        }
    }

    // MARK: - Private

    private func load(track: AudioTrack) {
        stopTimer()
        player?.stop()

        guard FileManager.default.fileExists(atPath: track.fileURL.path) else {
            state = .stopped
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: track.fileURL)
            p.delegate = self
            p.isMeteringEnabled = true
            p.prepareToPlay()
            player = p
            currentTrack = track
            duration = p.duration
            currentTime = 0
            p.play()
            state = .playing
            startTimer()
            updateNowPlayingInfo()
        } catch {
            state = .stopped
            playbackError = "Could not load \"\(track.title)\". The file may be corrupted or in an unsupported format."
        }
    }

    private func setupAudioSessionObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    // When something (notification sound, Siri, call) interrupts audio, iOS ducks or
    // stops the session. On interrupt-end we reactivate at full volume.
    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeVal)
        else { return }

        DispatchQueue.main.async {
            switch type {
            case .began:
                if self.state == .playing {
                    self.player?.pause()
                    self.state = .paused
                    self.stopTimer()
                    self.updateNowPlayingInfo()
                }
            case .ended:
                // Reactivate session at full volume regardless of shouldResume flag
                try? AVAudioSession.sharedInstance().setActive(true)
                let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume),
                   self.state == .paused {
                    self.player?.play()
                    self.state = .playing
                    self.startTimer()
                    self.updateNowPlayingInfo()
                }
            @unknown default: break
            }
        }
    }

    // Pause when headphones are unplugged so audio doesn't blast from speakers.
    @objc private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonVal = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            AVAudioSession.RouteChangeReason(rawValue: reasonVal) == .oldDeviceUnavailable
        else { return }

        DispatchQueue.main.async {
            if self.state == .playing { self.togglePlayPause() }
        }
    }

    private func setupRemoteControls() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.addTarget { [weak self] _ in
            guard let self, state != .playing else { return .commandFailed }
            togglePlayPause(); return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            guard let self, state == .playing else { return .commandFailed }
            togglePlayPause(); return .success
        }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause(); return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext(); return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious(); return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle:              track.title,
            MPMediaItemPropertyPlaybackDuration:   duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate:  state == .playing ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
        ]
    }

    private func startTimer() {
        stopTimer()  // always clear before creating to prevent orphaned timers
        // 30 Hz: smooth enough for a 60fps visualizer without excessive CPU use
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            player.updateMeters()

            // Blend peak (catches transient beats) with average (sustain) for a punchy feel
            let peak = Float(max(0.0, (Double(player.peakPower(forChannel: 0))    + 60.0) / 60.0))
            let avg  = Float(max(0.0, (Double(player.averagePower(forChannel: 0)) + 60.0) / 60.0))
            let target = peak * 0.65 + avg * 0.35

            // Asymmetric smoothing: snap up fast on beats, fall more slowly between them
            let cur = self.audioLevel
            self.audioLevel = target > cur
                ? cur * 0.15 + target * 0.85   // fast attack
                : cur * 0.72 + target * 0.28   // slow decay
        }
        RunLoop.main.add(t, forMode: .common)
        progressTimer = t
    }

    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard !isSeeking else { return }
        guard flag else { stop(); return }
        switch playbackMode {
        case .repeatOne:
            if let track = currentTrack { load(track: track) }
        case .next, .shuffle:
            playNext()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let title = currentTrack?.title ?? "this track"
        stop()
        playbackError = "Playback failed for \"\(title)\". The file may be corrupted."
    }
}
