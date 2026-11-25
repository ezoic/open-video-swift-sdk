# Open Video iOS SDK

Use the `OpenVideo` Swift Package Manager product from `https://github.com/ezoic/open-video-swift-sdk`, version 0.2.0 or later, on iOS 15 or later.

An app using Ezoic Ads elsewhere or managing its own consent initializes `EzoicAds` before `OpenVideo.configure(domain:)` with the same domain. Other apps call `EzoicAds.shared.presentConsentIfRequired(from:)` from the first screen after configuration succeeds. See [Configure and play](README.md#configure-and-play).

See [CLAUDE.md](CLAUDE.md) for source layout and Simulator tests.
