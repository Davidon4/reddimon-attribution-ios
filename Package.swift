// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ReddimonAttribution",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ReddimonAttribution",
            targets: ["ReddimonAttribution"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReddimonAttribution",
            dependencies: [],
            path: "Attribution"),
        .testTarget(
            name: "ReddimonAttributionTests",
            dependencies: ["ReddimonAttribution"],
            path: "Tests")
    ]
)