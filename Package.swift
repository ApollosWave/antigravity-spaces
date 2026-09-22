// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AntigravitySpaces",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "antigravity-spaces", targets: ["AntigravitySpaces"])
    ],
    targets: [
        .executableTarget(
            name: "AntigravitySpaces",
            path: "Sources/AntigravitySpaces"
        )
    ]
)
