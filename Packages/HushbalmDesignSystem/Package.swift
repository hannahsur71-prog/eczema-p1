// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HushbalmDesignSystem",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HushbalmDesignSystem", targets: ["HushbalmDesignSystem"])
    ],
    targets: [
        .target(
            name: "HushbalmDesignSystem",
            path: "Sources/HushbalmDesignSystem",
            resources: [.process("Resources")]
        )
    ]
)
