// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-keychain-kit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "KeychainKit", targets: ["KeychainKit"])
    ],
    targets: [
        .target(
            name: "KeychainKit",
            path: "Sources/KeychainKit"
        ),
        .testTarget(
            name: "KeychainKitTests",
            dependencies: ["KeychainKit"],
            path: "Tests/KeychainKitTests"
        )
    ]
)
