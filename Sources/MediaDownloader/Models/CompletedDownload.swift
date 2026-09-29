import Foundation

struct CompletedDownload: Sendable {
    let fileURL: URL
    let title: String
    let sourceURL: String
}
