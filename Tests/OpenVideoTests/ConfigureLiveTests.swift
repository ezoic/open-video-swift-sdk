import OpenVideo
import XCTest

/// D2 Acc: live `GET /api/sdk/config?domain=hackasaur.us` on iPhone Simulator.
/// Not ND3 Examples/. Needs network.
final class ConfigureLiveTests: XCTestCase {
    @MainActor
    func testHackasaurConfig() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["SKIP_LIVE_NETWORK"] == "1",
            "opt-out live sdk/config Acc"
        )
        try await OpenVideo.configure(domain: "hackasaur.us")
        let state = try OpenVideo.requireState()
        XCTAssertEqual(state.hostname, "hackasaur.us")
        XCTAssertEqual(state.config.domainId, 193293)
        XCTAssertEqual(state.config.channel.id, 3224)
        XCTAssertEqual(state.config.iosInsertMethod, "sdk_ios")
        XCTAssertTrue(state.config.isPreviewCTA)
    }
}
