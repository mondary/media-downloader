// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PKMediaDownloader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PKMediaDownloader", targets: ["MediaDownloader"]),
        .executable(name: "pkmd", targets: ["pkmd"]),
        .library(name: "MediaDownloaderCore", targets: ["MediaDownloaderCore"])
    ],
    targets: [
        .target(name: "MediaDownloaderCore"),
        .executableTarget(name: "MediaDownloader", dependencies: ["MediaDownloaderCore"]),
        .executableTarget(name: "pkmd", dependencies: ["MediaDownloaderCore"]),
        .testTarget(
            name: "MediaDownloaderTests",
            dependencies: ["MediaDownloader", "MediaDownloaderCore"]
        )
    ]
)
