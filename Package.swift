// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FLEX",
    platforms: [.iOS(.v8)],
    products: [
        .library(name: "FLEX", targets: ["FLEX"])
    ],
    targets: [
        .target(
            name: "FLEX",
            path: "Classes",
            cSettings: [.headerSearchPath("**")]
        ),
        .testTarget(
            name: "FLEXTestsMethodsList",
            dependencies: ["FLEX"],
            path: "FLEXTests",
            cSettings: [.headerSearchPath("../Classes/**")]
        )
    ]
)
