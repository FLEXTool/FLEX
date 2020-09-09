// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FLEX",
    products: [
        .library(name: "FLEX", targets: ["FLEX"])
    ],
    targets: [
        .target(
            name: "FLEX",
            path: "Classes",
            exclude: [
                "GlobalStateExplorers/SystemLog/LLVM_LICENSE.TXT",
                "Network/PonyDebugger/LICENSE",
                "Utility/APPLE_LICENSE",
                "GlobalStateExplorers/Keychain/SSKeychain_LICENSE",
                "Info.plist",
                "GlobalStateExplorers/DatabaseBrowser/LICENSE"
            ],
            publicHeadersPath: "./",
            cSettings: [
                .headerSearchPath("Core"),
                .headerSearchPath("Core/Controllers/"),
                .headerSearchPath("Core/Views"),
                .headerSearchPath("Core/Views/Cells"),
                .headerSearchPath("Core/Views/Carousel"),
                .headerSearchPath("Editing"),
                .headerSearchPath("Editing/ArgumentInputViews"),
                .headerSearchPath("ExplorerInterface"),
                .headerSearchPath("ExplorerInterface/Bookmarks"),
                .headerSearchPath("ExplorerInterface/Tabs"),
                .headerSearchPath("GlobalStateExplorers"),
                .headerSearchPath("GlobalStateExplorers/DatabaseBrowser"),
                .headerSearchPath("GlobalStateExplorers/FileBrowser"),
                .headerSearchPath("GlobalStateExplorers/Globals"),
                .headerSearchPath("GlobalStateExplorers/Keychain"),
                .headerSearchPath("GlobalStateExplorers/RuntimeBrowser"),
                .headerSearchPath("GlobalStateExplorers/RuntimeBrowser/DataSources"),
                .headerSearchPath("GlobalStateExplorers/SystemLog"),
                .headerSearchPath("Manager"),
                .headerSearchPath("Manager/Private"),
                .headerSearchPath("Network"),
                .headerSearchPath("Network/PonyDebugger"),
                .headerSearchPath("ObjectExplorers"),
                .headerSearchPath("ObjectExplorers/Sections"),
                .headerSearchPath("ObjectExplorers/Sections/Shortcuts"),
                .headerSearchPath("Toolbar"),
                .headerSearchPath("Utility"),
                .headerSearchPath("Utility/Categories"),
                .headerSearchPath("Utility/Keyboard"),
                .headerSearchPath("Utility/Runtime"),
                .headerSearchPath("Utility/Runtime/Objc"),
                .headerSearchPath("Utility/Runtime/Objc/Reflection"),
                .headerSearchPath("ViewHierarchy"),
                .headerSearchPath("ViewHierarchy/SnapshotExplorer"),
                .headerSearchPath("ViewHierarchy/SnapshotExplorer/Scene"),
                .headerSearchPath("ViewHierarchy/TreeExplorer")
            ]
        )
    ]
)
