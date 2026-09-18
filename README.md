# Open Video iOS SDK

Publisher native player (`OpenVideo` / `OpenVideoCore`). **Not** the Open Video store app (`open-video-mobile`). **Not** the Ezoic Ads SDK (`ezoic-swift-sdk`) — this package **depends on** Ads `EzoicInstreamAd` and hosts Google IMA.

**Compile / Xcode / device Acc: Mac only.** This tree can be edited and committed on Linux.

## Setup

1. Private GitHub: `ezoic/open-video-swift-sdk` and `ezoic/ezoic-swift-sdk`.
2. Xcode: File → Add Package Dependencies → this repo (or a local path).
3. Host `Info.plist`: `NSUserTrackingUsageDescription` (Ads ATT). App Transport as usual.
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

## Mac verify (not done on WSL)

```bash
swift test --filter OpenVideoCoreTests
# then Xcode: embed OpenVideoPlayerView, play hackasaur video + playlist, confirm preroll or clean no-fill
```

Demo app under `Examples/` is a later slice (ND3), not this package’s first commit.

## License

Proprietary. See `LICENSE`.
