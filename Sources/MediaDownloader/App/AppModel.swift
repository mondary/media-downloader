import AppKit
import MediaDownloaderCore
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var history: [DownloadItem] = []
    @Published private(set) var isDownloading = false
    @Published private(set) var activeDownload: DownloadProgress?
    @Published var statusMessage: String?
    @Published private(set) var lastDownloadFailed = false
    @Published var activeTrimSession: ActiveTrimSession?

    private let preferences: PreferencesStore
    private let historyStore = HistoryStore()
    private let downloader = MediaDownloaderService()
    private let thumbnailGenerator = ThumbnailGenerator()
    private let trimExporter = TrimExportService()
    private var pasteTask: Task<Void, Never>?
    private var completedDownloadPaths = Set<String>()
    private var settingsWindowController: SettingsWindowController?

    var downloadFolderPath: String {
        preferences.downloadFolder.path
    }

    init(preferences: PreferencesStore = PreferencesStore(), previewHistory: [DownloadItem]? = nil) {
        self.preferences = preferences
        history = previewHistory ?? historyStore.load()
    }

    func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = preferences.downloadFolder
        panel.prompt = "Choose"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        preferences.downloadFolder = url
    }

    func selectCookiesFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText, .data, .json]
        panel.prompt = "Select Cookies File"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        preferences.cookiesPath = url.path
    }

    func handlePasteCandidate() {
        pasteTask?.cancel()

        let candidate = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard URLValidator.looksLikeWebURL(candidate) else {
            return
        }

        pasteTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.startDownloadIfNeeded(candidate)
        }
    }

    func submitInput() {
        pasteTask?.cancel()
        Task { [weak self] in
            guard let self else { return }
            await self.startDownloadIfNeeded(self.inputText)
        }
    }

    func copyFile(_ item: DownloadItem) {
        ClipboardService.copyFile(URL(fileURLWithPath: item.filePath))
        statusMessage = "Copied \(item.displayName)."
    }

    func revealInFinder(_ item: DownloadItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.filePath)])
    }

    func openSourceURL(_ item: DownloadItem) {
        guard let url = URL(string: item.sourceURL) else { return }
        NSWorkspace.shared.open(url)
    }

    func deleteHistoryItem(_ item: DownloadItem) {
        history.removeAll { $0.id == item.id }
        historyStore.save(history)

        if activeTrimSession?.item.id == item.id {
            activeTrimSession = nil
        }
    }

    func clearHistory() {
        history.removeAll()
        historyStore.save(history)
        activeTrimSession = nil
    }

    func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                preferences: preferences,
                onCheckForUpdates: { UpdaterManager.shared.checkForUpdates() }
            )
        }

        settingsWindowController?.show()
    }

    func hotKeyShortcut(for action: HotKeyAction) -> HotKeyShortcut {
        preferences.hotKeyShortcut(for: action)
    }

    func editTrim(_ item: DownloadItem) {
        activeTrimSession = ActiveTrimSession(item: item)
    }

    func closeTrim() {
        activeTrimSession = nil
    }

    func saveActiveTrim(_ selection: TrimSelection) async throws -> URL {
        guard let session = activeTrimSession else {
            throw TrimExportError.invalidRange
        }

        let outputURL = await trimExporter.saveURL(for: session.fileURL, selection: selection)
        return try await trimExporter.exportTrim(
            sourceURL: session.fileURL,
            selection: selection,
            to: outputURL
        )
    }

    func copyActiveTrim(_ selection: TrimSelection) async throws {
        guard let session = activeTrimSession else {
            throw TrimExportError.invalidRange
        }

        let outputURL = try await trimExporter.temporaryURL(for: session.fileURL)
        let trimmedURL = try await trimExporter.exportTrim(
            sourceURL: session.fileURL,
            selection: selection,
            to: outputURL
        )
        ClipboardService.copyFile(trimmedURL)
    }

    private func startDownloadIfNeeded(_ rawURL: String) async {
        let sourceURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isDownloading else { return }
        guard URLValidator.looksLikeWebURL(sourceURL) else {
            statusMessage = "Enter a valid URL."
            return
        }

        isDownloading = true
        activeDownload = DownloadProgress(
            sourceURL: sourceURL,
            title: sourceURL,
            thumbnailURL: nil,
            playlistIndex: nil,
            playlistCount: nil,
            fractionCompleted: nil
        )
        statusMessage = "Downloading..."
        lastDownloadFailed = false
        completedDownloadPaths.removeAll()
        NotificationCenter.default.post(name: .downloadStarted, object: nil)
        let model = self

        do {
            let cookies = preferences.cookiesPath.isEmpty ? nil : preferences.cookiesPath
            let result = try await downloader.download(
                sourceURL: sourceURL,
                destinationFolder: preferences.downloadFolder,
                cookiesPath: cookies,
                cookiesBrowser: preferences.cookiesBrowser,
                onProgress: { progress in
                    await model.updateActiveDownload(progress)
                },
                onItemCompleted: { completedDownload in
                    await model.recordCompletedDownload(completedDownload)
                }
            )
            let completedDownload = CompletedDownload(
                fileURL: result.fileURL,
                title: result.title,
                sourceURL: sourceURL
            )
            let item = recordCompletedDownload(completedDownload)
                ?? history.first(where: { $0.filePath == result.fileURL.path })
                ?? DownloadItem(
                sourceURL: sourceURL,
                title: result.title,
                filePath: result.fileURL.path,
                thumbnailPath: nil,
                createdAt: Date()
            )

            ClipboardService.copyFile(result.fileURL)
            activeTrimSession = ActiveTrimSession(item: item)
            inputText = ""
            statusMessage = "Downloaded and copied."
            NotificationCenter.default.post(name: .downloadCompleted, object: nil, userInfo: ["title": result.title])
            generateThumbnailInBackground(for: item)
        } catch {
            statusMessage = error.localizedDescription
            lastDownloadFailed = true
            NotificationCenter.default.post(name: .downloadFailed, object: nil, userInfo: ["error": error.localizedDescription])
        }

        isDownloading = false
        activeDownload = nil
    }

    private func updateActiveDownload(_ progress: DownloadProgress) {
        guard isDownloading else { return }
        activeDownload = progress
        NotificationCenter.default.post(name: .downloadProgressed, object: progress)
    }

    @discardableResult
    private func recordCompletedDownload(_ completedDownload: CompletedDownload) -> DownloadItem? {
        guard completedDownloadPaths.insert(completedDownload.fileURL.path).inserted else {
            return nil
        }

        let item = DownloadItem(
            sourceURL: completedDownload.sourceURL,
            title: completedDownload.title,
            filePath: completedDownload.fileURL.path,
            thumbnailPath: nil,
            createdAt: Date()
        )
        history.insert(item, at: 0)
        historyStore.save(history)
        generateThumbnailInBackground(for: item)
        return item
    }

    private func generateThumbnailInBackground(for item: DownloadItem) {
        Task { [weak self] in
            guard let self, let thumbnailURL = try? await thumbnailGenerator.thumbnailPath(for: URL(fileURLWithPath: item.filePath)) else {
                return
            }

            guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
            history[index] = DownloadItem(
                id: item.id,
                sourceURL: item.sourceURL,
                title: item.title,
                filePath: item.filePath,
                thumbnailPath: thumbnailURL.path,
                createdAt: item.createdAt
            )
            historyStore.save(history)
        }
    }

}
