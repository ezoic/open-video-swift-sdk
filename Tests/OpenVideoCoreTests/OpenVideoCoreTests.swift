import Foundation
@testable import OpenVideoCore
import XCTest

final class DomainNormalizerTests: XCTestCase {
    func testWWWAndScheme() {
        let result = DomainNormalizer.hostname(from: "https://www.hackasaur.us/")
        XCTAssertEqual(try result.get(), "hackasaur.us")
    }

    func testRejectsDomainId() {
        switch DomainNormalizer.hostname(from: "193293") {
        case .failure: break
        case .success: XCTFail("id must not parse as hostname")
        }
    }

    func testRejectsSlug() {
        switch DomainNormalizer.hostname(from: "hackasaur-us") {
        case .failure: break
        case .success: XCTFail("slug must not parse as hostname")
        }
    }
}

final class SDKConfigTests: XCTestCase {
    func testDecodeAccShape() throws {
        let json = """
        {"domain_id":193293,"channel":{"id":3224,"slug":"hackasaur-us"},"ads":{"enabled":true,"adBreakGapSeconds":420},"pixels":{"insert_method":"sdk_ios"},"premium":{"mode":"preview_cta"}}
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(SDKConfig.self, from: json)
        XCTAssertEqual(config.domainId, 193293)
        XCTAssertEqual(config.channel.id, 3224)
        XCTAssertTrue(config.isPreviewCTA)
        XCTAssertEqual(config.iosInsertMethod, "sdk_ios")
    }
}

final class PlayRequestTests: XCTestCase {
    func testPreviewQuery() {
        let url = PlayRequest.url(videoId: "abc", preview: true)
        XCTAssertTrue(url.absoluteString.contains("mode=preview"))
        XCTAssertTrue(url.absoluteString.contains("manifest=hls"))
        XCTAssertFalse(url.absoluteString.contains("entitlement"))
    }

    func testFullPlayOmitsMode() {
        let url = PlayRequest.url(videoId: "abc", preview: false)
        XCTAssertFalse(url.absoluteString.contains("mode="))
    }
}

final class PixelContractTests: XCTestCase {
    func testRefusesOwnAppDomain() {
        XCTAssertThrowsError(try PixelContract.assertPublisherDomainId(708527))
    }

    func testVidJSONStamps() throws {
        let session = PixelContract.Session(
            domainId: 193293,
            insertMethod: "sdk_ios",
            visitUUID: "v",
            pageviewId: "p",
            videoImpressionId: "i",
            contentId: "vid",
            mediaSrc: "https://example/hls",
            videoTitle: "t",
            videoLengthSeconds: 10,
            pageURL: "https://hackasaur.us/openvideo/?v=vid",
            width: 320,
            height: 180,
            isPlaylistItem: false,
            isAutoplay: true
        )
        let payload = try PixelContract.vidQuery(session: session)
        XCTAssertEqual(payload["domain_id"] as? Int, 193293)
        XCTAssertEqual(payload["is_humix_app"] as? Int, 0)
        XCTAssertEqual(payload["insert_method"] as? String, "sdk_ios")
        XCTAssertNotEqual(payload["domain_id"] as? Int, 708527)
        let url = try PixelContract.vidURL(session: session)
        XCTAssertFalse(url.absoluteString.contains("708527"))
    }
}

final class CatalogIDsTests: XCTestCase {
    func testArrayOfVideoContentId() throws {
        let ids = try CatalogIDs.videoIds(from: [["videoContentId": "aaa"], ["id": "bbb"]])
        XCTAssertEqual(ids, ["aaa", "bbb"])
    }
}
