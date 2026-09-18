import Foundation

/// Publisher SDK pixel stamps. Never copy `open-video-mobile` (708527 / is_humix_app=1).
public enum PixelContract {
    public static let forbiddenOwnAppDomainId = 708527
    public static let isHumixApp = 0
    public static let insertMethodIOS = "sdk_ios"
    public static let vidHost = "g.ezoic.net"
    public static let vidPath = "/detroitchicago/vid.gif"
    public static let grapefruitPath = "/detroitchicago/grapefruit.gif"

    public enum ContentEvent: String, Sendable {
        case videoStart = "video_start"
        case viewedStart = "viewed_start"
        case viewedFirstQuartile = "viewed_first_quartile"
        case viewedMiddle = "viewed_middle"
        case viewedThirdQuartile = "viewed_third_quartile"
        case viewedEnd = "viewed_end"
        case completed = "completed"
        case errored = "errored"
    }

    public enum AdEvent: String, Sendable {
        case adStart = "ad_start"
        case viewedFirstQuartile = "viewed_first_quartile"
        case viewedMidpoint = "viewed_midpoint"
        case viewedThirdQuartile = "viewed_third_quartile"
        case completed = "completed"
        case errored = "errored"
    }

    public struct Session: Equatable, Sendable {
        public let domainId: Int
        public let insertMethod: String
        public let visitUUID: String
        public let pageviewId: String
        public let videoImpressionId: String
        public let contentId: String
        public let mediaSrc: String
        public let videoTitle: String
        public let videoLengthSeconds: Int
        public let pageURL: String
        public let width: Int
        public let height: Int
        public let isPlaylistItem: Bool
        public let isAutoplay: Bool

        public init(
            domainId: Int,
            insertMethod: String,
            visitUUID: String,
            pageviewId: String,
            videoImpressionId: String,
            contentId: String,
            mediaSrc: String,
            videoTitle: String,
            videoLengthSeconds: Int,
            pageURL: String,
            width: Int,
            height: Int,
            isPlaylistItem: Bool,
            isAutoplay: Bool
        ) {
            self.domainId = domainId
            self.insertMethod = insertMethod
            self.visitUUID = visitUUID
            self.pageviewId = pageviewId
            self.videoImpressionId = videoImpressionId
            self.contentId = contentId
            self.mediaSrc = mediaSrc
            self.videoTitle = videoTitle
            self.videoLengthSeconds = videoLengthSeconds
            self.pageURL = pageURL
            self.width = width
            self.height = height
            self.isPlaylistItem = isPlaylistItem
            self.isAutoplay = isAutoplay
        }
    }

    public static func assertPublisherDomainId(_ domainId: Int) throws {
        if domainId == forbiddenOwnAppDomainId {
            throw OpenVideoCoreError.invalidDomain("refusing OV store-app domain_id \(forbiddenOwnAppDomainId)")
        }
        if domainId <= 0 {
            throw OpenVideoCoreError.invalidDomain("domain_id must be > 0")
        }
    }

    public static func vidQuery(session: Session) throws -> [String: Any] {
        try assertPublisherDomainId(session.domainId)
        return [
            "domain_id": session.domainId,
            "url": session.pageURL,
            "pageview_id": session.pageviewId,
            "visit_uuid": session.visitUUID,
            "template_id": 0,
            "video_impression_id": session.videoImpressionId,
            "media_src": session.mediaSrc,
            "player_type": "ios",
            "video_title": session.videoTitle,
            "is_autoplay": session.isAutoplay ? 1 : 0,
            "is_floating": 0,
            "is_playlist_item": session.isPlaylistItem ? 1 : 0,
            "vab_test_id": "",
            "video_length": session.videoLengthSeconds,
            "content_id": session.contentId,
            "width": session.width,
            "height": session.height,
            "pos_x": 0,
            "pos_y": 0,
            "is_blocker_on": 0,
            "is_humix_app": isHumixApp,
            "insert_method": session.insertMethod,
            "is_vertical": 0,
        ]
    }

    public static func vidURL(session: Session) throws -> URL {
        let payload = try vidQuery(session: session)
        let data = try JSONSerialization.data(withJSONObject: [payload], options: [])
        let e = String(data: data, encoding: .utf8)!
        var components = URLComponents()
        components.scheme = "https"
        components.host = vidHost
        components.path = vidPath
        components.queryItems = [URLQueryItem(name: "e", value: e)]
        return components.url!
    }

    public static func grapefruitURL(
        domainId: Int,
        impressionId: String,
        eventName: String,
        now: Date = Date()
    ) throws -> URL {
        try assertPublisherDomainId(domainId)
        let epoch = Int(now.timeIntervalSince1970)
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let val = formatter.string(from: now)
        let body: [String: Any] = [
            "type": "video",
            "domain_id": domainId,
            "t_epoch": epoch,
            "video_impression_id": impressionId,
            "data": [["name": eventName, "val": val]],
        ]
        let json = try JSONSerialization.data(withJSONObject: body, options: [])
        let v = json.base64EncodedString()
        var components = URLComponents()
        components.scheme = "https"
        components.host = vidHost
        components.path = grapefruitPath
        components.queryItems = [
            URLQueryItem(name: "orig", value: "0"),
            URLQueryItem(name: "v", value: v),
        ]
        return components.url!
    }

    public static func watchOnSiteURL(hostname: String, videoId: String) -> URL {
        URL(string: "https://\(hostname)/openvideo/?v=\(videoId)")!
    }
}
