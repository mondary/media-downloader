#if DEBUG
import AppKit
import MediaDownloaderCore
import SwiftUI

// Offscreen capture of production views, never the user's desktop or persisted history.
@MainActor
enum PromoCapture {
    static func run() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "--capture-promo"),
              arguments.indices.contains(flag + 1) else {
            fputs("usage: PKMediaDownloader --capture-promo /path/to/screenshots\n", stderr)
            return
        }
        let directory = URL(fileURLWithPath: arguments[flag + 1], isDirectory: true)
        let suite = "com.pkmediadownloader.promo.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("/Users/demo/Downloads", forKey: "downloadFolderPath")

        let thumbnails = ["thumb-bbb.jpg", "thumb-sintel.jpg", "thumb-tears.jpg"]
            .map { directory.appendingPathComponent($0).path }
        let items = [
            DownloadItem(sourceURL: "https://www.youtube.com/watch?v=aqz-KE-bpKQ", title: "Big Buck Bunny", filePath: "/Users/demo/Downloads/Big-Buck-Bunny.mp4", thumbnailPath: thumbnails[0], createdAt: .now),
            DownloadItem(sourceURL: "https://www.youtube.com/watch?v=eRsGyueVLvQ", title: "Sintel", filePath: "/Users/demo/Downloads/Sintel.mp4", thumbnailPath: thumbnails[1], createdAt: .now.addingTimeInterval(-3600)),
            DownloadItem(sourceURL: "https://www.youtube.com/watch?v=R6MlUcmOul8", title: "Tears of Steel", filePath: "/Users/demo/Downloads/Tears-of-Steel.mp4", thumbnailPath: thumbnails[2], createdAt: .now.addingTimeInterval(-7200))
        ]
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.appearance = NSAppearance(named: .aqua)
        let model = AppModel(preferences: PreferencesStore(defaults: defaults), previewHistory: items)
        let size = NSSize(width: 940, height: 450)
        let window = NSWindow(contentRect: NSRect(origin: NSPoint(x: -10000, y: -10000), size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "PKMediaDownloader"
        window.appearance = NSAppearance(named: .aqua)
        let hosting = NSHostingView(rootView: ContentView(model: model).frame(width: size.width, height: size.height))
        window.contentView = hosting
        window.orderFront(nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        hosting.layoutSubtreeIfNeeded()

        capture(hosting, to: directory.appendingPathComponent("01-app-history.png"))
        window.orderOut(nil)

        for (appearance, suffix) in [(NSAppearance.Name.aqua, "light"), (.darkAqua, "dark")] {
            for section in [MediaSettingsSection.general, .about, .support, .library] {
                let settings = SettingsWindowController(
                    preferences: PreferencesStore(defaults: defaults),
                    initialSection: section,
                    onCheckForUpdates: {}
                )
                if let settingsWindow = settings.window, let content = settingsWindow.contentView {
                    settingsWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))
                    settingsWindow.appearance = NSAppearance(named: appearance)
                    settingsWindow.orderFront(nil)
                    RunLoop.current.run(until: Date().addingTimeInterval(0.3))
                    content.layoutSubtreeIfNeeded()
                    let filename = section == .general && suffix == "dark"
                        ? "02-settings.png" : "settings-\(section.rawValue)-\(suffix).png"
                    capture(content, to: directory.appendingPathComponent(filename))
                    settingsWindow.orderOut(nil)
                }
            }
        }
    }

    private static func capture(_ view: NSView, to output: URL) {
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
        do {
            try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: output)
            print("Captured native view with fictitious data: \(output.path)")
        } catch {
            fputs("Capture failed: \(error)\n", stderr)
        }
    }
}
#endif
