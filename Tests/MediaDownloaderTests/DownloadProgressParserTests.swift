import XCTest
@testable import MediaDownloader

final class DownloadProgressParserTests: XCTestCase {
    func testParsesPlaylistProgressAcrossOutputChunks() async {
        let parser = DownloadProgressParser(sourceURL: "https://youtube.com/playlist?list=example")
        let separator = "\u{1F}"

        let first = await parser.consumeStandardError("progress:42.7%\(separator)2\(separator)12\(separator)Current video")
        let second = await parser.consumeStandardError("\(separator)https://youtube.com/watch?v=example\(separator)https://image.example/thumbnail.jpg\n")

        XCTAssertTrue(first.isEmpty)
        XCTAssertEqual(second.count, 1)
        XCTAssertEqual(second.first?.title, "Current video")
        XCTAssertEqual(second.first?.playlistIndex, 2)
        XCTAssertEqual(second.first?.playlistCount, 12)
        XCTAssertEqual(second.first?.fractionCompleted ?? 0, 0.427, accuracy: 0.000_001)
        XCTAssertEqual(second.first?.thumbnailURL, URL(string: "https://image.example/thumbnail.jpg"))
    }

    func testParsesMetadataBeforeTheDownloadStarts() async {
        let parser = DownloadProgressParser(sourceURL: "https://youtube.com/playlist?list=example")
        let separator = "\u{1F}"
        let updates = await parser.consumeStandardOutput("metadata:1\(separator)28\(separator)First video\(separator)https://youtube.com/watch?v=first\(separator)https://image.example/first.jpg\n")

        XCTAssertEqual(updates.count, 1)
        XCTAssertEqual(updates.first?.title, "First video")
        XCTAssertEqual(updates.first?.playlistPosition, "Video 1 of 28")
        XCTAssertNil(updates.first?.fractionCompleted)
    }
}
