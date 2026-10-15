# Releasing OpenVideo (iOS)

Private repo. Installs need a GitHub account with read access to `ezoic/open-video-swift-sdk`.

## Cut a release

1. Set the same version `X.Y.Z` in all of:
   - `Sources/OpenVideo/OpenVideo.swift` (`version`)
   - `Sources/OpenVideoCore/OpenVideoAPIClient.swift` (`clientHeader`)
   - `OpenVideo.podspec` (`s.version` and `:tag => 'vX.Y.Z'`)
   - `Examples/OpenVideoDemo/OpenVideoDemo/Info.plist` (`CFBundleShortVersionString`)
   - `Examples/OpenVideoDemo/OpenVideoDemo.xcodeproj/project.pbxproj` (`MARKETING_VERSION`,
     and the OpenVideo package `version` — the demo is the first app to install each release)
2. Push to `master`; wait for the `CI` workflow to pass.
3. `git tag -a vX.Y.Z -m "OpenVideo X.Y.Z" && git push origin vX.Y.Z`.
4. The `Release` workflow checks every version string against the tag, runs
   `pod lib lint`, and creates the GitHub Release. A tag that does not match fails
   before anything is published. Prerelease tags use a hyphen: `vX.Y.Z-rc.1`.

Rerun an existing tag: Actions → Release → Run workflow → `tag`.

## Install in an app

Swift Package Manager: add `https://github.com/ezoic/open-video-swift-sdk.git`, exact
version `X.Y.Z`, product `OpenVideo`. The package also resolves the private
`ezoic/ezoic-swift-sdk`; a machine that clones over SSH needs:

```sh
git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"
```

CocoaPods (iOS 15+), inside the app target:

```ruby
use_frameworks! :linkage => :static
pod 'OpenVideo', :git => 'git@github.com:ezoic/open-video-swift-sdk.git', :tag => 'vX.Y.Z'
```

The app needs its own `GADApplicationIdentifier` in `Info.plist`, and should call
`OpenVideo.configure(domain:)` before a player view is shown.

## Privacy

`Sources/OpenVideo/PrivacyInfo.xcprivacy` ships with both install routes. It declares
product-interaction and usage analytics events, not linked to the user, no tracking.
Update it whenever `PixelContract.swift` starts sending a new kind of data.

## Run the demo

- Simulator: build with the command in `README.md` §Demo (it fetches the private
  packages over SSH with system git), then install the `.app` with `xcrun simctl install booted <path>`. Tap Allow on the tracking prompt.
- Device: needs a member of the Ezoic Apple developer team, the device registered on
  that team, and development signing for `com.ezoic.openvideo.demo`. Open the project
  in Xcode, pick the team, select the device, Run.

## CI secrets

- `ADS_SWIFT_DEPLOY_KEY`: private half of a read-only deploy key on
  `ezoic/ezoic-swift-sdk`. Without it the SPM job prints a notice and does nothing;
  the CocoaPods job still validates the package.
- The demo installs the released OpenVideo tag from this repo; the job's own token
  reads it, no extra secret. Until the pinned tag exists the demo build is skipped
  with a notice.
