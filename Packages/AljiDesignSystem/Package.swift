// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AljiDesignSystem",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AljiDesignSystem", targets: ["AljiDesignSystem"])
    ],
    targets: [
        .target(
            name: "AljiDesignSystem",
            path: "Sources/AljiDesignSystem",
            resources: [.process("Resources")]
        )
    ]
)
