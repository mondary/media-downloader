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

        let items = [
            DownloadItem(sourceURL: "https://www.youtube.com/watch?v=demo-nord", title: "Coastline / study", filePath: "/Users/demo/Downloads/Coastline.mp4", thumbnailPath: nil, createdAt: .now),
            DownloadItem(sourceURL: "https://vimeo.com/000000", title: "Field notes", filePath: "/Users/demo/Downloads/Field-notes.mp4", thumbnailPath: nil, createdAt: .now.addingTimeInterval(-3600)),
            DownloadItem(sourceURL: "https://www.youtube.com/watch?v=demo-city", title: "City at dusk", filePath: "/Users/demo/Downloads/City-at-dusk.mp4", thumbnailPath: nil, createdAt: .now.addingTimeInterval(-7200))
        ]
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.appearance = NSAppearance(named: .darkAqua)
        let model = AppModel(preferences: PreferencesStore(defaults: defaults), previewHistory: items)
        let size = NSSize(width: 940, height: 450)
        let window = NSWindow(contentRect: NSRect(origin: NSPoint(x: -10000, y: -10000), size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "PKMediaDownloader"
        window.appearance = NSAppearance(named: .darkAqua)
        let hosting = NSHostingView(rootView: ContentView(model: model).frame(width: size.width, height: size.height))
        window.contentView = hosting
        window.orderFront(nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        hosting.layoutSubtreeIfNeeded()

        capture(hosting, to: directory.appendingPathComponent("01-app-history.png"))
        window.orderOut(nil)

        let settings = SettingsWindowController(preferences: PreferencesStore(defaults: defaults), onCheckForUpdates: {})
        if let settingsWindow = settings.window, let content = settingsWindow.contentView {
            settingsWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))
            settingsWindow.appearance = NSAppearance(named: .darkAqua)
            settingsWindow.orderFront(nil)
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            content.layoutSubtreeIfNeeded()
            capture(content, to: directory.appendingPathComponent("02-settings.png"))
            settingsWindow.orderOut(nil)
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
