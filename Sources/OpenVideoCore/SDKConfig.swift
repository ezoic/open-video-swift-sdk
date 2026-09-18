import Foundation

/// `GET /api/sdk/config` JSON (`video-product` `sdkConfigResponse`).
public struct SDKConfig: Codable, Equatable, Sendable {
    public let domainId: Int
    public let channel: Channel
    public let ads: Ads
    public let pixels: Pixels
    public let premium: Premium

    public struct Channel: Codable, Equatable, Sendable {
        public let id: Int
        public let slug: String
    }

    public struct Ads: Codable, Equatable, Sendable {
        public let enabled: Bool
        public let adBreakGapSeconds: Int
    }

    public struct Pixels: Codable, Equatable, Sendable {
        public let insertMethod: String?

        enum CodingKeys: String, CodingKey {
            case insertMethod = "insert_method"
        }
    }

    public struct Premium: Codable, Equatable, Sendable {
        public let mode: String
    }

    enum CodingKeys: String, CodingKey {
        case domainId = "domain_id"
        case channel
        case ads
        case pixels
        case premium
    }

    public var isPreviewCTA: Bool {
        premium.mode == "preview_cta"
    }

    /// Publisher pixel insert_method. Config omits it when `platform` was not sent.
    public var iosInsertMethod: String {
        pixels.insertMethod ?? "sdk_ios"
    }
}
