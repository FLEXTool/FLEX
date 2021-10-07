// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FLEX",
  platforms: [
    .iOS(.v9)
  ],
  products: [
    .library(
      name: "FLEX",
      targets: ["FLEX"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "FLEX",
      dependencies: [],
      path: ".",
      exclude: [
        "include",
        "LICENSE",
        "CONTRIBUTING.md",
        "FLEX.podspec",
        "README.md",
        "Example",
        "FLEXTests",
        "Package.swift",
        "Graphics",
        "Classes/Info.plist",
        "Classes/GlobalStateExplorers/DatabaseBrowser/LICENSE",
        "Classes/Network/PonyDebugger/LICENSE",
        "Classes/Utility/APPLE_LICENSE",
        "Classes/GlobalStateExplorers/SystemLog/",
        "Classes/GlobalStateExplorers/Keychain/SSKeychain_LICENSE"
      ],
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath("."),
        .headerSearchPath("include")
      ],
      linkerSettings: [
        .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("AppKit", .when(platforms: [.macOS])),
      ]
    )
  ]
)











