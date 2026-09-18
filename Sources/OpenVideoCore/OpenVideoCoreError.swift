import Foundation

public enum OpenVideoCoreError: Error, Equatable, Sendable {
    case invalidDomain(String)
    case notConfigured
    case httpStatus(Int)
    case malformedJSON
    case emptyPlaylist
    case missingVideoId
}
