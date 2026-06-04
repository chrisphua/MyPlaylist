<div align="center">

# MyPlaylist

**Offline music player for iOS — import files, build playlists, play.**

[![App Store](https://img.shields.io/badge/App%20Store-Download-0071E3?logo=apple&logoColor=white)](https://chrisphua.github.io/MyPlaylist)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-0071E3?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-2cb67d)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=github-sponsors)](https://github.com/sponsors/chrisphua)

</div>

---

## Overview

**MyPlaylist** is a clean, offline-first iOS music player. Import audio and video files directly from your device or iCloud Drive, organise them into playlists, and enjoy distraction-free playback — no streaming accounts, no internet required.

---

## Features

- 🎵 **Multi-format import** — MP3, AAC, M4A, WAV, AIFF, FLAC, MP4, CAF, OPUS, and more
- 📂 **Playlist management** — Create, rename, reorder, and delete playlists
- 🎛 **Audio visualiser** — Pulsing ball with radial amplitude lines, synced to the music
- 🔁 **Playback modes** — Sequential, Repeat One, Repeat All, Shuffle
- 🌗 **Appearance** — Dark, Light, or follow System setting
- 🌍 **Localisation** — English, Spanish, French, German, Portuguese, Japanese, Korean, Simplified Chinese, Traditional Chinese, Arabic
- 📵 **Offline first** — All imported files are stored locally — no streaming required
- 🔒 **Portrait mode** — Optimised single-orientation UI

---

## Preview

Visit the **[landing page](https://chrisphua.github.io/MyPlaylist)** for an overview of the app.

---

## Requirements

- **Xcode** 15+
- **iOS** 17+
- **Swift** 5.9+

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/chrisphua/MyPlaylist.git
   cd MyPlaylist
   ```

2. Open `MyPlaylist.xcodeproj` in Xcode.

3. Select your target device or simulator and press **⌘R** to build and run.

> **Note:** Ad unit IDs are included for development. Debug and TestFlight builds use Google's test ad units automatically.

---

## Architecture

```
MyPlaylist/
├── AudioLibrary.swift       # File import, persistence, track management
├── AudioPlayer.swift        # AVAudioPlayer wrapper, metering, playback state
├── PlaylistManager.swift    # Playlist CRUD and persistence
├── HexVisualizerView.swift  # Canvas-based audio visualiser (60 fps)
├── ContentView.swift        # Tab structure
├── PlaylistsView.swift      # Playlist list tab
├── PlaylistDetailView.swift # Tracks within a playlist
├── NowPlayingView.swift     # Now Playing screen
├── LibraryView.swift        # Full track library with search
└── SettingsView.swift       # Appearance & in-app purchase
```

---

## Sponsor

If you find MyPlaylist useful, consider sponsoring development!

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors)](https://github.com/sponsors/chrisphua)

---

## License

Distributed under the MIT License. See `LICENSE` for details.
