import AppKit
import MediaDownloaderCore
import UserNotifications

final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "PKMediaDownloader")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
            button.imagePosition = .imageOnly
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        rebuildMenu()
        observeDownloadNotifications()
        requestNotificationPermission()
    }

    private func observeDownloadNotifications() {
        NotificationCenter.default.addObserver(forName: .downloadStarted, object: nil, queue: .main) { [weak self] _ in
            self?.setDownloading(true)
        }
        NotificationCenter.default.addObserver(forName: .downloadCompleted, object: nil, queue: .main) { [weak self] notification in
            self?.setDownloading(false)
            self?.showSuccess()
            if let title = notification.userInfo?["title"] as? String {
                self?.sendNotification(title: "Download Complete", body: title)
            }
        }
        NotificationCenter.default.addObserver(forName: .downloadProgressed, object: nil, queue: .main) { [weak self] notification in
            self?.setDownloadProgress(notification.object as? DownloadProgress)
        }
        NotificationCenter.default.addObserver(forName: .downloadFailed, object: nil, queue: .main) { [weak self] notification in
            self?.setDownloading(false)
            self?.showError()
            if let error = notification.userInfo?["error"] as? String {
                self?.sendNotification(title: "Download Failed", body: error)
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func setDownloading(_ active: Bool) {
        guard let button = statusItem?.button else { return }

        if active {
            let image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: "Downloading")
            image?.isTemplate = false
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
            button.contentTintColor = .systemBlue

        } else {
            let image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "PKMediaDownloader")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
            button.contentTintColor = nil
            button.title = ""
        }
    }

    private func setDownloadProgress(_ progress: DownloadProgress?) {
        guard let button = statusItem?.button, let progress else { return }

        let playlistPosition = progress.playlistPosition.map { "\($0) · " } ?? ""
        button.title = " \(playlistPosition)\(progress.progressLabel)"
        button.toolTip = "\(progress.title) · \(progress.progressLabel)"
        button.setAccessibilityLabel("Downloading \(progress.title), \(playlistPosition)\(progress.progressLabel)")
    }

    func showSuccess() {
        guard let button = statusItem?.button else { return }

        let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Downloaded")
        image?.isTemplate = false
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.contentTintColor = .systemGreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, let btn = self.statusItem?.button else { return }
            let img = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "PKMediaDownloader")
            img?.isTemplate = true
            img?.size = NSSize(width: 18, height: 18)
            btn.image = img
            btn.contentTintColor = nil
        }
    }

    func showError() {
        guard let button = statusItem?.button else { return }

        let image = NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: "Error")
        image?.isTemplate = false
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.contentTintColor = .systemRed

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, let btn = self.statusItem?.button else { return }
            let img = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "PKMediaDownloader")
            img?.isTemplate = true
            img?.size = NSSize(width: 18, height: 18)
            btn.image = img
            btn.contentTintColor = nil
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let language = MediaSettingsLanguage.current
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let versionItem = NSMenuItem(title: "PKMediaDownloader v\(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(.separator())
        let mainWindowTitle = language.text("Ouvrir la fenêtre principale", "Open Main Window")
        let mainWindowItem = NSMenuItem(title: mainWindowTitle, action: #selector(openMainWindow), keyEquivalent: "o")
        mainWindowItem.image = menuSymbol("macwindow", description: mainWindowTitle)
        menu.addItem(mainWindowItem)

        let settingsTitle = language.text("Réglages…", "Settings…")
        let settingsItem = NSMenuItem(title: settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.image = menuSymbol("gearshape", description: settingsTitle)
        menu.addItem(settingsItem)

        let supportTitle = language.text("Soutenir sur Ko-fi", "Support on Ko-fi")
        let supportItem = NSMenuItem(title: supportTitle, action: #selector(openSupportPage), keyEquivalent: "")
        supportItem.image = kofiMenuImage()
        menu.addItem(supportItem)

        menu.addItem(.separator())
        let quitTitle = language.text("Quitter", "Quit")
        let quitItem = NSMenuItem(title: quitTitle, action: #selector(quitApp), keyEquivalent: "q")
        quitItem.image = menuSymbol("power", description: quitTitle)
        menu.addItem(quitItem)
        for item in menu.items where item.action != nil {
            item.target = self
        }
        statusMenu = menu
    }

    private func menuSymbol(_ name: String, description: String) -> NSImage? {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: description) else { return nil }
        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = true
        return image
    }

    private func kofiMenuImage() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "kofi-logo", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return menuSymbol("cup.and.saucer.fill", description: "Ko-fi")
        }
        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = false
        return image
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            guard let statusMenu else { return }
            statusItem?.menu = statusMenu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
            return
        }
        openMainWindow()
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .showMainWindow, object: nil)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }

    @objc private func openSupportPage() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/pouark")!)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let showMainWindow = Notification.Name("PKMediaDownloaderShowMainWindow")
    static let showSettings = Notification.Name("PKMediaDownloaderShowSettings")
    static let downloadStarted = Notification.Name("PKMediaDownloaderDownloadStarted")
    static let downloadProgressed = Notification.Name("PKMediaDownloaderDownloadProgressed")
    static let downloadCompleted = Notification.Name("PKMediaDownloaderDownloadCompleted")
    static let downloadFailed = Notification.Name("PKMediaDownloaderDownloadFailed")
}
