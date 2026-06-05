import Foundation
import Combine

// MARK: - AdMob disabled
// Uncomment the block below and remove the stub to re-enable ads.

/*
import GoogleMobileAds
import UIKit
import Combine

class AdManager: NSObject, ObservableObject {
    var isAdFree = false   // set by MyPlaylistApp when PurchaseManager.isAdFree changes

    private var interstitial: GADInterstitialAd?
    private var manualPlayCount = 0

    // DEBUG + TestFlight → test ad unit; App Store release → real ad unit.
    private let adUnitID: String = {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        return isTestFlight
            ? "ca-app-pub-3940256099942544/4411468910"
            : "ca-app-pub-3368935744379533/8627015383"
        #endif
    }()
    private let showEvery = 3  // show ad every 3 manually-selected songs

    override init() {
        super.init()
    }

    // Called by MyPlaylistApp after UMP consent is obtained and GAD is initialised.
    func startAdLoading() {
        loadAd()
    }

    // Call this when the user taps a new song in the library (not on autoplay).
    func recordManualPlay() {
        guard !isAdFree else { return }
        manualPlayCount += 1
        if manualPlayCount % showEvery == 0 {
            presentIfReady()
        }
    }

    // MARK: - Private

    private func loadAd() {
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error {
                    print("AdManager: interstitial load failed — \(error.localizedDescription)")
                    return
                }
                self?.interstitial = ad
                self?.interstitial?.fullScreenContentDelegate = self
            }
        }
    }

    private func presentIfReady() {
        guard
            let interstitial,
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        interstitial.present(fromRootViewController: root)
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
        loadAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
        loadAd()
    }
}
*/

class AdManager: NSObject, ObservableObject {
    var isAdFree = false
    func startAdLoading() {}
    func recordManualPlay() {}
}
