// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApiDiffViewer",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ApiDiffViewer",
            targets: ["AppProvider"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftty/XcodeGenBinary.git", from: "2.43.0"),
        .package(url: "https://github.com/swiftty/SwiftLintBinary.git", exact: "0.59.1-patch"),
    ],
    targets: [
        .target(
            name: "AppProvider",
            dependencies: [
                "RootPage"
            ]
        ),
        .target(
            name: "RootPage",
            dependencies: [
                "SidePanePage"
            ]
        ),
        .target(
            name: "SidePanePage"
        )
    ]
)

extension Optional {
    static func += <T>(lhs: inout Self, rhs: [T]) where Wrapped == [T] {
        lhs = (lhs ?? []) + rhs
    }
}

package.targets.forEach { target in
    if target.type != .macro {
        target.swiftSettings += [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault")
        ]
    }
    target.plugins += [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintBinary")
    ]
}
