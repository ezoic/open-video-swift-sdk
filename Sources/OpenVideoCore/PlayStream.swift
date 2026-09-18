import Foundation

public struct PlayStream: Equatable, Sendable {
    public let videoId: String
    public let src: URL
    public let durationMs: Int
    public let poster: URL?

    public init(videoId: String, src: URL, durationMs: Int, poster: URL?) {
        self.videoId = videoId
        self.src = src
        self.durationMs = durationMs
        self.poster = poster
    }

    public static func parse(json: [String: Any]) throws -> PlayStream {
        let videoId = (json["video"] as? String) ?? (json["videoID"] as? String) ?? ""
        guard !videoId.isEmpty else { throw OpenVideoCoreError.missingVideoId }
        guard let srcRaw = json["src"] as? String, let src = URL(string: srcRaw) else {
            throw OpenVideoCoreError.malformedJSON
        }
        let durationMs: Int
        if let n = json["duration"] as? Int {
            durationMs = n
        } else if let n = json["duration"] as? Double {
            durationMs = Int(n)
        } else {
            durationMs = 0
        }
        let poster: URL?
        if let p = json["poster"] as? String, !p.isEmpty {
            poster = URL(string: p)
        } else {
            poster = nil
        }
        return PlayStream(videoId: videoId, src: src, durationMs: durationMs, poster: poster)
    }
}

public enum PlayRequest {
    public static let host = "videosvc.ezoic.com"

    public static func url(videoId: String, preview: Bool) -> URL {
        var items = [
            URLQueryItem(name: "videoID", value: videoId),
            URLQueryItem(name: "manifest", value: "hls"),
        ]
        if preview {
            items.append(URLQueryItem(name: "mode", value: "preview"))
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/play"
        components.queryItems = items
        return components.url!
    }
}
