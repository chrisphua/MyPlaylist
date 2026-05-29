import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(selectedTab: $selectedTab)
                .tabItem { Label("Playlist", systemImage: "music.note.list") }
                .tag(0)
            NowPlayingView()
                .tabItem { Label("Now Playing", systemImage: "play.circle") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioLibrary())
        .environmentObject(AudioPlayer())
}
