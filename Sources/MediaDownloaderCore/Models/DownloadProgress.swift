import Foundation

public struct DownloadProgress: Equatable, Sendable {
    public let sourceURL: String
    public let title: String
    public let thumbnailURL: URL?
    public let playlistIndex: Int?
    public let playlistCount: Int?
    public let fractionCompleted: Double?

    public init(
        sourceURL: String,
        title: String,
        thumbnailURL: URL?,
        playlistIndex: Int?,
        playlistCount: Int?,
        fractionCompleted: Double?
    ) {
        self.sourceURL = sourceURL
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.playlistIndex = playlistIndex
        self.playlistCount = playlistCount
        self.fractionCompleted = fractionCompleted
    }

    public var playlistPosition: String? {
        guard let playlistIndex, let playlistCount, playlistCount > 1 else {
            return nil
        }

        return "Video \(playlistIndex) of \(playlistCount)"
    }

    public var progressLabel: String {
        guard let fractionCompleted else {
            return "Preparing download"
        }

        return "\(Int((fractionCompleted * 100).rounded()))%"
    }
}
