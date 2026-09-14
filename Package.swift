// swift-tools-version:5.9
// Test-only package: compiles the app's pure logic (rule matching, host
// matching, URL unwrapping, source attribution) into a module so `swift test`
// runs WITHOUT Xcode. The app itself is still built from the .xcodeproj.
//
// Two constraints learned the hard way, do not "simplify" these away:
//  - `exclude:` must list every non-source entry under the target path, or
//    SwiftPM tries to process Assets.xcassets with `actool`, which only
//    exists inside Xcode.app. Build fails with a confusing decode error.
//  - Tests use swift-testing (`import Testing`), NOT XCTest. XCTest ships
//    with Xcode; it is absent from Command Line Tools.
import PackageDescription

let package = Package(
    name: "LinkRouterCore",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "LinkRouterCore",
            path: "LinkRouter",
            exclude: [
                "Assets.xcassets",
                "Preview Content",
                "Info.plist",
                "LinkRouter.entitlements",
                "LinkRouter.icns",
                "LinkRouterApp.swift",
                "LinkRouterApplication.swift",
                "LinkRouterWindow.swift",
                "main.swift",
                "Models/BrowserUtil.swift",
                "Modifiers",
                "Views",
                "Extensions/View+FocusEffectDisabled.swift",
                "Extensions/View+If.swift",
                "Extensions/View+OnKeyPress.swift",
                "Extensions/View+ScrollEdgeDisabled.swift",
                "Extensions/View+Tooltip.swift",
            ],
            sources: [
                "Models/Rule.swift",
                "Extensions/URLExtensions.swift",
                "Extensions/URLUnwrapping.swift",
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
