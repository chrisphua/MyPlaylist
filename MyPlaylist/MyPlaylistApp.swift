import SwiftUI
import AVFoundation
import GoogleMobileAds

@main
struct MyPlaylistApp: App {
    @StateObject private var library = AudioLibrary()
    @StateObject private var player = AudioPlayer()
    @StateObject private var ads = AdManager()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var playlistManager = PlaylistManager()
    @AppStorage("appAppearance") private var appAppearance = "default"

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case "dark":  return .dark
        case "clear": return .light
        default:      return nil
        }
    }

    init() {
        // Run heavyweight SDK init off the main thread to prevent startup lag
        DispatchQueue.global(qos: .userInitiated).async {
            MyPlaylistApp.configureAudioSession()
            GADMobileAds.sharedInstance().start()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(player)
                .environmentObject(ads)
                .environmentObject(purchases)
                .environmentObject(playlistManager)
                .preferredColorScheme(preferredColorScheme)
                .onChange(of: purchases.isAdFree) { _, adFree in
                    ads.isAdFree = adFree
                }
        }
    }

    private static func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.allowAirPlay, .allowBluetoothA2DP]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
