import Foundation
#if canImport(OpenVideoCore)
import OpenVideoCore
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(EzoicAdsSDKBinary)
import EzoicAdsSDKBinary
#else
import EzoicAdsSDK
#endif

/// Publisher Open Video iOS SDK. Call `configure(domain:)` before creating player views.
public enum OpenVideo {
    public static let version = "0.1.2"

    /// Placeholder instream unit (same numeric id the Flutter store-app spike used).
    /// Sol does not use `ad_unit_id` to pick GAM placement; identity is domain + bundle.
    public static let defaultInstreamAdUnitId = 201

    private static let lock = NSLock()
    private static var _state: RuntimeState?

    public struct RuntimeState: Sendable {
        public let hostname: String
        public let config: SDKConfig
        public let visitUUID: String
    }

    public static var state: RuntimeState? {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    public static func requireState() throws -> RuntimeState {
        guard let state else { throw OpenVideoCoreError.notConfigured }
        return state
    }

    /// Loads `GET /api/sdk/config?domain=` (hostname only) and initializes Ezoic Ads.
    @MainActor
    public static func configure(domain: String) async throws {
        let hostname = try DomainNormalizer.hostname(from: domain).get()
        let client = OpenVideoAPIClient()
        let config = try await client.fetchSDKConfig(hostname: hostname)
        try PixelContract.assertPublisherDomainId(config.domainId)
        lock.lock()
        _state = RuntimeState(
            hostname: hostname,
            config: config,
            visitUUID: UUID().uuidString
        )
        lock.unlock()
        // Ads init failure must not block video. Player then skips/no-fills preroll.
        do {
            try await EzoicAds.shared.initialize(with: EzoicConfiguration(domain: hostname))
        } catch {
            print("OpenVideo: EzoicAds initialize failed (playback continues): \(error)")
        }
    }

    public static func resetForTests() {
        lock.lock()
        _state = nil
        lock.unlock()
    }
}

public protocol OpenVideoPlayerDelegate: AnyObject {
    func openVideoPlayerDidStartContent(_ player: OpenVideoPlayerView)
    func openVideoPlayer(_ player: OpenVideoPlayerView, didFail error: Error)
    func openVideoPlayerDidHitPreviewLimit(_ player: OpenVideoPlayerView, watchURL: URL)
}
