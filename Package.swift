// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PKMediaDownloader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PKMediaDownloader", targets: ["MediaDownloader"])
    ],
    targets: [
        .executableTarget(name: "MediaDownloader"),
        .testTarget(name: "MediaDownloaderTests", dependencies: ["MediaDownloader"])
    ]
)
