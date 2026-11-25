# Open Video iOS SDK

Add an Open Video player to your iOS app. The SDK supports individual videos, playlists, and previews of premium videos.

## Install

Requires iOS 15 or later. In Xcode, choose File → Add Package Dependencies, enter `https://github.com/ezoic/open-video-swift-sdk`, select version 0.2.0 or later, and add the `OpenVideo` product to your app target.

To call the Ads APIs below, also add the `EzoicAdsSDK` product from `https://github.com/ezoic/ezoic-swift-sdk-dist`. OpenVideo 0.2.0 requires Ads 1.26.x, so use a compatible Ads version in your app.

Set `GADApplicationIdentifier` in your app's `Info.plist` to your own Google Ad Manager iOS app ID. Add an app-appropriate `NSUserTrackingUsageDescription` for the tracking permission prompt.

## Configure and play

Pass your publisher hostname to `OpenVideo.configure(domain:)` and await it before adding an `OpenVideoPlayerView` to the view hierarchy.

- If your app uses Ezoic Ads elsewhere or handles consent with its own tool, initialize `EzoicAds` before calling `OpenVideo.configure`. Use the same publisher hostname for both. Your app's Ads configuration stays in effect. Set `cmpEnabled: false` in that configuration when your app manages consent.
- Otherwise, call `EzoicAds.shared.presentConsentIfRequired(from:)` from your first screen after `OpenVideo.configure` succeeds. Call it once the view controller is visible.

For an app using the built-in consent dialog, run the following from a visible view controller:

```swift
import EzoicAdsSDK
import OpenVideo
import UIKit

@MainActor
func makePlayer(from host: UIViewController) async throws -> OpenVideoPlayerView {
    try await OpenVideo.configure(domain: "example.com")
    _ = await EzoicAds.shared.presentConsentIfRequired(from: host)
    return OpenVideoPlayerView(videoId: "<videoContentId>")
    // For a playlist, use OpenVideoPlayerView(playlistId: "<playlist id or slug>").
}
```

The SDK plays content if a preroll is unavailable. For premium previews, the player reports the watch-on-site URL to its delegate at the preview limit.

## Run tests on an iPhone Simulator

```bash
xcodebuild test \
  -scheme OpenVideo-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:OpenVideoCoreTests \
  -skipPackagePluginValidation \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Choose an installed simulator from `xcrun simctl list devices available`. Use `-only-testing:OpenVideoTests` for the live configuration and playback tests, which require a network connection.

## Demo

The sample app in `Examples/OpenVideoDemo` uses an exact OpenVideo release. Build it once the version pinned in the project has been tagged.

```bash
xcodebuild build \
  -project Examples/OpenVideoDemo/OpenVideoDemo.xcodeproj \
  -scheme OpenVideoDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

Run the app in Xcode on your simulator. The demo configures with `hackasaur.us` and starts a video preview. Use **Play video** or **Play playlist** to try either player type. Respond to any system tracking or consent prompts.

## License

See [LICENSE](LICENSE).
