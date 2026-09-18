import Foundation

public enum CatalogIDs {
    /// Playlist JSON is a top-level array (`HandleListPlaylistVideos` writes `videos` as JSON).
    public static func videoIds(from jsonObject: Any) throws -> [String] {
        let rows: [[String: Any]]
        if let array = jsonObject as? [[String: Any]] {
            rows = array
        } else if let dict = jsonObject as? [String: Any], let array = dict["videos"] as? [[String: Any]] {
            rows = array
        } else {
            throw OpenVideoCoreError.malformedJSON
        }
        let ids = rows.compactMap { row -> String? in
            if let id = row["videoContentId"] as? String, !id.isEmpty { return id }
            if let id = row["id"] as? String, !id.isEmpty { return id }
            if let id = row["VideoContentId"] as? String, !id.isEmpty { return id }
            return nil
        }
        if ids.isEmpty { throw OpenVideoCoreError.emptyPlaylist }
        return ids
    }

    public static func playlistURL(idOrSlug: String) -> URL {
        let isSlug = idOrSlug.hasPrefix("@") || idOrSlug.contains("-") && idOrSlug.first?.isLetter == true
        let path: String
        if idOrSlug.hasPrefix("@") {
            path = "/api/playlist/\(idOrSlug)/videos"
        } else if isSlug && idOrSlug.rangeOfCharacter(from: CharacterSet.letters) != nil
            && !idOrSlug.allSatisfy(\.isNumber)
        {
            path = "/api/playlist/@\(idOrSlug)/videos"
        } else {
            path = "/api/playlist/\(idOrSlug)/videos"
        }
        return URL(string: "https://open.video\(path)")!
    }
}
