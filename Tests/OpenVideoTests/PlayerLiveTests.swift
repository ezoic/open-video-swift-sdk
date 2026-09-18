import OpenVideo
import UIKit
import XCTest

/// D3–D6 Acc: host-embed `OpenVideoPlayerView` on iPhone Simulator.
/// Not ND3 `Examples/`. Needs network. `SKIP_LIVE_NETWORK=1` skips.
final class PlayerLiveTests: XCTestCase {
    private var holdWindow: UIWindow?
    private var holdPlayer: OpenVideoPlayerView?

    override func setUp() {
        super.setUp()
        OpenVideo.resetForTests()
        PixelProbe.reset()
        URLProtocol.registerClass(PixelProbeProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(PixelProbeProtocol.self)
        holdPlayer = nil
        holdWindow = nil
        OpenVideo.resetForTests()
        super.tearDown()
    }

    @MainActor
    func testHackasaurVideoPlayAdsPixelsPreview() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["SKIP_LIVE_NETWORK"] == "1",
            "opt-out live play Acc"
        )
        try await OpenVideo.configure(domain: "hackasaur.us")
        XCTAssertEqual(try OpenVideo.requireState().config.domainId, 193293)

        let probe = PlayerProbe()
        embed(OpenVideoPlayerView(videoId: "DdXGnZvrBZu"), probe: probe)

        await fulfillment(of: [probe.start], timeout: 90)
        if let err = probe.error {
            XCTFail("player failed: \(err)")
            return
        }

        await fulfillment(of: [probe.preview], timeout: 40)
        XCTAssertEqual(probe.watchURL?.host, "hackasaur.us")
        let watch = probe.watchURL?.absoluteString ?? ""
        XCTAssertTrue(watch.contains("/openvideo/?v="), watch)
        XCTAssertTrue(watch.contains("DdXGnZvrBZu"), watch)

        let hits = PixelProbe.snapshot()
        XCTAssertFalse(hits.isEmpty, "expected vid.gif fire")
        for hit in hits {
            XCTAssertEqual(intValue(hit["domain_id"]), 193293)
            XCTAssertEqual(intValue(hit["is_humix_app"]), 0)
            XCTAssertEqual(hit["insert_method"] as? String, "sdk_ios")
            XCTAssertNotEqual(intValue(hit["domain_id"]), 708527)
        }
    }

    @MainActor
    func testHackasaurPlaylistStarts() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["SKIP_LIVE_NETWORK"] == "1",
            "opt-out live play Acc"
        )
        try await OpenVideo.configure(domain: "hackasaur.us")
        let probe = PlayerProbe()
        embed(OpenVideoPlayerView(playlistId: "5tXyasXrAIp"), probe: probe)
        await fulfillment(of: [probe.start], timeout: 90)
        if let err = probe.error {
            XCTFail("playlist failed: \(err)")
            return
        }
    }

    @MainActor
    private func embed(_ player: OpenVideoPlayerView, probe: PlayerProbe) {
        player.delegate = probe
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let vc = UIViewController()
        player.frame = CGRect(x: 0, y: 0, width: 390, height: 220)
        player.autoresizingMask = [.flexibleWidth]
        vc.view.addSubview(player)
        window.rootViewController = vc
        window.makeKeyAndVisible()
        holdWindow = window
        holdPlayer = player
        player.layoutIfNeeded()
    }

    private func intValue(_ raw: Any?) -> Int? {
        if let i = raw as? Int { return i }
        return (raw as? NSNumber)?.intValue
    }
}

private final class PlayerProbe: NSObject, OpenVideoPlayerDelegate {
    let start = XCTestExpectation(description: "content-start")
    let preview = XCTestExpectation(description: "preview-limit")
    var error: Error?
    var watchURL: URL?

    func openVideoPlayerDidStartContent(_ player: OpenVideoPlayerView) {
        start.fulfill()
    }

    func openVideoPlayer(_ player: OpenVideoPlayerView, didFail error: Error) {
        self.error = error
        start.fulfill()
    }

    func openVideoPlayerDidHitPreviewLimit(_ player: OpenVideoPlayerView, watchURL: URL) {
        self.watchURL = watchURL
        preview.fulfill()
    }
}

private enum PixelProbe {
    static var vidPayloads: [[String: Any]] = []
    static let lock = NSLock()

    static func reset() {
        lock.lock()
        vidPayloads = []
        lock.unlock()
    }

    static func snapshot() -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return vidPayloads
    }

    static func record(url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        guard
            let e = items?.first(where: { $0.name == "e" })?.value,
            let data = e.data(using: .utf8),
            let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
            let first = arr.first
        else {
            return
        }
        lock.lock()
        vidPayloads.append(first)
        lock.unlock()
    }
}

/// Intercepts `vid.gif` once per request in `startLoading` (not `canInit`).
private final class PixelProbeProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.host == "g.ezoic.net" && url.path.contains("vid.gif")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let url = request.url {
            PixelProbe.record(url: url)
        }
        let url = request.url ?? URL(string: "https://g.ezoic.net/detroitchicago/vid.gif")!
        let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
