import AppKit
import Combine
import Foundation
import Sparkle
import SwiftUI

private final class ChannelFeedProvider: NSObject, SPUUpdaterDelegate {
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        let isDevBuild = (Bundle.main.object(forInfoDictionaryKey: "PKMediaDownloaderBuildChannel") as? String) == "dev"
        let isDevChannel = UserDefaults.standard.string(forKey: "updateChannel") == "dev"
        let address = (isDevBuild || isDevChannel)
            ? "https://raw.githubusercontent.com/mondary/media-downloader/main/appcast-dev.xml"
            : "https://raw.githubusercontent.com/mondary/media-downloader/main/appcast.xml"
        guard var components = URLComponents(string: address) else { return address }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "_pk_refresh", value: UUID().uuidString)]
        return components.url?.absoluteString ?? address
    }
}

@MainActor
final class UpdaterManager: NSObject, ObservableObject {
    static let shared = UpdaterManager()
    static let channelKey = "updateChannel"
    static let stableFeedURL = "https://raw.githubusercontent.com/mondary/media-downloader/main/appcast.xml"
    static let devFeedURL = "https://raw.githubusercontent.com/mondary/media-downloader/main/appcast-dev.xml"

    private let controller: SPUStandardUpdaterController
    private let channelFeedProvider: ChannelFeedProvider
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var latestStableVersion: String?
    @Published private(set) var latestDevVersion: String?
    @Published private(set) var availableUpdateVersion: String?
    private var latestStableBuild: String?
    private var latestDevBuild: String?

    private override init() {
        let channelFeedProvider = ChannelFeedProvider()
        self.channelFeedProvider = channelFeedProvider
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: channelFeedProvider,
            userDriverDelegate: nil
        )
        super.init()
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        #if DEBUG
        return
        #else
        configure(channel: UserDefaults.standard.string(forKey: Self.channelKey) ?? "stable")
        controller.startUpdater()
        #endif
    }

    func updateChannelChanged(to channel: String) {
        #if !DEBUG
        configure(channel: channel)
        #endif
        refreshAvailableVersions()
    }

    func checkForUpdates() {
        #if DEBUG
        return
        #else
        refreshAvailableVersions()
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
        #endif
    }

    private func configure(channel: String) {
        let isDevBuild = (Bundle.main.object(forInfoDictionaryKey: "PKMediaDownloaderBuildChannel") as? String) == "dev"
        controller.updater.automaticallyDownloadsUpdates = isDevBuild || channel == "dev"
    }

    func refreshAvailableVersions() {
        Task {
            async let stable = Self.latestInfo(at: Self.stableFeedURL)
            async let dev = Self.latestInfo(at: Self.devFeedURL)
            let feeds = await (stable, dev)
            latestStableVersion = feeds.0?.shortVersion
            latestStableBuild = feeds.0?.buildVersion
            latestDevVersion = feeds.1?.shortVersion
            latestDevBuild = feeds.1?.buildVersion
            refreshUpdateAvailability()
        }
    }

    func versionStatus(for channel: String) -> MediaChannelVersionStatus {
        let installedChannel = (Bundle.main.object(forInfoDictionaryKey: "PKMediaDownloaderBuildChannel") as? String) == "dev" ? "dev" : "stable"
        guard channel == installedChannel else { return .otherChannel }
        guard let publishedBuild = channel == "dev" ? latestDevBuild : latestStableBuild,
              let installedBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
              let order = compareBuildNumbers(publishedBuild, installedBuild) else { return .unavailable }
        switch order {
        case .orderedDescending: return .updateAvailable
        case .orderedSame: return .upToDate
        case .orderedAscending: return .installedAhead
        }
    }

    private func refreshUpdateAvailability() {
        let isDevBuild = (Bundle.main.object(forInfoDictionaryKey: "PKMediaDownloaderBuildChannel") as? String) == "dev"
        let channel = isDevBuild ? "dev" : UserDefaults.standard.string(forKey: Self.channelKey) ?? "stable"
        let availableBuild = channel == "dev" ? latestDevBuild : latestStableBuild
        let installedBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        availableUpdateVersion = if let availableBuild, let installedBuild,
                                    compareBuildNumbers(availableBuild, installedBuild) == .orderedDescending {
            channel == "dev" ? latestDevVersion : latestStableVersion
        } else {
            nil
        }
    }

    private static func latestInfo(at address: String) async -> MediaAppcastInfo? {
        guard var components = URLComponents(string: address) else { return nil }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "_pk_refresh", value: UUID().uuidString)]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let parser = MediaAppcastParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        return xml.parse() ? parser.info : nil
    }
}

enum MediaChannelVersionStatus {
    case updateAvailable, upToDate, installedAhead, otherChannel, unavailable

    var symbol: String {
        switch self {
        case .updateAvailable: "arrow.down.circle.fill"
        case .upToDate: "checkmark.circle.fill"
        case .installedAhead: "arrow.up.circle.fill"
        case .otherChannel: "circle.dashed"
        case .unavailable: "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .updateAvailable: .accentColor
        case .upToDate: .green
        case .installedAhead: .orange
        case .otherChannel, .unavailable: .secondary
        }
    }

    func title(language: MediaSettingsLanguage) -> String {
        switch self {
        case .updateAvailable: language.text("Mise à jour disponible", "Update available")
        case .upToDate: language.text("À jour", "Up to date")
        case .installedAhead: language.text("Version installée plus récente", "Installed version is newer")
        case .otherChannel: language.text("Autre canal", "Other channel")
        case .unavailable: language.text("Version indisponible", "Version unavailable")
        }
    }
}

private struct MediaAppcastInfo {
    let shortVersion: String
    let buildVersion: String
}

private func compareBuildNumbers(_ lhs: String, _ rhs: String) -> ComparisonResult? {
    func components(_ value: String) -> [UInt64]? {
        let parts = value.split(separator: ".")
        guard !parts.isEmpty else { return nil }
        let numbers = parts.compactMap { UInt64($0) }
        return numbers.count == parts.count ? numbers : nil
    }
    guard let left = components(lhs), let right = components(rhs) else { return nil }
    for index in 0..<max(left.count, right.count) {
        let a = index < left.count ? left[index] : 0
        let b = index < right.count ? right[index] : 0
        if a != b { return a < b ? .orderedAscending : .orderedDescending }
    }
    return .orderedSame
}

private final class MediaAppcastParser: NSObject, XMLParserDelegate {
    private var readingShortVersion = false
    private var readingBuild = false
    private var currentText = ""
    private var shortVersion: String?
    private var buildVersion: String?

    var info: MediaAppcastInfo? {
        guard let shortVersion, let buildVersion else { return nil }
        return MediaAppcastInfo(shortVersion: shortVersion, buildVersion: buildVersion)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "sparkle:shortVersionString" || qName == "sparkle:shortVersionString" {
            readingShortVersion = true
            currentText = ""
        } else if elementName == "sparkle:version" || qName == "sparkle:version" {
            readingBuild = true
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if readingShortVersion || readingBuild { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if readingShortVersion && (elementName == "sparkle:shortVersionString" || qName == "sparkle:shortVersionString") {
            shortVersion = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            readingShortVersion = false
        } else if readingBuild && (elementName == "sparkle:version" || qName == "sparkle:version") {
            buildVersion = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            readingBuild = false
        }
    }
}
