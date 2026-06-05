import SwiftUI
// import StoreKit // disabled — IAP removed

struct SettingsView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var player: AudioPlayer
    @AppStorage("appAppearance") private var appAppearance = "default"

    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $appAppearance) {
                        Text("Default").tag("default")
                        Text("Dark").tag("dark")
                        Text("Clear").tag("clear")
                    }
                    .pickerStyle(.segmented)
                }

                // Disabled — IAP removed
//                Section("Remove Ads") {
//                    if purchases.isAdFree {
//                        Label("Ads Removed", systemImage: "checkmark.circle.fill")
//                            .foregroundStyle(.green)
//                    } else {
//                        Button {
//                            Task { await purchases.purchase() }
//                        } label: {
//                            HStack {
//                                Text("Remove Ads")
//                                Spacer()
//                                if purchases.isLoading {
//                                    ProgressView()
//                                } else {
//                                    Text(purchases.product?.displayPrice ?? "$0.99")
//                                        .foregroundStyle(.secondary)
//                                }
//                            }
//                        }
//                        .disabled(purchases.isLoading)
//
//                        Button("Restore Purchase") {
//                            Task { await purchases.restore() }
//                        }
//                        .disabled(purchases.isLoading)
//                    }
//                }

                Section("Legal") {
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("User Agreement") {
                        UserAgreementView()
                    }
                }

                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if player.currentTrack != nil, selectedTab != 1 {
                    MiniPlayerBar(selectedTab: $selectedTab)
                }
            }
            .navigationTitle("Settings")
            // Disabled — IAP removed
//            .alert("Purchase Error", isPresented: Binding(
//                get: { purchases.errorMessage != nil },
//                set: { if !$0 { purchases.errorMessage = nil } }
//            )) {
//                Button("OK") { purchases.errorMessage = nil }
//            } message: {
//                Text(purchases.errorMessage ?? "")
//            }
        }
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                policySection(
                    title: "Privacy Policy",
                    body: "Last updated: June 2026\n\nThis policy describes how MyPlaylist handles your information."
                )
                policySection(
                    title: "1. Data We Collect",
                    body: "MyPlaylist does not collect, store, or transmit any personal data to our servers. All audio files and playlists remain on your device.\n\nThe app uses Google Mobile Ads, which may collect certain device identifiers and usage data to serve advertisements. This is subject to Google's Privacy Policy."
                )
                policySection(
                    title: "2. Advertising",
                    body: "MyPlaylist displays advertisements provided by Google AdMob. Google may use your device's advertising identifier (IDFA) to show relevant ads. You can opt out of personalised ads at any time via iOS Settings → Privacy & Security → Tracking.\n\nIf you purchase 'Remove Ads', no advertisements will be shown and no advertising data will be collected."
                )
                policySection(
                    title: "3. App Tracking Transparency",
                    body: "On iOS 14 and later, MyPlaylist will ask for your permission before accessing your device's advertising identifier. You can change your preference at any time in iOS Settings → Privacy & Security → Tracking → MyPlaylist."
                )
                policySection(
                    title: "4. In-App Purchases",
                    body: "Purchase transactions are handled entirely by Apple. MyPlaylist does not have access to your payment information. Apple's privacy policy applies to all transactions."
                )
                policySection(
                    title: "5. Local Storage",
                    body: "Your library tracks and playlists are stored locally on your device using Apple's standard storage APIs. This data is not shared with anyone."
                )
                policySection(
                    title: "6. Contact",
                    body: "If you have questions about this policy, you can reach us via the GitHub repository at github.com/chrisphua/MyPlaylist."
                )
            }
            .padding(20)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - User Agreement

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    agreementSection(
                        title: "User Agreement",
                        body: "Last updated: May 2026\n\nPlease read this agreement carefully before using MyPlaylist (the \"App\"). By using the App, you agree to be bound by the terms set out below. If you do not agree, do not use the App."
                    )

                    agreementSection(
                        title: "1. About the App",
                        body: "MyPlaylist is a local, offline audio player. It allows you to import audio files stored on your device and play them back privately. The App does not stream, download, distribute, or transmit audio content over any network."
                    )

                    agreementSection(
                        title: "2. Your Responsibility for Content",
                        body: "You are solely responsible for the audio files you import into the App. You represent and warrant that you have the legal right to access, store, and play back any content you add to your library.\n\nThe App is intended for personal playback of audio files you own or are otherwise authorized to use. It is not intended for, and must not be used for, the playback of content in violation of any applicable copyright, licence, or intellectual property law."
                    )

                    agreementSection(
                        title: "3. No Liability for Misuse",
                        body: "The software provider accepts no responsibility or liability of any kind for any misuse of the App by you or any third party. This includes, without limitation:\n\n• Importing, storing, or playing back audio content without authorization;\n• Infringing the intellectual property rights of any third party;\n• Any loss, claim, or damage arising from content you add to the App;\n• Any consequence of distributing, sharing, or publicly performing imported content.\n\nAny misuse of the App is entirely at your own risk and is your sole legal responsibility."
                    )

                    agreementSection(
                        title: "4. Disclaimer of Warranties",
                        body: "The App is provided \"as is\" and \"as available\", without warranty of any kind, express or implied. The software provider makes no warranties regarding fitness for a particular purpose, merchantability, or uninterrupted operation. Use of the App is at your own risk."
                    )

                    agreementSection(
                        title: "5. Limitation of Liability",
                        body: "To the maximum extent permitted by applicable law, the software provider shall not be liable for any direct, indirect, incidental, special, consequential, or exemplary damages arising out of or in connection with your use of the App, including but not limited to loss of data, loss of profits, or any other intangible losses."
                    )

                    agreementSection(
                        title: "6. Changes to This Agreement",
                        body: "The software provider reserves the right to update this agreement at any time. Continued use of the App following any update constitutes your acceptance of the revised terms."
                    )

                    agreementSection(
                        title: "7. Governing Law",
                        body: "This agreement is governed by the laws of the jurisdiction in which the software provider operates, without regard to conflict of law provisions."
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle("User Agreement")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func agreementSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
