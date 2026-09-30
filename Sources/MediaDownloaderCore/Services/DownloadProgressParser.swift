import Foundation

public actor DownloadProgressParser {
    private let sourceURL: String
    private var pendingStandardOutput = ""
    private var pendingStandardError = ""
    private var pendingCompletedDownloads = ""

public init(sourceURL: String) {
        self.sourceURL = sourceURL
    }

    public func consumeStandardOutput(_ output: String) -> [DownloadProgress] {
        consume(output, pendingOutput: &pendingStandardOutput)
    }

    public func consumeStandardError(_ output: String) -> [DownloadProgress] {
        consume(output, pendingOutput: &pendingStandardError)
    }

    public func consumeCompletedDownloads(_ output: String) -> [CompletedDownload] {
        pendingCompletedDownloads += output
        let lines = pendingCompletedDownloads.components(separatedBy: .newlines)
        pendingCompletedDownloads = lines.last ?? ""

        return lines.dropLast().compactMap(parseCompletedDownload)
    }

    private func consume(_ output: String, pendingOutput: inout String) -> [DownloadProgress] {
        pendingOutput += output
        let lines = pendingOutput.components(separatedBy: .newlines)
        pendingOutput = lines.last ?? ""

        return lines.dropLast().compactMap(parse)
    }

    private func parse(_ line: String) -> DownloadProgress? {
        let type: DownloadProgressType
        let range: Range<String.Index>

        if let metadataRange = line.range(of: "metadata:") {
            type = .metadata
            range = metadataRange
        } else if let progressRange = line.range(of: "progress:") {
            type = .progress
            range = progressRange
        } else {
            return nil
        }

        let rawFields = line[range.upperBound...].split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
        let fields: [String]

        switch type {
        case .metadata:
            guard rawFields.count >= 5 else { return nil }
            fields = [""] + rawFields
        case .progress:
            guard rawFields.count >= 6 else { return nil }
            fields = rawFields
        }

        guard fields.count >= 6 else {
            return nil
        }

        let percentage = type == .progress
            ? Double(fields[0].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
            : nil
        let thumbnailURL = URL(string: fields[5].trimmingCharacters(in: .whitespaces))

        return DownloadProgress(
            sourceURL: fields[4].isEmpty ? sourceURL : fields[4],
            title: fields[3].isEmpty ? sourceURL : fields[3],
            thumbnailURL: thumbnailURL,
            playlistIndex: Int(fields[1]),
            playlistCount: Int(fields[2]),
            fractionCompleted: percentage.map { min(max($0 / 100, 0), 1) }
        )
    }

    private func parseCompletedDownload(_ line: String) -> CompletedDownload? {
        guard let range = line.range(of: "completed:") else {
            return nil
        }

        let fields = line[range.upperBound...].split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 3 else {
            return nil
        }

        return CompletedDownload(
            fileURL: URL(fileURLWithPath: fields[0]),
            title: fields[1],
            sourceURL: fields[2].isEmpty ? sourceURL : fields[2]
        )
    }
}

private enum DownloadProgressType {
    case metadata
    case progress
}
