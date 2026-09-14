// swift-tools-version:5.9
// Test-only package: compiles LinkRouter's pure logic (rule matching, host
// matching, deep-link decoding, defaults coding) into a module so `swift test`
// can exercise it without an Xcode test target. The app itself is built from
// LinkRouter.xcodeproj as usual.
import PackageDescription

let package = Package(
    name: "LinkRouterCore",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "LinkRouterCore",
            path: "LinkRouter",
            sources: [
                "Models/Rule.swift",
                "Extensions/URLExtensions.swift",
                "Extensions/Array+RawRepresentable.swift",
            ]
        ),
        .testTarget(
            name: "LinkRouterCoreTests",
            dependencies: ["LinkRouterCore"],
            path: "Tests"
        ),
    ]
)
