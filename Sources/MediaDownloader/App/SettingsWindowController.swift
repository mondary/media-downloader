import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let preferences: PreferencesStore
    private let onCheckForUpdates: () -> Void

    init(preferences: PreferencesStore, onCheckForUpdates: @escaping () -> Void) {
        self.preferences = preferences
        self.onCheckForUpdates = onCheckForUpdates

        let contentSize = NSSize(width: 520, height: 520)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "PKMediaDownloader — Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(calibratedWhite: 0.11, alpha: 1)
        window.minSize = contentSize
        window.maxSize = NSSize(width: 520, height: 800)
        window.collectionBehavior = [.moveToActiveSpace]
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: window)

        window.delegate = self
        let hosting = NSHostingView(
            rootView: SettingsRootView(preferences: preferences, onCheckForUpdates: onCheckForUpdates)
                .frame(width: contentSize.width, height: contentSize.height)
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

// MARK: - SwiftUI Settings Root

private struct SettingsRootView: View {
    @ObservedObject var preferences: PreferencesStoreWrapper
    let onCheckForUpdates: () -> Void
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var engineVersion: String?
    @State private var isUpdatingEngine = false
    @State private var engineUpdateResult: String?
    private let statusTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    init(preferences: PreferencesStore, onCheckForUpdates: @escaping () -> Void) {
        self.preferences = PreferencesStoreWrapper(preferences)
        self.onCheckForUpdates = onCheckForUpdates
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                appSection
                engineSection
                downloadSection
                socialMediaSection
                accessibilitySection
                shortcutsSection
                linksSection
            }
            .padding(24)
        }
        .background(Color(NSColor(calibratedWhite: 0.11, alpha: 1)))
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
    }

    // MARK: - App Section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PKMediaDownloader")
                        .font(.title3.weight(.semibold))
                                        Text("v1.2026.10 — Native macOS video downloader")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Check for Updates") { onCheckForUpdates() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(14)
            .background(cardBackground)
        }
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

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Links")
                .font(.headline)

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/pixel-point/media-downloader")!) {
                    Label("Original Project (GitHub)", systemImage: "arrow.up.right.square")
                        .font(.subheadline)
                }

                Spacer()

                Link(destination: URL(string: "https://github.com/mondary/media-downloader")!) {
                    Label("PKMediaDownloader (GitHub)", systemImage: "arrow.up.right.square")
                        .font(.subheadline)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
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
