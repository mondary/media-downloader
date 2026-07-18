import Foundation

final class PreferencesStore {
    private let downloadFolderKey = "downloadFolderPath"
    private let cookiesPathKey = "cookiesFilePath"
    private let cookiesBrowserKey = "cookiesBrowser"
    private let hotKeyPrefix = "hotKeyShortcut."
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var downloadFolder: URL {
        get {
            if let path = defaults.string(forKey: downloadFolderKey), !path.isEmpty {
                return URL(fileURLWithPath: path, isDirectory: true)
            }

            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            return downloads
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads", isDirectory: true)
        }
        set {
            defaults.set(newValue.path, forKey: downloadFolderKey)
        }
    }

    var cookiesPath: String {
        get { defaults.string(forKey: cookiesPathKey) ?? "" }
        set { defaults.set(newValue, forKey: cookiesPathKey) }
    }

    var cookiesBrowser: String {
        get { defaults.string(forKey: cookiesBrowserKey) ?? "chrome" }
        set { defaults.set(newValue, forKey: cookiesBrowserKey) }
    }

    var autoCopyAfterDownload: Bool {
        get { defaults.object(forKey: "autoCopyAfterDownload") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoCopyAfterDownload") }
    }

    func hotKeyShortcut(for action: HotKeyAction) -> HotKeyShortcut {
        let key = hotKeyKey(for: action)
        guard let data = defaults.data(forKey: key),
              let shortcut = try? JSONDecoder().decode(HotKeyShortcut.self, from: data) else {
            return action.defaultShortcut
        }

        return shortcut
    }

    func setHotKeyShortcut(_ shortcut: HotKeyShortcut, for action: HotKeyAction) {
        let key = hotKeyKey(for: action)
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: key)
        NotificationCenter.default.post(name: .mediaDownloaderHotKeysDidChange, object: action)
    }

    private func hotKeyKey(for action: HotKeyAction) -> String {
        hotKeyPrefix + action.rawValue
    }
}
