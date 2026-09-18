import Foundation

/// Client-side hostname normalize matching `video-product` `parseSDKDomainQuery`
/// (lowercase, strip scheme/path/port, strip `www.`). Server still re-parses.
public enum DomainNormalizer {
    public static let maxLength = 253

    public static func hostname(from raw: String) -> Result<String, OpenVideoCoreError> {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty {
            return .failure(.invalidDomain("domain query parameter is required"))
        }
        if value.contains("://") {
            guard let url = URL(string: value), let host = url.host, !host.isEmpty else {
                return .failure(.invalidDomain("domain must be a hostname"))
            }
            value = host
        } else {
            if let slash = value.firstIndex(of: "/") {
                value = String(value[..<slash])
            }
            if value.contains(":") {
                if let host = URL(string: "https://\(value)")?.host {
                    value = host
                }
            }
        }
        while value.hasPrefix(".") || value.hasSuffix(".") {
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
        if value.hasPrefix("www.") {
            value.removeFirst(4)
        }
        if value.isEmpty || value.count > maxLength {
            return .failure(.invalidDomain("domain must be a hostname"))
        }
        if isAllDigits(value) || !value.contains(".") || !isHostCharset(value) {
            return .failure(.invalidDomain("domain must be a hostname"))
        }
        return .success(value)
    }

    private static func isAllDigits(_ s: String) -> Bool {
        !s.isEmpty && s.allSatisfy(\.isNumber)
    }

    private static func isHostCharset(_ s: String) -> Bool {
        s.allSatisfy { ch in
            ch.isASCII && (ch.isLetter || ch.isNumber || ch == "." || ch == "-")
        }
    }
}
