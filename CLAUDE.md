# open-video-swift-sdk

Publisher Open Video **iOS player SDK** (`OpenVideo`). SPM. Depends on `ezoic-swift-sdk` (`EzoicInstreamAd` VAST → host IMA). **Never** `deploy-backend`. Not `open-video-mobile`.

## Commands

- `swift test --filter OpenVideoCoreTests` — Foundation tests (Mac; no Swift toolchain on WSL).
- Xcode: add the local package, call `OpenVideo.configure(domain:)`, embed `OpenVideoPlayerView`.

## Layout

- `Sources/OpenVideoCore` — hostname, sdk/config JSON, `/play` URL, playlist ids, pixel stamps.
- `Sources/OpenVideo` — `OpenVideo.configure`, `OpenVideoPlayerView`, IMA + Ads.
- `Tests/OpenVideoCoreTests` — no UIKit.

## Git

Fast Track (`git-rules.md`). Pre-commit `review_diff`. Direct `master`. Version `OpenVideo.version`.
