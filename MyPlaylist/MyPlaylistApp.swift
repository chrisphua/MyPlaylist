import SwiftUI
import AVFoundation
import GoogleMobileAds
import UserMessagingPlatform

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
        DispatchQueue.global(qos: .userInitiated).async {
            MyPlaylistApp.configureAudioSession()
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
                .task { await requestConsentAndStartAds() }
        }
    }

    @MainActor
    private func requestConsentAndStartAds() async {
        // 1. Request UMP consent info update (handles GDPR + ATT for iOS)
        let params = UMPRequestParameters()
        await withCheckedContinuation { cont in
            UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: params) { _ in
                cont.resume()
            }
        }

        // 2. Show consent form if required
        if let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
            .first {
            await withCheckedContinuation { cont in
                UMPConsentForm.loadAndPresentIfRequired(from: rootVC) { _ in
                    cont.resume()
                }
            }
        }

        // 3. Initialise GAD and start loading ads only after consent is resolved
        guard UMPConsentInformation.sharedInstance.canRequestAds else { return }
        await withCheckedContinuation { cont in
            GADMobileAds.sharedInstance().start { _ in cont.resume() }
        }
        ads.startAdLoading()
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
