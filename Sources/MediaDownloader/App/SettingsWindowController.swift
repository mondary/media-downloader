import AppKit
import MediaDownloaderCore
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let preferences: PreferencesStore
    private let onCheckForUpdates: () -> Void

    init(preferences: PreferencesStore, initialSection: MediaSettingsSection = .general, onCheckForUpdates: @escaping () -> Void) {
        self.preferences = preferences
        self.onCheckForUpdates = onCheckForUpdates

        let contentSize = NSSize(width: 780, height: 620)
        let minimumSize = NSSize(width: 760, height: 560)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "PKMediaDownloader — Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.minSize = minimumSize
        window.maxSize = NSSize(width: 980, height: 900)
        window.collectionBehavior = [.moveToActiveSpace]
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true

        super.init(window: window)

        window.delegate = self
        let hosting = NSHostingView(
            rootView: SettingsRootView(preferences: preferences, initialSection: initialSection, onCheckForUpdates: onCheckForUpdates)
                .frame(minWidth: minimumSize.width, minHeight: minimumSize.height)
        )
        window.contentView = hosting
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        guard let window else { return }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window?.makeFirstResponder(nil)
    }
}

enum MediaSettingsLanguage: String, CaseIterable, Identifiable {
    case fr, en
    var id: String { rawValue }
    var flag: String { self == .fr ? "🇫🇷" : "🇬🇧" }
    static var current: MediaSettingsLanguage {
        MediaSettingsLanguage(rawValue: UserDefaults.standard.string(forKey: "mediaSettingsLanguage") ?? "en") ?? .en
    }
    func text(_ french: String, _ english: String) -> String { self == .fr ? french : english }
}

enum MediaSettingsSection: String, CaseIterable, Identifiable {
    case general, download, authentication, shortcuts, credits, library, support, about
    var id: String { rawValue }
    var group: String { self == .credits || self == .about || self == .support || self == .library ? "PK PROJECTS" : "APP" }
    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .download: "arrow.down.to.line"
        case .authentication: "person.crop.circle.badge.key"
        case .shortcuts: "keyboard"
        case .credits: "text.book.closed"
        case .about: "info.circle"
        case .support: "heart.fill"
        case .library: "square.grid.2x2"
        }
    }
    func title(_ language: MediaSettingsLanguage) -> String {
        switch self {
        case .general: language.text("Général", "General")
        case .download: language.text("Téléchargement", "Download")
        case .authentication: language.text("Authentification", "Authentication")
        case .shortcuts: language.text("Raccourcis", "Shortcuts")
        case .credits: language.text("Crédits", "Credits")
        case .about: language.text("À propos", "About")
        case .support: language.text("Soutenir", "Support")
        case .library: language.text("Bibliothèque de projets", "Project Library")
        }
    }
}

// MARK: - SwiftUI Settings Root

private struct SettingsRootView: View {
    @ObservedObject var preferences: PreferencesStoreWrapper
    @ObservedObject private var updater = UpdaterManager.shared
    @AppStorage("updateChannel") private var updateChannel = "stable"
    private var isDevBuild: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "PKMediaDownloaderBuildChannel") as? String) == "dev"
    }
    let onCheckForUpdates: () -> Void
    @State private var selection: MediaSettingsSection = .general
    @State private var searchText = ""
    @State private var language = MediaSettingsLanguage.current
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var engineVersion: String?
    @State private var isUpdatingEngine = false
    @State private var engineUpdateResult: String?
    private let statusTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var visibleSections: [MediaSettingsSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return MediaSettingsSection.allCases }
        return MediaSettingsSection.allCases.filter {
            $0.title(language).localizedCaseInsensitiveContains(query) || $0.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    init(preferences: PreferencesStore, initialSection: MediaSettingsSection, onCheckForUpdates: @escaping () -> Void) {
        self.preferences = PreferencesStoreWrapper(preferences)
        _selection = State(initialValue: initialSection)
        self.onCheckForUpdates = onCheckForUpdates
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                selectedContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Divider()
                settingsFooter
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            engineVersion = await Task.detached(priority: .utility) {
                DependencyChecker.version(ofTool: "yt-dlp")
            }.value
        }
        .onChange(of: preferences.autoCopy) { _, _ in
            preferences.saveAutoCopy()
        }
        .onChange(of: preferences.cookiesPath) { _, _ in
            preferences.saveCookiesPath()
        }
        .onChange(of: preferences.cookiesBrowser) { _, _ in
            preferences.saveCookiesBrowser()
        }
        .onReceive(statusTimer) { _ in
            accessibilityGranted = AXIsProcessTrusted()
        }
        .onAppear {
            updater.refreshAvailableVersions()
            language = .current
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().interpolation(.high).frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("PKMediaDownloader").font(.headline)
                    Text(language.text("Téléchargements multimédias", "Media downloads"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.top, 22).padding(.bottom, 24)

            Text(language.text("RÉGLAGES", "SETTINGS"))
                .font(.system(size: 10, weight: .bold)).foregroundStyle(.tertiary)
                .padding(.horizontal, 18).padding(.bottom, 8)
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(language.text("Rechercher", "Search settings"), text: $searchText).textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).frame(height: 30)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
            .padding(.horizontal, 10).padding(.bottom, 10)

            ForEach(["APP", "PK PROJECTS"], id: \.self) { group in
                let sections = visibleSections.filter { $0.group == group }
                if !sections.isEmpty {
                    Text(group == "APP" ? language.text("APPLICATION", "APP") : group)
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
                        .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 4)
                    ForEach(sections) { item in
                        Button { selection = item } label: {
                            Label(item.title(language), systemImage: item.icon)
                                .font(.system(size: 12, weight: selection == item ? .semibold : .regular))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10).frame(height: 34)
                                .foregroundStyle(item == .support ? Color(red: 1, green: 0.37, blue: 0.36) : .primary)
                                .background(selection == item ? Color.accentColor.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain).padding(.horizontal, 8)
                    }
                }
            }

            Spacer(minLength: 12)
            HStack(spacing: 8) {
                ForEach(MediaSettingsLanguage.allCases) { item in
                    Button(item.flag) {
                        language = item
                        UserDefaults.standard.set(item.rawValue, forKey: "mediaSettingsLanguage")
                    }
                    .buttonStyle(.plain).opacity(language == item ? 1 : 0.55).help(item == .fr ? "Français" : "English")
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 10)
            HStack(spacing: 5) {
                Text("PKMediaDownloader \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.75)
                if let available = updater.availableUpdateVersion {
                    Button { onCheckForUpdates() } label: {
                        Label(available, systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced)).lineLimit(1)
                    }
                    .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                    .help(language.text("Installer la version %@", "Install version %@").replacingOccurrences(of: "%@", with: available))
                }
            }
            .padding(.horizontal, 14).padding(.bottom, 18)
        }
        .frame(width: 220).background(.regularMaterial)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selection {
        case .general:
            ScrollView { VStack(alignment: .leading, spacing: 20) { appSection; engineSection }.padding(24) }
        case .download:
            ScrollView { downloadSection.padding(24) }
        case .authentication:
            ScrollView { socialMediaSection.padding(24) }
        case .shortcuts:
            ScrollView { VStack(alignment: .leading, spacing: 20) { accessibilitySection; shortcutsSection }.padding(24) }
        case .about:
            aboutSection
        case .credits:
            creditsSection
        case .support:
            supportSection
        case .library:
            projectLibrarySection
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PKMediaDownloader")
                            .font(.title3.weight(.semibold))
                        Text(language.text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev") — Téléchargeur vidéo natif pour macOS", "v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev") — Native macOS video downloader"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - About and Updates

    private var aboutSection: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 0) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable().interpolation(.high).frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(.top, 36).padding(.bottom, 16)
                        Text("PKMediaDownloader").font(.system(size: 24, weight: .bold))
                        Text(language.text("Version installée", "Installed version") + " \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"))")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary).padding(.top, 4).help(language.text("Version installée", "Installed version"))
                        Text(language.text("Par PK", "By PK"))
                            .font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 2).padding(.bottom, 24)
                        VStack(alignment: .leading, spacing: 14) {
                            Text(language.text("Salut l’ami,", "Hey friend,")).italic().font(.system(size: 13))
                            Text(language.text(
                                "PKMediaDownloader est une application macOS native pour télécharger, découper et exporter des médias. Les traitements restent sur ce Mac.",
                                "PKMediaDownloader is a native macOS app to download, trim and export media. Processing stays on this Mac."
                            )).font(.system(size: 13)).foregroundStyle(.secondary)
                            Text(language.text("Merci d’utiliser l’application.", "Thanks for using the app."))
                                .font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 8)
                            Text("— PK").font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 480, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            Divider()
            updatesCard
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
    }

    private var settingsFooter: some View {
        HStack(spacing: 16) {
            Link(destination: URL(string: "https://github.com/mondary/media-downloader")!) {
                Label("GitHub", systemImage: "network")
            }
            .foregroundStyle(.secondary)
            Link(destination: URL(string: "https://github.com/mondary/media-downloader/issues")!) {
                Label("Issues", systemImage: "exclamationmark.bubble")
            }
            .foregroundStyle(.secondary)
            Link(destination: URL(string: "https://ko-fi.com/pouark")!) {
                HStack(spacing: 4) {
                    kofiIcon.resizable().scaledToFit().frame(width: 12, height: 12)
                    Text(language.text("Soutenir sur Ko-fi", "Support on Ko-fi"))
                }
                .foregroundStyle(Color(red: 1, green: 0.37, blue: 0.36))
            }
            Spacer(minLength: 8)
            Text("MIT · macOS 14+").foregroundStyle(.tertiary)
        }
        .font(.caption)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var kofiIcon: Image {
        if let logo = bundledImage(named: "kofi-logo", in: "") {
            return Image(nsImage: logo)
        }
        return Image(systemName: "cup.and.saucer.fill")
    }

    private struct CreditEntry: Identifiable {
        let id: String
        let icon: String
        let name: String
        let author: String
        let use: String
        let license: String?
        let tint: Color
        let url: URL
    }

    private var toolCredits: [CreditEntry] {
        [
            CreditEntry(id: "yt-dlp", icon: "arrow.down.circle", name: "yt-dlp", author: "yt-dlp team", use: language.text("Téléchargement des médias", "Media downloading"), license: nil, tint: .blue, url: URL(string: "https://github.com/yt-dlp/yt-dlp")!),
            CreditEntry(id: "ffmpeg", icon: "film", name: "FFmpeg", author: "FFmpeg project", use: language.text("Conversion, extraction et découpe vidéo", "Video conversion, extraction and trimming"), license: nil, tint: .orange, url: URL(string: "https://ffmpeg.org/")!),
            CreditEntry(id: "sparkle", icon: "sparkles", name: "Sparkle", author: "Sparkle project", use: language.text("Mises à jour de l’app macOS", "macOS app updates"), license: "MIT", tint: .purple, url: URL(string: "https://github.com/sparkle-project/Sparkle")!)
        ]
    }

    private var upstreamCredits: [CreditEntry] {
        [
            CreditEntry(id: "upstream", icon: "arrow.triangle.branch", name: "pixel-point/media-downloader", author: "pixel-point", use: language.text("Projet d’origine adapté pour PKMediaDownloader", "Original project adapted for PKMediaDownloader"), license: nil, tint: .teal, url: URL(string: "https://github.com/pixel-point/media-downloader")!),
            CreditEntry(id: "cobalt", icon: "safari", name: "Cobalt", author: "Cobalt project", use: language.text("Service de secours externe, ouvert dans le navigateur à la demande", "Optional external fallback, opened in the browser on request"), license: nil, tint: .indigo, url: URL(string: "https://cobalt.tools/")!)
        ]
    }

    private var creditsSection: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Text(language.text("Crédits & inspirations", "Credits & inspirations"))
                        .font(.system(size: 20, weight: .bold))
                    Text(language.text("Les outils utilisés et les projets qui ont inspiré cette application.", "The tools used and projects that inspired this app."))
                        .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, 36).padding(.bottom, 8)

                creditGroup(title: language.text("Outils et dépendances utilisés", "Tools and dependencies used"), entries: toolCredits)
                creditGroup(title: language.text("Projet amont et service facultatif", "Upstream project and optional service"), entries: upstreamCredits)
                Text(language.text(
                    "Cobalt est externe et facultatif : aucune URL n’y est envoyée automatiquement. Les crédits ne remplacent pas les notices de licence.",
                    "Cobalt is an optional external service: URLs are never sent automatically. These credits do not replace license notices."
                )).font(.caption).foregroundStyle(.secondary).frame(maxWidth: 480, alignment: .leading)
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
    }

    private func creditGroup(title: String, entries: [CreditEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 13, weight: .semibold))
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 { Divider().padding(.leading, 58) }
                    Link(destination: entry.url) {
                        HStack(spacing: 12) {
                            Image(systemName: entry.icon).font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(entry.tint).frame(width: 36, height: 36)
                                .background(entry.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(entry.name).font(.system(size: 12, weight: .semibold))
                                    if let license = entry.license {
                                        Text(license).font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                                            .padding(.horizontal, 5).padding(.vertical, 2).background(Color.primary.opacity(0.06), in: Capsule())
                                    }
                                }
                                Text(entry.author).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                                Text(entry.use).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 9).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: 480, alignment: .leading)
    }

    private var updatesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("Mises à jour", "Updates")).font(.headline)
            HStack(spacing: 10) {
                updateVersionColumn(
                    title: language.text("Stable", "Stable"),
                    value: updater.latestStableVersion ?? language.text("Non publiée", "Not published"),
                    status: updater.versionStatus(for: "stable")
                )
                updateVersionColumn(
                    title: language.text("Dev", "Dev"),
                    value: updater.latestDevVersion ?? language.text("Non publiée", "Not published"),
                    status: updater.versionStatus(for: "dev")
                )
            }
            HStack(spacing: 12) {
                Picker(language.text("Canal de mise à jour", "Update channel"), selection: Binding(
                    get: { isDevBuild ? "dev" : updateChannel },
                    set: {
                        guard !isDevBuild else { return }
                        updateChannel = $0
                        UpdaterManager.shared.updateChannelChanged(to: $0)
                    }
                )) {
                    Text("Stable").tag("stable")
                    Text("Dev").tag("dev")
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 190).disabled(isDevBuild)
                Spacer(minLength: 0)
                Button { onCheckForUpdates() } label: {
                    Label(
                        updateButtonTitle,
                        systemImage: updater.availableUpdateVersion == nil ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent).disabled(!updater.canCheckForUpdates)
            }
            Text(language.text(
                isDevBuild ? "Cette build Dev suit le canal Dev." : "Les versions Stable sont publiées et testées ; Dev suit les builds de développement.",
                isDevBuild ? "This Dev build follows the Dev channel." : "Stable builds are tested releases; Dev follows development builds."
            ))
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.035)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    private var updateButtonTitle: String {
        guard let version = updater.availableUpdateVersion else {
            return language.text("Rechercher les mises à jour…", "Check for Updates…")
        }
        return language.text("Installer %@", "Install %@").replacingOccurrences(of: "%@", with: version)
    }

    private func updateVersionColumn(title: String, value: String, status: MediaChannelVersionStatus) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 14, weight: .semibold, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.75).help(value)
            Label(status.title(language: language), systemImage: status.symbol)
                .font(.system(size: 10, weight: .medium)).foregroundStyle(status.color)
                .lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Engine Section

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Download Engine")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("yt-dlp \(engineVersion ?? "—")")
                        .font(.subheadline.weight(.medium))
                    if let engineUpdateResult {
                        Text(engineUpdateResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                Spacer()

                Button(isUpdatingEngine ? "Updating…" : "Update") {
                    isUpdatingEngine = true
                    engineUpdateResult = nil
                    Task {
                        let result = await Task.detached(priority: .userInitiated) {
                            DependencyChecker.updateYTDLP()
                        }.value
                        engineUpdateResult = result
                        engineVersion = await Task.detached(priority: .utility) {
                            DependencyChecker.version(ofTool: "yt-dlp")
                        }.value
                        isUpdatingEngine = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isUpdatingEngine)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Download Section

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Download")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Save to")
                        .font(.subheadline.weight(.medium))
                    Text(preferences.downloadFolder.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button("Change…") { preferences.chooseDownloadFolder() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Divider().overlay(Color.white.opacity(0.08))

            HStack(spacing: 12) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundStyle(.secondary)

                Text("Auto-copy to clipboard")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Toggle("", isOn: $preferences.autoCopy)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Social Media Section

    private var socialMediaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Social Media Auth")
                .font(.headline)

            Text("Your logged-in browser session is used automatically for Instagram, X/Twitter, and TikTok.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Browser session")
                        .font(.subheadline.weight(.medium))
                    Text("Use the browser where you are connected to X, Instagram, or TikTok.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Picker("Browser", selection: $preferences.cookiesBrowser) {
                    Text("Chrome").tag("chrome")
                    Text("Brave").tag("brave")
                    Text("Firefox").tag("firefox")
                    Text("Safari").tag("safari")
                    Text("Edge").tag("edge")
                }
                .labelsHidden()
                .frame(width: 115)
            }

            Text("Optional: select a cookies.txt file only if browser extraction is unavailable.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack {
                Button("Choose cookies.txt…") { preferences.selectCookiesFile() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                if !preferences.cookiesPath.isEmpty {
                    Button("Clear imported file") { preferences.cookiesPath = "" }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Accessibility Section

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accessibility")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accessibilityGranted ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accessibilityGranted ? "Accessibility Granted" : "Accessibility Required")
                        .font(.subheadline.weight(.medium))
                    Text("Global keyboard shortcuts need accessibility access.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !accessibilityGranted {
                    Button("Grant Access") {
                        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        AXIsProcessTrustedWithOptions(options)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accessibilityGranted ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accessibilityGranted ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard Shortcuts")
                .font(.headline)

            VStack(spacing: 0) {
                shortcutRow("Activate app", action: .activateApp)
                Divider().overlay(Color.white.opacity(0.08))
                shortcutRow("Copy file", action: .copy)
                Divider().overlay(Color.white.opacity(0.08))
                shortcutRow("Open trim mode", action: .openTrim)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func shortcutRow(_ title: String, action: HotKeyAction) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            ShortcutRecorderControl(shortcut: preferences.hotKeyShortcut(for: action)) { shortcut in
                preferences.setHotKeyShortcut(shortcut, for: action)
            }
            .frame(width: 126, height: 26)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Support and Project Library

    private var supportSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill").font(.system(size: 36))
                        .foregroundStyle(Color(red: 1, green: 0.37, blue: 0.36))
                    Text(language.text("Soutenir PKMediaDownloader", "Support PKMediaDownloader"))
                        .font(.system(size: 20, weight: .bold))
                    Text(language.text("Si l’application vous est utile, vous pouvez soutenir son développement.", "If this app is useful to you, consider supporting its development."))
                        .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, 36).padding(.bottom, 24)
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        kofiIcon.resizable().scaledToFit()
                            .frame(width: 28, height: 28)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ko-fi").font(.system(size: 14, weight: .semibold))
                            Text(language.text("Offrir un café au développeur", "Support the developer with a coffee"))
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Link(destination: URL(string: "https://ko-fi.com/pouark")!) {
                            Text(language.text("Soutenir sur Ko-fi", "Support on Ko-fi"))
                                .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(Color(red: 1, green: 0.37, blue: 0.36), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                    VStack(spacing: 0) {
                        supportLink(icon: "network", title: "GitHub", subtitle: language.text("Code source et versions", "Source code and releases"), url: "https://github.com/mondary/media-downloader")
                        Divider().padding(.leading, 52)
                        supportLink(icon: "exclamationmark.bubble", title: language.text("Signaler un problème", "Report an issue"), subtitle: language.text("Bugs, idées et retours", "Bugs, ideas and feedback"), url: "https://github.com/mondary/media-downloader/issues")
                        Divider().padding(.leading, 52)
                        supportLink(icon: "person.crop.circle", title: language.text("PK sur GitHub", "PK on GitHub"), subtitle: language.text("Découvrir les autres projets", "Discover other projects"), url: "https://github.com/mondary")
                    }
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: 480).padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var projectLibrarySection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2.fill").font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Text(language.text("Bibliothèque de projets", "Project Library")).font(.system(size: 20, weight: .bold))
                    Text(language.text("Découvrez les autres outils et projets que je développe.", "Discover the other tools and projects I build."))
                        .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.bottom, 4)

                featuredProjectCard(mediaProject)
                Text(language.text("Plus de projets", "More projects"))
                    .font(.system(size: 18, weight: .bold, design: .rounded)).padding(.top, 6)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(otherProjects) { project in projectCard(project) }
                }
                Link(destination: URL(string: "https://github.com/mondary")!) {
                    Label(language.text("Voir tous les dépôts sur GitHub", "View all repositories on GitHub"), systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent).padding(.top, 4)
            }
            .padding(.horizontal, 28).padding(.top, 32).padding(.bottom, 28)
            .frame(maxWidth: 860).frame(maxWidth: .infinity)
        }
    }

    private var mediaProject: MediaProject {
        MediaProject(
            id: "media-downloader", title: "PKMediaDownloader", kind: "macOS app",
            description: language.text(
                "Téléchargez des vidéos avec yt-dlp — YouTube, Instagram, X, TikTok et des milliers d’autres sites.",
                "Download videos with yt-dlp — YouTube, Instagram, X, TikTok and thousands more."
            ),
            iconAsset: "PKMediaDownloader", screenshot: "PKMediaDownloader", tint: Color(red: 0.96, green: 0.25, blue: 0.37)
        )
    }

    private var otherProjects: [MediaProject] {
        [
            MediaProject(id: "PKwindowsManagement", title: "PKwindowsManagement", kind: "macOS app", description: language.text("Gérez les fenêtres au clavier, les Rooms et les apps.", "Manage windows, Rooms and apps from the keyboard."), iconAsset: "PKwindowsManagement", screenshot: nil, tint: Color.orange),
            MediaProject(id: "PKbrain", title: "PKbrain", kind: "macOS app", description: language.text("Notes avec calcul inline, palette de commandes et raccourcis.", "Notes with inline calculation, command palette and shortcuts."), iconAsset: "PKbrain", screenshot: nil, tint: Color.indigo),
            MediaProject(id: "Macos_PKarchives", title: "PKarchives", kind: "macOS app", description: language.text("Archivez le Bureau vers Google Drive avec rclone.", "Archive your Desktop to Google Drive with rclone."), iconAsset: "PKarchives", screenshot: "PKarchives", tint: Color.purple),
            MediaProject(id: "PKmonitor", title: "PKMonitor", kind: "macOS app", description: language.text("CPU, GPU, RAM, réseau et disque dans la barre des menus.", "CPU, GPU, RAM, network and disk in the menu bar."), iconAsset: "PKmonitor", screenshot: "PKmonitor", tint: Color.cyan),
            MediaProject(id: "Macos_PKpowerlines", title: "PKpowerlines", kind: "macOS app", description: language.text("Affichez RAM, CPU, réseau ou batterie sur chaque écran.", "Show RAM, CPU, network or battery across your displays."), iconAsset: "PKpowerlines", screenshot: "PKpowerlines", tint: Color.green),
            MediaProject(id: "PKmac-cleanup", title: "LaunchPad", kind: "macOS app", description: language.text("Auditez les agents utilisateur et services système.", "Audit user agents and system daemons."), iconAsset: "PKmac-cleanup", screenshot: nil, tint: Color.pink),
            MediaProject(id: "Chrome_PKshortcuts", title: "PK Chrome Shortcuts", kind: "Chrome extension", description: language.text("Contrôlez onglets, navigation et split view au clavier.", "Control tabs, navigation and split view with the keyboard."), iconAsset: "PKshortcuts", screenshot: nil, tint: Color.orange)
        ]
    }

    private func featuredProjectCard(_ project: MediaProject) -> some View {
        Link(destination: project.url) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    projectIcon(project, size: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    Text(project.title).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                    Text(project.kind.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(project.tint)
                    Text(project.description).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(3)
                    Label(language.text("Étoiler sur GitHub", "Star on GitHub"), systemImage: "star.fill")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(Color.accentColor)).padding(.top, 4)
                }
                .frame(maxWidth: 340, alignment: .leading).padding(22)
                projectMedia(project, iconSize: 96).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 210, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func projectCard(_ project: MediaProject) -> some View {
        Link(destination: project.url) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    projectMedia(project, iconSize: 74).frame(maxWidth: .infinity).frame(height: 150)
                    Text(project.kind.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(.ultraThinMaterial)).padding(10)
                }
                HStack(spacing: 10) {
                    projectIcon(project, size: 30).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary).lineLimit(1)
                        Text(project.description).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(14)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func projectMedia(_ project: MediaProject, iconSize: CGFloat) -> some View {
        if let screenshot = project.screenshot, let image = bundledImage(named: screenshot, in: "ProjectScreenshots") {
            GeometryReader { proxy in
                Image(nsImage: image).resizable().scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height).clipped()
            }
        } else {
            ZStack {
                LinearGradient(colors: [project.tint.opacity(0.75), project.tint.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                projectIcon(project, size: iconSize).clipShape(RoundedRectangle(cornerRadius: iconSize / 5, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }
        }
    }

    private func projectIcon(_ project: MediaProject, size: CGFloat) -> some View {
        Group {
            if let image = bundledImage(named: project.iconAsset, in: "ProjectIcons") {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(nsImage: NSApp.applicationIconImage).resizable().interpolation(.high).scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }

    private func bundledImage(named name: String, in directory: String) -> NSImage? {
        let subdirectory = directory.isEmpty ? nil : directory
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
            ?? Bundle.main.resourceURL?.appendingPathComponent(directory).appendingPathComponent("\(name).png") else { return nil }
        return NSImage(contentsOf: url)
    }

    private func supportLink(icon: String, title: String, subtitle: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(.secondary).frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func projectRow(_ title: String, subtitle: String, icon: String, color: Color, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
                    .frame(width: 38, height: 38).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(.tertiary)
            }
            .padding(12).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func settingsPageHeader(_ title: String, _ subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 19)).foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42).background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 21, weight: .bold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            )
    }
}

private struct MediaProject: Identifiable {
    let id: String
    let title: String
    let kind: String
    let description: String
    let iconAsset: String
    let screenshot: String?
    let tint: Color
    var url: URL { URL(string: "https://github.com/mondary/\(id)")! }
}

// MARK: - Observable Wrapper

@MainActor
final class PreferencesStoreWrapper: ObservableObject {
    @Published var cookiesPath: String
    @Published var autoCopy: Bool
    @Published var cookiesBrowser: String
    @Published var downloadFolder: URL

    private let store: PreferencesStore

    init(_ store: PreferencesStore) {
        self.store = store
        self.cookiesPath = store.cookiesPath
        self.autoCopy = store.autoCopyAfterDownload
        self.cookiesBrowser = store.cookiesBrowser
        self.downloadFolder = store.downloadFolder
    }

    func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = store.downloadFolder
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.downloadFolder = url
        downloadFolder = url
    }

    func selectCookiesFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText, .data, .json]
        panel.prompt = "Select Cookies File"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.cookiesPath = url.path
        cookiesPath = url.path
    }

    func hotKeyShortcut(for action: HotKeyAction) -> HotKeyShortcut {
        store.hotKeyShortcut(for: action)
    }

    func saveAutoCopy() {
        store.autoCopyAfterDownload = autoCopy
    }

    func saveCookiesPath() {
        store.cookiesPath = cookiesPath
    }

    func saveCookiesBrowser() {
        store.cookiesBrowser = cookiesBrowser
    }

    func setHotKeyShortcut(_ shortcut: HotKeyShortcut, for action: HotKeyAction) {
        store.setHotKeyShortcut(shortcut, for: action)
        objectWillChange.send()
    }
}

private struct ShortcutRecorderControl: NSViewRepresentable {
    let shortcut: HotKeyShortcut
    let onRecord: (HotKeyShortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        ShortcutRecorderButton(shortcut: shortcut, onRecord: onRecord)
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.update(shortcut: shortcut, onRecord: onRecord)
    }
}

private final class ShortcutRecorderButton: NSButton {
    private var shortcut: HotKeyShortcut
    private var onRecord: (HotKeyShortcut) -> Void
    private var isRecording = false

    init(shortcut: HotKeyShortcut, onRecord: @escaping (HotKeyShortcut) -> Void) {
        self.shortcut = shortcut
        self.onRecord = onRecord
        super.init(frame: .zero)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 6
        focusRingType = .none
        target = self
        action = #selector(beginRecording)
        refreshTitle()
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }

    func update(shortcut: HotKeyShortcut, onRecord: @escaping (HotKeyShortcut) -> Void) {
        guard !isRecording else { return }
        self.shortcut = shortcut
        self.onRecord = onRecord
        refreshTitle()
    }

    @objc private func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        refreshTitle()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            isRecording = false
            refreshTitle()
            return
        }

        guard ![54, 55, 56, 57, 58, 59, 60, 61, 62].contains(event.keyCode) else { return }
        shortcut = HotKeyShortcut(keyCode: event.keyCode, modifiers: event.modifierFlags)
        isRecording = false
        onRecord(shortcut)
        refreshTitle()
    }

    private func refreshTitle() {
        let text = isRecording ? "Press shortcut" : shortcut.displayText
        attributedTitle = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
            ]
        )
        layer?.backgroundColor = (isRecording ? NSColor.controlAccentColor.withAlphaComponent(0.14) : NSColor.white.withAlphaComponent(0.08)).cgColor
    }
}
