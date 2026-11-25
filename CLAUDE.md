# Open Video iOS SDK

- Install through Swift Package Manager from `https://github.com/ezoic/open-video-swift-sdk`, version 0.2.0 or later. The `OpenVideo` product requires iOS 15 or later.
- Apps using Ezoic Ads elsewhere or managing their own consent initialize `EzoicAds` before `OpenVideo.configure(domain:)` with the same domain. Other apps call `EzoicAds.shared.presentConsentIfRequired(from:)` from the first screen after configuration succeeds. See [Configure and play](README.md#configure-and-play).
- Run tests with `xcodebuild test -scheme OpenVideo-Package` on an iPhone Simulator. See [README.md](README.md#run-tests-on-an-iphone-simulator) for the full command.
- `Sources/OpenVideoCore` handles configuration, playlist and stream URLs, and analytics events. `Sources/OpenVideo` provides the player, Ads integration, and privacy manifest.
- See [RELEASING.md](RELEASING.md) for version fields and demo verification.
