# Releasing OpenVideo for iOS

## Cut a release

1. Set the same version `X.Y.Z` in all of:
   - `Sources/OpenVideo/OpenVideo.swift` (`version`)
   - `Sources/OpenVideoCore/OpenVideoAPIClient.swift` (`clientHeader`)
   - `Examples/OpenVideoDemo/OpenVideoDemo/Info.plist` (`CFBundleShortVersionString`)
   - `Examples/OpenVideoDemo/OpenVideoDemo.xcodeproj/project.pbxproj` (`MARKETING_VERSION` and the exact OpenVideo package `version`)
2. Push the release commit to `master` and wait for CI. CI runs the package tests and builds the demo when its pinned tag exists.
3. Run `git tag -a vX.Y.Z -m "OpenVideo X.Y.Z" && git push origin vX.Y.Z`.
4. The Release workflow checks the SDK version and client header against the tag and creates the GitHub Release. Prerelease tags use a hyphen, for example `vX.Y.Z-rc.1`.
5. Rerun CI after the tag is available to build the demo against the release.

To rerun the Release workflow for an existing tag, use Actions → Release → Run workflow and enter the tag.

## Install in an app

Use Swift Package Manager with `https://github.com/ezoic/open-video-swift-sdk`, OpenVideo 0.2.0 or later, and iOS 15 or later. Add the `OpenVideo` product.

Before calling `OpenVideo.configure(domain:)`, an app that uses Ezoic Ads elsewhere or manages its own consent must initialize `EzoicAds` with the same domain. Other apps call `EzoicAds.shared.presentConsentIfRequired(from:)` from the first screen after configuration succeeds. See [Configure and play](README.md#configure-and-play) for the app setup and the consent flow.

## Privacy

The Swift package includes `Sources/OpenVideo/PrivacyInfo.xcprivacy`. Update it if the SDK changes the kinds of data it collects.

## Run the demo

- Simulator. Build using the command in [Demo](README.md#demo) or run the scheme from Xcode. Respond to any tracking or consent prompts.
- Device. Choose your development team in the app's signing settings, select a registered device, and run from Xcode. Use a bundle identifier and signing settings for your team.
