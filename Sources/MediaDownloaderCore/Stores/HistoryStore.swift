import Foundation

public final class HistoryStore {
    private let fileManager: FileManager
    private let historyURL: URL

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        let directory = support.appendingPathComponent("MediaDownloader", isDirectory: true)
        historyURL = directory.appendingPathComponent("history.json")
    }

    public func load() -> [DownloadItem] {
        guard let data = try? Data(contentsOf: historyURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([DownloadItem].self, from: data)) ?? []
    }

    public func save(_ history: [DownloadItem]) {
        do {
            try fileManager.createDirectory(
                at: historyURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            NSLog("Failed to save download history: \(error.localizedDescription)")
        }
    }
}
