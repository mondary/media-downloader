import Foundation

enum CliRunner {
    private static let subcommands = ["list", "engines", "update-engine"]
    private static var lastRenderedPercent = -1

    static func handles(_ arguments: [String]) -> Bool {
        let args = arguments.filter { $0 != "--cli" }
        guard let first = args.first else { return false }
        if first == "--help" || first == "-h" || first == "help" { return true }
        if subcommands.contains(first) { return true }
        return URLValidator.looksLikeWebURL(first)
    }

    static func run(_ arguments: [String]) -> Never {
        let args = arguments.filter { $0 != "--cli" }
        let semaphore = DispatchSemaphore(value: 0)
        var exitCode: Int32 = 0

        Task {
            exitCode = await dispatch(args)
            semaphore.signal()
        }

        semaphore.wait()
        exit(exitCode)
    }

    private static func dispatch(_ arguments: [String]) async -> Int32 {
        var positional: [String] = []
        var outputFolder: URL?

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--out", index + 1 < arguments.count {
                outputFolder = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
                index += 2
                continue
            }
            positional.append(argument)
            index += 1
        }

        switch positional.first {
        case nil, "--help", "-h", "help":
            printUsage()
            return 0
        case "list":
            let limit = positional.dropFirst().compactMap { Int($0) }.first ?? 10
            return listHistory(limit: limit)
        case "engines":
            return enginesInfo()
        case "update-engine":
            return await updateEngine()
        case .some(let url) where URLValidator.looksLikeWebURL(url):
            return await download(url: url, folder: outputFolder ?? PreferencesStore().downloadFolder)
        default:
            print("unknown command: \(positional.first ?? "")")
            printUsage()
            return 1
        }
    }

    private static func printUsage() {
        print("""
        pkmd — PKMediaDownloader CLI

        Usage:
          pkmd <url> [--out <dir>]    download to folder (default: app setting)
          pkmd list [n]               last n history entries (default 10)
          pkmd engines                show engine info (yt-dlp path + version)
          pkmd update-engine          update yt-dlp (Homebrew or self-update)
          pkmd help                   this help

        History and download folder are shared with the Mac app.
        """)
    }

    private static func download(url: String, folder: URL) async -> Int32 {
        let status = DependencyChecker.check()
        guard status.isSatisfied else {
            print("missing tools: \(status.missingTools.joined(separator: ", "))")
            print(DependencyChecker.installPrompt)
            return 1
        }

        let service = MediaDownloaderService()
        let historyStore = HistoryStore()
        var recordedPaths = Set<String>()

        do {
            let result = try await service.download(
                sourceURL: url,
                destinationFolder: folder,
                onProgress: { progress in
                    render(progress)
                },
                onItemCompleted: { completed in
                    renderNewlineIfNeeded()
                    guard recordedPaths.insert(completed.fileURL.path).inserted else { return }

                    var history = historyStore.load()
                    history.insert(
                        DownloadItem(
                            sourceURL: completed.sourceURL,
                            title: completed.title,
                            filePath: completed.fileURL.path,
                            thumbnailPath: nil,
                            createdAt: Date()
                        ),
                        at: 0
                    )
                    historyStore.save(history)
                    print("done: \(completed.title)\n      \(completed.fileURL.path)")
                }
            )

            renderNewlineIfNeeded()
            print("saved: \(result.fileURL.path)")
            return 0
        } catch {
            renderNewlineIfNeeded()
            print("error: \(error.localizedDescription)")
            return 1
        }
    }

    private static func render(_ progress: DownloadProgress) {
        let percent = progress.fractionCompleted.map { Int(($0 * 100).rounded()) } ?? -1
        guard percent != lastRenderedPercent else { return }
        lastRenderedPercent = percent

        var line = percent >= 0 ? "\(percent)%" : "preparing"
        if let position = progress.playlistPosition {
            line += " · \(position)"
        }
        if !progress.title.isEmpty, progress.title.count <= 40 {
            line += " · \(progress.title)"
        }

        print("\r\(line)          ", terminator: "")
        fflush(stdout)
    }

    private static func renderNewlineIfNeeded() {
        if lastRenderedPercent >= 0 {
            lastRenderedPercent = -1
            print("")
        }
    }

    private static func listHistory(limit: Int) -> Int32 {
        let items = HistoryStore().load()
        guard !items.isEmpty else {
            print("history is empty")
            return 0
        }

        for item in items.prefix(limit) {
            let date = item.createdAt.formatted(date: .abbreviated, time: .shortened)
            print("\(date)  \(item.title)")
            print("           \(item.filePath)")
        }
        return 0
    }

    private static func enginesInfo() -> Int32 {
        guard let path = DependencyChecker.executablePath(named: "yt-dlp") else {
            print("engine: yt-dlp (not installed)")
            print(DependencyChecker.installPrompt)
            return 1
        }

        print("engine:  yt-dlp")
        print("path:    \(path)")
        print("version: \(DependencyChecker.version(ofTool: "yt-dlp") ?? "?")")
        return 0
    }

    private static func updateEngine() async -> Int32 {
        guard DependencyChecker.executablePath(named: "yt-dlp") != nil else {
            print("yt-dlp is not installed")
            return 1
        }

        print(DependencyChecker.updateYTDLP())
        print("version: \(DependencyChecker.version(ofTool: "yt-dlp") ?? "?")")
        return 0
    }
}
