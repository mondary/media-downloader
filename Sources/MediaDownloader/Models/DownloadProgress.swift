import Foundation

struct DownloadProgress: Equatable, Sendable {
    let sourceURL: String
    let title: String
    let thumbnailURL: URL?
    let playlistIndex: Int?
    let playlistCount: Int?
    let fractionCompleted: Double?

    var playlistPosition: String? {
        guard let playlistIndex, let playlistCount, playlistCount > 1 else {
            return nil
        }

        return "Video \(playlistIndex) of \(playlistCount)"
    }

    var progressLabel: String {
        guard let fractionCompleted else {
            return "Preparing download"
        }

        return "\(Int((fractionCompleted * 100).rounded()))%"
    }
}
