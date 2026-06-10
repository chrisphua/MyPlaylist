# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

Use the `BuildProject` MCP tool (xcode-tools) to build. For a quick compiler check on a single file without a full build, use `XcodeRefreshCodeIssuesInFile`.

```bash
# Full build via CLI (when MCP is unavailable)
xcodebuild -project MyPlaylist.xcodeproj -scheme MyPlaylist \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -project MyPlaylist.xcodeproj -scheme MyPlaylist \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Deployment target is **iOS 16.0**, universal **iPhone + iPad** (`TARGETED_DEVICE_FAMILY = 1,2`).

---

## Architecture

### Dependency graph

Five `@StateObject` singletons are created in `MyPlaylistApp` and injected app-wide as `@EnvironmentObject`:

```
MyPlaylistApp
├── AudioLibrary      — import, persistence, artwork loading
├── AudioPlayer       — AVAudioPlayer wrapper, speed, sleep timer, remote controls
├── PlaylistManager   — playlist CRUD and persistence
├── AdManager         — App Store review prompt (no ads; AdMob is commented out)
└── PurchaseManager   — stub (IAP removed; original code in block comment)
```

Every view that needs one of these accesses it via `@EnvironmentObject`. Never pass them as explicit parameters.

### Data persistence

- **Tracks** — JSON-encoded `[AudioTrack]` in `UserDefaults` key `"savedTracks"`. Audio files live in `Documents/AudioFiles/<UUID>.<ext>`.
- **Playlists** — JSON-encoded `[Playlist]` in `UserDefaults` key `"savedPlaylists"`.
- **Preferences** — individual `UserDefaults`/`@AppStorage` keys: `librarySortOrder`, `playbackMode`, `playbackRate`, `appAppearance`, `totalManualPlays`, `lastReviewVersion`.

`AudioTrack.filename` stores only the filename (not the full path). The full URL is computed via `AudioTrack.fileURL` → `AudioLibrary.audioFilesDirectory + filename`. On library load, tracks whose files no longer exist are silently dropped.

### Artwork

`AudioLibrary.artwork(for:)` loads artwork asynchronously via `AVAsset.load(.commonMetadata)`. Results are cached in two structures: a hit cache (`[UUID: UIImage]`) and a miss set (`Set<UUID>`) so failed lookups are not retried. `ArtworkImage` is the shared SwiftUI view for displaying artwork with a music-note placeholder fallback.

When a track starts playing, `NowPlayingView` pushes artwork to `AudioPlayer.currentArtwork`, which triggers `updateNowPlayingInfo()` to update the lock screen / Control Center via `MPNowPlayingInfoCenter`.

### Player

`AudioPlayer` wraps `AVAudioPlayer` (not `AVPlayer` — no video rendering). Key behaviours:
- `enableRate = true` is set before `prepareToPlay()` so `playbackRate` applies immediately.
- A 30 Hz `Timer` drives `currentTime`, `audioLevel` (for the visualiser), and sleep timer checks.
- `setupRemoteControls()` registers `MPRemoteCommandCenter` handlers for lock screen / headphone controls.
- Interruption (calls, Siri) and route-change (headphone unplug) are handled via `NotificationCenter`.

### Mini player bar

`MiniPlayerBar` is injected via `.safeAreaInset(edge: .bottom)` on the `List` or `Group` inside each tab — **not** on `NavigationStack`. Placing it on `NavigationStack` corrupts the hit-test coordinate space and breaks toolbar menus.

### iOS 16 compatibility

- Use single-param `onChange`: `.onChange(of: value) { _ in ... }` not zero-param or two-param form.
- Use `GeometryReader` + `PreferenceKey` instead of `onGeometryChange` (iOS 17+). See `MarqueeText.swift` for the pattern.

---

## Important conventions

**Appearance tag mismatch** — The "Light" appearance option is stored with tag `"clear"` in `@AppStorage` for historical reasons. Do not change the tag value; only the display label is "Light".

**AdMob / IAP stubs** — `GoogleMobileAds` and `GoogleUserMessagingPlatform` are local stub packages (no real SDK). The original implementation is preserved in `/* */` block comments inside `AdManager.swift`, `PurchaseManager.swift`, `MyPlaylistApp.swift`, and `SettingsView.swift`. Do not delete these comments; they exist to allow easy re-enabling.

**`PlaybackMode` case order** — The order of cases in `PlaybackMode.allCases` determines the cycle sequence in the Now Playing bottom bar. Current order: Next → Repeat All → Repeat One → Shuffle.

**iCloud imports** — `AudioLibrary.coordinatedCopy(from:to:)` uses `NSFileCoordinator` to download iCloud placeholders before copying. Always go through this path when copying imported files.

**Duplicate detection** — Import uses a SHA-256 content hash (`AudioLibrary.fileHash`). Tracks with matching hashes are rejected without being copied.
