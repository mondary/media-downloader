import Foundation

public struct CompletedDownload: Sendable {
    public let fileURL: URL
    public let title: String
    public let sourceURL: String

    public init(fileURL: URL, title: String, sourceURL: String) {
        self.fileURL = fileURL
        self.title = title
        self.sourceURL = sourceURL
    }
}
