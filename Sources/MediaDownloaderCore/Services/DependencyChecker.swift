import Foundation

public struct DependencyStatus: Equatable {
    public let missingTools: [String]

    public var isSatisfied: Bool {
        missingTools.isEmpty
    }
}

public enum DependencyChecker {
    public static let installPrompt = "Install ffmpeg and yt-dlp on macOS. Prefer Homebrew if available. Verify both commands work: ffmpeg -version and yt-dlp --version."

    public static func check() -> DependencyStatus {
        let missing = ["ffmpeg", "yt-dlp"].filter { executablePath(named: $0) == nil }
        return DependencyStatus(missingTools: missing)
    }

    public static func version(ofTool tool: String) -> String? {
        guard let path = executablePath(named: tool) else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        process.environment = processEnvironment
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines).first
    }

    @discardableResult
    public static func updateYTDLP() -> String {
        if let brew = executablePath(named: "brew"),
           let ytdlp = executablePath(named: "yt-dlp"),
           ytdlp.hasPrefix(URL(fileURLWithPath: brew).deletingLastPathComponent().path) {
            return run(brew, ["upgrade", "yt-dlp"])
        }
        if let ytdlp = executablePath(named: "yt-dlp") {
            return run(ytdlp, ["-U"])
        }
        return "yt-dlp is not installed"
    }

    private static func run(_ executable: String, _ arguments: [String]) -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        process.environment = processEnvironment
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error.localizedDescription
        }
        let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (output + error).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func executablePath(named tool: String) -> String? {
        let fileManager = FileManager.default

        for directory in searchDirectories {
            let path = URL(fileURLWithPath: directory).appendingPathComponent(tool).path
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
    }

    public static var processEnvironment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = searchDirectories.joined(separator: ":")
        return environment
    }

    private static var searchDirectories: [String] {
        let pathDirectories = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)

        let commonDirectories = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/opt/local/bin",
            "/usr/bin",
            "/bin"
        ]

        var result: [String] = []
        for directory in pathDirectories + commonDirectories where !directory.isEmpty && !result.contains(directory) {
            result.append(directory)
        }
        return result
    }
}
