import Foundation

enum MediaDownloaderError: LocalizedError {
    case missingTool(String)
    case processFailed(String)
    case missingOutputFile

    var errorDescription: String? {
        switch self {
        case .missingTool(let tool):
            return "\(tool) was not found in PATH."
        case .processFailed(let message):
            return message.isEmpty ? "Download failed." : message
        case .missingOutputFile:
            return "Download finished but no output file was found."
        }
    }
}

actor MediaDownloaderService {
    private let fileManager = FileManager.default

    func download(
        sourceURL: String,
        destinationFolder: URL,
        cookiesPath: String? = nil,
        cookiesBrowser: String = "chrome",
        onProgress: @escaping @Sendable (DownloadProgress) async -> Void = { _ in }
    ) async throws -> DownloadResult {
        try await requireTool("yt-dlp")
        try await requireTool("ffmpeg")
        try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        let startDate = Date()
        var arguments = [
            "yt-dlp",
            "--newline",
            "--progress-template", "download:progress:%(progress._percent_str)s\u{1F}%(info.playlist_index)s\u{1F}%(info.playlist_count)s\u{1F}%(info.title)s\u{1F}%(info.webpage_url)s\u{1F}%(info.thumbnail)s",
            "--restrict-filenames",
            "--merge-output-format", "mp4",
            "--remux-video", "mp4",
            "-S", "vcodec:h264,acodec:aac,ext:mp4:m4a",
            "--paths", destinationFolder.path,
            "--output", "%(title).180B [%(id)s].%(ext)s",
            "--print", "before_dl:metadata:%(playlist_index)s\u{1F}%(playlist_count)s\u{1F}%(title)s\u{1F}%(webpage_url)s\u{1F}%(thumbnail)s",
            "--print", "after_move:%(filepath)s",
            "--print", "after_move:%(title)s",
        ]

        let lowercased = sourceURL.lowercased()
        let requiresSocialCookies = lowercased.contains("instagram.com")
            || lowercased.contains("x.com")
            || lowercased.contains("twitter.com")
            || lowercased.contains("tiktok.com")

        if let cookies = cookiesPath, !cookies.isEmpty, fileManager.fileExists(atPath: cookies) {
            arguments += ["--cookies", cookies]
        } else if requiresSocialCookies {
            arguments += ["--cookies-from-browser", cookiesBrowser]
        }

        let isYouTubePlaylist = lowercased.contains("youtube.com/playlist?list=")
            || (lowercased.contains("youtube.com/watch") && lowercased.contains("list="))
            || (lowercased.contains("youtu.be/") && lowercased.contains("list="))

        if !isYouTubePlaylist {
            arguments += ["--no-playlist"]
        }

        arguments.append(sourceURL)

        let progressParser = DownloadProgressParser(sourceURL: sourceURL)
        let output = try await runProcess(
            executable: "/usr/bin/env",
            arguments: arguments,
            onStandardOutput: { output in
                Task {
                    let updates = await progressParser.consumeStandardOutput(output)
                    for update in updates {
                        await onProgress(update)
                    }
                }
            },
            onStandardError: { output in
                Task {
                    let updates = await progressParser.consumeStandardError(output)
                    for update in updates {
                        await onProgress(update)
                    }
                }
            }
        )
        let lines = output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let filePath = lines.first(where: { $0.hasPrefix("/") && fileManager.fileExists(atPath: $0) })
        let fileURL = try filePath.map(URL.init(fileURLWithPath:)) ?? newestMediaFile(in: destinationFolder, after: startDate)
        let title = lines.last(where: { !$0.hasPrefix("/") }) ?? fileURL.deletingPathExtension().lastPathComponent
        return DownloadResult(fileURL: fileURL, title: title)
    }

    private func requireTool(_ tool: String) async throws {
        _ = try await runProcess(executable: "/usr/bin/env", arguments: ["which", tool])
    }

    private func newestMediaFile(in folder: URL, after date: Date) throws -> URL {
        let extensions = Set(["mp4", "m4v", "mov"])
        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let candidates = files.compactMap { url -> (URL, Date)? in
            guard extensions.contains(url.pathExtension.lowercased()) else {
                return nil
            }

            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            guard let modified = values?.contentModificationDate, modified >= date.addingTimeInterval(-2) else {
                return nil
            }

            return (url, modified)
        }

        guard let newest = candidates.max(by: { $0.1 < $1.1 })?.0 else {
            throw MediaDownloaderError.missingOutputFile
        }

        return newest
    }

    private func runProcess(
        executable: String,
        arguments: [String],
        onStandardOutput: @escaping @Sendable (String) -> Void = { _ in },
        onStandardError: @escaping @Sendable (String) -> Void = { _ in }
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.environment = DependencyChecker.processEnvironment
            process.standardOutput = stdout
            process.standardError = stderr
            let standardOutput = ProcessOutputCollector()
            let standardError = ProcessOutputCollector()

            stdout.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else {
                    return
                }

                standardOutput.append(output)
                onStandardOutput(output)
            }

            stderr.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else {
                    return
                }

                standardError.append(output)
                onStandardError(output)
            }

            process.terminationHandler = { process in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""
                standardOutput.append(output)
                standardError.append(error)

                if process.terminationStatus == 0 {
                    continuation.resume(returning: standardOutput.value)
                } else {
                    continuation.resume(throwing: MediaDownloaderError.processFailed(standardError.value))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

private final class ProcessOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var output = ""

    func append(_ value: String) {
        lock.lock()
        output += value
        lock.unlock()
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return output
    }
}
