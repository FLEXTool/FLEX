// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FLEX",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "FLEX", targets: ["FLEX"])
    ],
    targets: [
        .target(
            name: "FLEX",
            path: "Classes",
            exclude: [
                "Info.plist",
                "Utility/APPLE_LICENSE",
                "Network/PonyDebugger/LICENSE",
                "GlobalStateExplorers/DatabaseBrowser/LICENSE",
                "GlobalStateExplorers/Keychain/SSKeychain_LICENSE",
                "GlobalStateExplorers/SystemLog/LLVM_LICENSE.TXT",
            ],
            publicHeadersPath: "Headers",
            cSettings: [
                // .unsafeFlags([
                //     "-Wno-deprecated-declarations",
                //     "-Wno-strict-prototypes",
                //     "-Wno-unsupported-availability-guard",
                // ]),
                .headerSearchPath("Classes"),
                .headerSearchPath("Core"),
                .headerSearchPath("Core/Controllers"),
                .headerSearchPath("Core/Views"),
                .headerSearchPath("Core/Views/Cells"),
                .headerSearchPath("Core/Views/Carousel"),
                .headerSearchPath("ObjectExplorers"),
                .headerSearchPath("ObjectExplorers/Sections"),
                .headerSearchPath("ObjectExplorers/Sections/Shortcuts"),
                .headerSearchPath("Network"),
                .headerSearchPath("Network/PonyDebugger"),
                .headerSearchPath("Toolbar"),
                .headerSearchPath("Manager"),
                .headerSearchPath("Manager/Private"),
                .headerSearchPath("Editing"),
                .headerSearchPath("Editing/ArgumentInputViews"),
                .headerSearchPath("Headers"),
                .headerSearchPath("ExplorerInterface"),
                .headerSearchPath("ExplorerInterface/Tabs"),
                .headerSearchPath("ExplorerInterface/Bookmarks"),
                .headerSearchPath("GlobalStateExplorers"),
                .headerSearchPath("GlobalStateExplorers/Globals"),
                .headerSearchPath("GlobalStateExplorers/Keychain"),
                .headerSearchPath("GlobalStateExplorers/FileBrowser"),
                .headerSearchPath("GlobalStateExplorers/SystemLog"),
                .headerSearchPath("GlobalStateExplorers/DatabaseBrowser"),
                .headerSearchPath("GlobalStateExplorers/RuntimeBrowser"),
                .headerSearchPath("GlobalStateExplorers/RuntimeBrowser/DataSources"),
                .headerSearchPath("ViewHierarchy"),
                .headerSearchPath("ViewHierarchy/SnapshotExplorer"),
                .headerSearchPath("ViewHierarchy/SnapshotExplorer/Scene"),
                .headerSearchPath("ViewHierarchy/TreeExplorer"),
                .headerSearchPath("Utility"),
                .headerSearchPath("Utility/Runtime"),
                .headerSearchPath("Utility/Runtime/Objc"),
                .headerSearchPath("Utility/Runtime/Objc/Reflection"),
                .headerSearchPath("Utility/Categories"),
                .headerSearchPath("Utility/Categories/Private"),
                .headerSearchPath("Utility/Keyboard")
            ]
        )
    ]
)
