# FLEX for macOS

A native **AppKit** port of [FLEX](../README.md), the in-app debugging and exploration tool.
Embed it in any Cocoa (AppKit) app to inspect and modify the running app from the inside.

It reuses FLEX's platform-independent core (runtime reflection, heap enumeration, network
observer/recorder, keychain, SQLite) from `../Classes`, and adds a new AppKit interface in `FLEXMac/`.

## Features

| Feature | iOS FLEX | macOS |
| --- | --- | --- |
| Floating toolbar (Menu, Views, Select, Network, Close) | ✅ | ✅ `NSPanel` |
| Select a view by hovering/clicking it, with on-screen highlight | ✅ | ✅ (Esc cancels) |
| View hierarchy of all windows, filterable, with highlight | ✅ | ✅ `NSOutlineView` |
| Object explorer: properties, ivars, methods, class methods, protocols, hierarchy | ✅ | ✅ with class scope + "include superclasses" |
| Edit properties and ivars (objects, numbers, BOOL, structs like `NSRect`) | ✅ | ✅ |
| Call methods with arguments | ✅ | ✅ |
| Type-specific shortcuts (views, windows, view controllers, menus, collections, data, images…) | ✅ | ✅ AppKit equivalents |
| Network history (NSURLSession/NSURLConnection), request/response details, cURL | ✅ | ✅ |
| Heap objects by class, live instances, references to an object | ✅ | ✅ |
| Runtime browser (loaded images → classes), subclasses | ✅ | ✅ |
| File browser, plist/JSON/image/text previews, SQLite browser | ✅ | ✅ |
| User defaults viewer/editor | ✅ | ✅ |
| Keychain, cookies, system log | ✅ | ✅ (log via `OSLogStore`) |
| Explore by address / class name, custom global entries | ✅ | ✅ |
| 3D view snapshot, Realm browser, Firebase viewer | ✅ | ❌ not ported |

## Requirements

macOS 12+, Xcode 15+ (developed with Xcode 27). Objective-C and Swift apps both work.

## Building

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`
(the generated `FLEXMac.xcodeproj` is checked in, so XcodeGen is only needed if you change `project.yml`).

```sh
cd macOS
xcodegen generate                       # optional, regenerates FLEXMac.xcodeproj
open FLEXMac.xcodeproj                  # run the FLEXMacExample scheme
# or from the command line:
xcodebuild -project FLEXMac.xcodeproj -scheme FLEXMacExample build
xcodebuild -project FLEXMac.xcodeproj -scheme FLEXMacExample test
```

The `FLEXMac` target builds `FLEX.framework` (module name `FLEX`).

## Usage

Embed `FLEX.framework` in your app (Debug builds only is recommended), then:

```objc
#import <FLEX/FLEX.h>

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
#if DEBUG
    FLEXManager.sharedManager.networkDebuggingEnabled = YES; // optional
    [FLEXManager.sharedManager installMainMenuItem];          // Window ▸ Explore with FLEX
#endif
}
```

```swift
import FLEX

FLEXManager.shared.showExplorer()
```

- **⌥⌘F** toggles FLEX while the app is active (configure with `keyboardShortcutKey`,
  `keyboardShortcutModifiers`, or disable with `keyboardShortcutEnabled = NO`).
- `showExplorer`, `hideExplorer`, `toggleExplorer`, `showGlobals`, `showViewHierarchy`,
  `beginViewSelection`, `showNetworkHistory`, `presentObjectExplorer:`, `presentTool:`.
- `registerGlobalEntryWithName:objectFutureBlock:` / `…viewControllerFutureBlock:` add your own
  entries to the main menu, as on iOS.

In the explorer window: **double-click** or **Return** opens a row, **right-click** shows more
actions (edit, copy, explore type, list references…), **⌘[** goes back, **⌘R** refreshes,
**⌘C** copies the selected row.

## Injecting FLEX without recompiling (FLEX Injector)

`FLEX.framework`'s binary doubles as an injectable dylib. When it is loaded into a
host process via `DYLD_INSERT_LIBRARIES` **and** the `FLEX_AUTO_SHOW` environment
variable is set, a constructor waits for the app to finish launching and then attaches
FLEX to it (`installMainMenuItem`, and `showExplorer` when `FLEX_AUTO_SHOW=1`). Without
`FLEX_AUTO_SHOW` the constructor does nothing, so linking FLEX normally is unaffected.

On injection FLEX also turns on network recording automatically (set `FLEX_NO_NETWORK=1`
to opt out), and its windows float above the host app and keep working even while the
host runs a modal alert.

The **FLEX Injector** app (the `FLEXInjector` scheme) is a picker for doing this against
your own debuggable builds:

- Lists apps from `/Applications` and `~/Applications`, plus any you add with **Add App…**.
- For each app it reports whether launch-time injection will actually work, by reading the
  code signature with `codesign`:
  - **Injectable** — no hardened runtime (typical debug build), or hardened runtime with
    library validation disabled.
  - **Needs library validation disabled** — hardened runtime: the inserted dylib must be
    signed by the same team, or re-sign the app with
    `com.apple.security.cs.disable-library-validation`.
  - **Restricted** — hardened runtime without `com.apple.security.cs.allow-dyld-environment-variables`:
    dyld strips `DYLD_*`, so launch-time injection is not possible.
  - **SIP protected** — Apple system/platform binary: `DYLD_*` is stripped.
- **Launch with FLEX** runs the app's executable directly (via `NSTask`, bypassing Launch
  Services, which may strip `DYLD_*`) with `DYLD_INSERT_LIBRARIES` set to the bundled FLEX
  binary and `FLEX_AUTO_SHOW` set. The child's stdout/stderr (including any dyld errors)
  stream into the console at the bottom of the window.

This is the same mechanism as running `DYLD_INSERT_LIBRARIES=… FLEX_AUTO_SHOW=1 ./MyApp.app/Contents/MacOS/MyApp`
from a terminal. It only works for apps you can launch yourself; it does not attach to
already-running processes and cannot defeat SIP, the hardened runtime's dyld-variable
opt-out, or library validation.

### Command line

```sh
DYLD_INSERT_LIBRARIES="/path/to/FLEX.framework/Versions/A/FLEX" \
FLEX_AUTO_SHOW=1 \
"/path/to/MyDebugApp.app/Contents/MacOS/MyDebugApp"
```

## Notes

- FLEX calls property getters to show value previews, exactly like iOS FLEX. If a getter
  misbehaves, uncheck **Value previews** in the object explorer.
- The keychain view lists generic password items visible to the app; on macOS this can include
  items from the login keychain, and revealing a password may show a system permission prompt.
- Shared sources in `../Classes` have small `#if TARGET_OS_OSX` guards so they compile for both
  platforms; the iOS build is unaffected.
