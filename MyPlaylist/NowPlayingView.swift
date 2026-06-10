import SwiftUI
import UIKit

struct NowPlayingView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var library: AudioLibrary
    @EnvironmentObject private var playlistManager: PlaylistManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var seekValue: Double? = nil  // non-nil only while user is dragging
    @State private var currentArtwork: UIImage? = nil
    @State private var showSpeedDialog = false
    @State private var showSleepDialog = false
    @State private var showAddToPlaylistDialog = false
    @State private var selectedSleepMinutes: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                if player.currentTrack == nil {
                    emptyState
                } else {
                    playerContent
                }
            }
            .navigationTitle("Now Playing")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddToPlaylistDialog = true
                    } label: {
                        Label("Add to Playlist", systemImage: "text.badge.plus")
                    }
                    .disabled(player.currentTrack == nil || playlistManager.playlists.isEmpty)
                    .popover(isPresented: $showAddToPlaylistDialog, arrowEdge: .top) {
                        addToPlaylistPopover
                            .compactPopover()
                    }
                }
            }
            .onChange(of: player.currentTrack?.id) { _ in seekValue = nil }
            .onChange(of: player.state) { _ in if player.state == .stopped { seekValue = nil } }
            .task(id: player.currentTrack?.id) {
                currentArtwork = nil
                player.currentArtwork = nil
                guard let track = player.currentTrack else { return }
                let art = await library.artwork(for: track)
                currentArtwork = art
                player.currentArtwork = art
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Nothing Playing")
                .font(.title2.weight(.semibold))
            Text("Go to Playlist and tap a song to start playing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Player content

    private var playerContent: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
    }

    private var artworkOrVisualizer: some View {
        Group {
            if let image = currentArtwork {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
            } else {
                HexVisualizerView()
            }
        }
    }

    // Two-column layout for iPad / large screens
    private var iPadLayout: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(spacing: 20) {
                Spacer()
                artworkOrVisualizer
                    .frame(maxWidth: 440)
                trackInfo
                Spacer()
            }
            .frame(maxWidth: .infinity)

            Divider().padding(.vertical, 48)

            VStack(spacing: 28) {
                Spacer()
                progressSection
                transportControls
                bottomBar
                Spacer()
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            Spacer()

            artworkOrVisualizer

            Spacer()

            VStack(spacing: 24) {
                trackInfo
                progressSection
                transportControls
                bottomBar
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 80)
        }
    }

    // MARK: - Subviews

    private var trackInfo: some View {
        Text(player.currentTrack?.title ?? "")
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            SeekBar(
                currentTime: player.currentTime,
                duration: player.duration,
                seekValue: $seekValue,
                onDragStart: { player.beginSeeking() },
                onDragEnd: { time in
                    player.endSeeking(to: time)
                    seekValue = nil
                }
            )
            HStack {
                Text(TimeFormatter.format(seekValue ?? player.currentTime))
                Spacer()
                Text(TimeFormatter.format(player.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }

    private var transportControls: some View {
        HStack(spacing: 44) {
            Button {
                player.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
            }
            .accessibilityLabel("Previous")

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)
            }
            .accessibilityLabel(player.state == .playing ? "Pause" : "Play")

            Button {
                player.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
            }
            .accessibilityLabel("Next")
        }
    }

    private var bottomBar: some View {
        HStack {
            // Speed
            Button { showSpeedDialog = true } label: {
                Text(speedLabel(player.playbackRate))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(width: 58, height: 44)
                    .background(
                        player.playbackRate != 1.0 ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSpeedDialog, arrowEdge: .bottom) {
                speedPopover.compactPopover()
            }

            Spacer()

            // Playback mode
            Button { cycleMode() } label: {
                HStack(spacing: 6) {
                    Image(systemName: player.playbackMode.systemImage)
                    Text(LocalizedStringKey(player.playbackMode.rawValue))
                        .font(.subheadline)
                }
            }
            .accessibilityLabel("Playback mode: \(player.playbackMode.rawValue)")

            Spacer()

            // Sleep timer
            Button { showSleepDialog = true } label: {
                ZStack {
                    Text(player.sleepTimerEnd.map {
                        TimeFormatter.format(max(0, $0.timeIntervalSinceNow).rounded(.up))
                    } ?? "")
                    .monospacedDigit()
                    .opacity(player.sleepTimerEnd != nil ? 1 : 0)

                    Image(systemName: "moon.zzz")
                        .opacity(player.sleepTimerEnd == nil ? 1 : 0)
                }
                .font(.subheadline.weight(.semibold))
                .frame(width: 58, height: 44)
                .background(
                    player.sleepTimerEnd != nil ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSleepDialog, arrowEdge: .bottom) {
                sleepPopover.compactPopover()
            }
            .onChange(of: player.sleepTimerEnd) { end in
                if end == nil { selectedSleepMinutes = 0 }
            }
        }
    }

    private var speedPopover: some View {
        let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        return VStack(spacing: 0) {
            ForEach(Array(rates.enumerated()), id: \.offset) { idx, rate in
                Button {
                    player.setPlaybackRate(rate)
                    showSpeedDialog = false
                } label: {
                    HStack {
                        Text(speedLabel(rate)).foregroundStyle(.primary)
                        Spacer()
                        if player.playbackRate == rate {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < rates.count - 1 { Divider() }
            }
        }
        .frame(minWidth: 200)
    }

    private var sleepPopover: some View {
        VStack(spacing: 0) {
            sleepOptionRow("Off", minutes: 0)
            Divider()
            sleepOptionRow("15 minutes", minutes: 15)
            Divider()
            sleepOptionRow("30 minutes", minutes: 30)
            Divider()
            sleepOptionRow("45 minutes", minutes: 45)
            Divider()
            sleepOptionRow("60 minutes", minutes: 60)
        }
        .frame(minWidth: 220)
    }

    private func sleepOptionRow(_ title: String, minutes: Int) -> some View {
        Button {
            if minutes == 0 { player.cancelSleepTimer() } else { player.setSleepTimer(minutes: minutes) }
            selectedSleepMinutes = minutes
            showSleepDialog = false
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                if selectedSleepMinutes == minutes {
                    Image(systemName: "checkmark").foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addToPlaylistPopover: some View {
        let playlists = playlistManager.playlists
        return VStack(spacing: 0) {
            ForEach(Array(playlists.enumerated()), id: \.element.id) { idx, playlist in
                Button {
                    if let track = player.currentTrack {
                        playlistManager.addTrack(track, to: playlist)
                    }
                    showAddToPlaylistDialog = false
                } label: {
                    HStack {
                        Text(playlist.name).foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < playlists.count - 1 { Divider() }
            }
        }
        .frame(minWidth: 240)
    }

    // MARK: - Helpers

    private var playPauseIcon: String {
        player.state == .playing ? "pause.circle.fill" : "play.circle.fill"
    }

    private func cycleMode() {
        let all = PlaybackMode.allCases
        let idx = all.firstIndex(of: player.playbackMode) ?? 0
        player.setPlaybackMode(all[(idx + 1) % all.count])
    }

    private func speedLabel(_ rate: Float) -> String {
        rate == 1.0 ? "1×" : String(format: "%.3g×", rate)
    }
}
// MARK: - Compact popover helper (forces popover on iPhone; iOS 16.4+)

extension View {
    func compactPopover() -> some View {
        modifier(CompactPopoverModifier())
    }
}

private struct CompactPopoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}

// MARK: - SeekBar

private struct SeekBar: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    @Binding var seekValue: Double?
    let onDragStart: () -> Void
    let onDragEnd: (TimeInterval) -> Void

    private var displayed: Double { seekValue ?? currentTime }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let pct = duration > 0 ? CGFloat(displayed / duration) : 0
            let filled = (pct * w).clamped(to: 0...w)
            let thumbOffset = (filled - 11).clamped(to: 0...(w - 22))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: filled, height: 4)
                Circle()
                    .fill(Color.primary)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                    .offset(x: thumbOffset)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if seekValue == nil {
                            onDragStart()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        let t = Double(v.location.x / w) * duration
                        seekValue = t.clamped(to: 0...duration)
                    }
                    .onEnded { v in
                        let t = Double(v.location.x / w) * duration
                        onDragEnd(t.clamped(to: 0...duration))
                    }
            )
        }
        .frame(height: 30)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

