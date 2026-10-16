// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Paperboy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Paperboy",
            path: "Sources/Paperboy"
        )
    ]
)
