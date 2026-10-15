# Open Video iOS SDK

Publisher native player (`OpenVideo` / `OpenVideoCore`). **Not** the Open Video store app (`open-video-mobile`). **Not** the Ezoic Ads SDK (`ezoic-swift-sdk`) — this package **depends on** Ads `EzoicInstreamAd` and hosts Google IMA.

**Compile / Xcode / device Acc: Mac only.** This tree can be edited and committed on Linux.

## Setup

1. Private GitHub: `ezoic/open-video-swift-sdk` and `ezoic/ezoic-swift-sdk`.
2. Xcode: File → Add Package Dependencies → this repo (or a local path).
3. Host `Info.plist`: `NSUserTrackingUsageDescription` (Ads ATT) and `GADApplicationIdentifier` (required by Google Ads — missing key crashes at launch). App Transport as usual. Demo uses Google’s sample App ID; a publisher app must use its own GAM iOS App ID.
4. Before any player view:

```swift
import OpenVideo

try await OpenVideo.configure(domain: "hackasaur.us")
let player = OpenVideoPlayerView(videoId: "<videoContentId>")
// or OpenVideoPlayerView(playlistId: "<playlist id or slug>")
```

`configure` calls live `GET https://open.video/api/sdk/config?domain=` with a **hostname** only (`hackasaur.us`). Domain id / slug in the query are rejected by the server (400).

## Acc fixture

| | |
|--|--|
| Hostname | `hackasaur.us` |
| `domain_id` | 193293 (from config JSON — do not hardcode in app logic) |
| Channel | 3224 / `hackasaur-us` |

Do **not** stamp `domain_id` 708527 or `is_humix_app=1` (those are the OV store app).

## Behavior

- Stream: `GET https://videosvc.ezoic.com/play?videoID=&manifest=hls`. Premium v1 adds `mode=preview` and stops at 30s with a watch-on-site URL (`https://{hostname}/openvideo/?v=`). No entitlement on `/play`.
- Ads: `EzoicInstreamAd(adUnitId: 201)` → GAM VAST URL → IMA. Sol placement is **domain + bundle**, not this numeric id. No-fill / init miss → content plays.
- Pixels: GET `vid.gif?e=` + `grapefruit.gif` with publisher `domain_id`, `is_humix_app=0`, `insert_method=sdk_ios`.

## Mac verify (iPhone Simulator)

Swift Package Manager supports **iOS 14+** (same floor as the ads SDK); CocoaPods requires **iOS 15+**. Host `swift test` compiles `OpenVideoCore` as macOS and fails — do **not** add `.macOS` to `Package.swift`. Same test pattern as Ads (`ezoic-swift-sdk` GitHub Actions `test.yml`).

Google’s in-stream player package **3.28+** is iOS 15-only. This repo pins **3.23 ..< 3.28** so iOS 14 apps still compile.

Private Ads dep is HTTPS; this machine’s `gh` is SSH. Rewrite for SPM fetch:

```bash
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=url.ssh://git@github.com/.insteadOf \
GIT_CONFIG_VALUE_0=https://github.com/ \
xcodebuild test \
  -scheme OpenVideo-Package \
  -scmProvider system \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:OpenVideoCoreTests \
  -skipPackagePluginValidation \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Pick any available iPhone Simulator if `iPhone 17` is missing (`xcrun simctl list devices available`). Then in Xcode: embed `OpenVideoPlayerView`, play hackasaur video `DdXGnZvrBZu` + playlist, confirm preroll or clean no-fill, pixels `domain_id=193293`.

## Demo (`Examples/OpenVideoDemo`)

Official sample app (ND3). Installs the released package (exact version pinned in the project), so it is the first app to test each release; code under change is tested by the package tests. Acc = iPhone Simulator — not host `swift test`, not `PlayerLiveTests`.

```bash
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=url.ssh://git@github.com/.insteadOf \
GIT_CONFIG_VALUE_0=https://github.com/ \
xcodebuild -project Examples/OpenVideoDemo/OpenVideoDemo.xcodeproj \
  -scheme OpenVideoDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -scmProvider system -skipPackagePluginValidation \
  COMPILER_INDEX_STORE_ENABLE=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Then run the app on that Simulator: configure `hackasaur.us`, **Play video** `DdXGnZvrBZu`, **Play playlist** `5tXyasXrAIp`.

## License

Proprietary. See `LICENSE`.
