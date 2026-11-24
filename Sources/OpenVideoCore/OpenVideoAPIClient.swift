import Foundation

public enum OpenVideoEndpoints {
    public static let catalogHost = "open.video"

    public static func sdkConfigURL(hostname: String, platform: String = "ios") -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = catalogHost
        components.path = "/api/sdk/config"
        components.queryItems = [
            URLQueryItem(name: "domain", value: hostname),
            URLQueryItem(name: "platform", value: platform),
        ]
        return components.url!
    }
}

public final class OpenVideoAPIClient: @unchecked Sendable {
    public static let clientHeader = "OpenVideoSDK/0.1.2"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func getJSON(url: URL) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.setValue(Self.clientHeader, forHTTPHeaderField: "X-OV-Client")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenVideoCoreError.malformedJSON
        }
        return (data, http)
    }

    public func fetchSDKConfig(hostname: String) async throws -> SDKConfig {
        let url = OpenVideoEndpoints.sdkConfigURL(hostname: hostname)
        let (data, http) = try await getJSON(url: url)
        guard (200 ..< 300).contains(http.statusCode) else {
            throw OpenVideoCoreError.httpStatus(http.statusCode)
        }
        return try JSONDecoder().decode(SDKConfig.self, from: data)
    }

    public func fetchPlay(videoId: String, preview: Bool) async throws -> PlayStream {
        let url = PlayRequest.url(videoId: videoId, preview: preview)
        let (data, http) = try await getJSON(url: url)
        guard (200 ..< 300).contains(http.statusCode) else {
            throw OpenVideoCoreError.httpStatus(http.statusCode)
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenVideoCoreError.malformedJSON
        }
        return try PlayStream.parse(json: obj)
    }

    public func fetchPlaylistVideoIds(playlistId: String) async throws -> [String] {
        let url = CatalogIDs.playlistURL(idOrSlug: playlistId)
        let (data, http) = try await getJSON(url: url)
        guard (200 ..< 300).contains(http.statusCode) else {
            throw OpenVideoCoreError.httpStatus(http.statusCode)
        }
        let obj = try JSONSerialization.jsonObject(with: data)
        return try CatalogIDs.videoIds(from: obj)
    }

    public func getPixel(url: URL) async {
        var request = URLRequest(url: url)
        request.setValue(Self.clientHeader, forHTTPHeaderField: "X-OV-Client")
        request.setValue("\(Self.clientHeader) (ios)", forHTTPHeaderField: "User-Agent")
        _ = try? await session.data(for: request)
    }
}
