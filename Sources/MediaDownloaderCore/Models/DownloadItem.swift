import Foundation

public struct DownloadItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let sourceURL: String
    public let title: String
    public let filePath: String
    public let thumbnailPath: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        sourceURL: String,
        title: String,
        filePath: String,
        thumbnailPath: String?,
        createdAt: Date
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.title = title
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.createdAt = createdAt
    }

    public var displayName: String {
        if !title.isEmpty {
            return title
        }

        return fileName
    }

    public var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    public var sourceName: String {
        guard let host = URLComponents(string: sourceURL)?.host else {
            return "Web"
        }

        let normalizedHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let source = normalizedHost.split(separator: ".").first.map(String.init) ?? normalizedHost

        switch source.lowercased() {
        case "instagram":
            return "Instagram"
        case "youtube", "youtu":
            return "YouTube"
        case "tiktok":
            return "TikTok"
        case "x", "twitter":
            return "X"
        case "vimeo":
            return "Vimeo"
        default:
            return source.prefix(1).uppercased() + source.dropFirst()
        }
    }
}
