# FLEX
[![CocoaPods](https://img.shields.io/cocoapods/v/FLEX.svg)](https://cocoapods.org/?q=FLEX)
 [![CocoaPods](https://img.shields.io/cocoapods/l/FLEX.svg)](https://github.com/Flipboard/FLEX/blob/master/LICENSE)
 [![CocoaPods](https://img.shields.io/cocoapods/p/FLEX.svg)]()
 [![Twitter: @ryanolsonk](https://img.shields.io/badge/contact-@ryanolsonk-blue.svg?style=flat)](https://twitter.com/ryanolsonk)
 [![Build Status](https://travis-ci.org/Flipboard/FLEX.svg?branch=master)](https://travis-ci.org/Flipboard/FLEX)
 [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

FLEX (Flipboard Explorer) is a set of in-app debugging and exploration tools for iOS development. When presented, FLEX shows a toolbar that lives in a window above your application. From this toolbar, you can view and modify nearly every piece of state in your running application.

<img alt="Demo" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70185687-e842c800-16af-11ea-8ef9-9e071380a462.gif>


## Give Yourself Debugging Superpowers
- Inspect and modify views in the hierarchy.
- See the properties and ivars on any object.
- Dynamically modify many properties and ivars.
- Dynamically call instance and class methods.
- Observe detailed network request history with timing, headers, and full responses.
- Add your own simulator keyboard shortcuts.
- View system log messages (e.g. from `NSLog`).
- Access any live object via a scan of the heap.
- View the file system within your app's sandbox.
- Browse SQLite/Realm databases in the file system.
- Trigger 3D touch in the simulator using the control, shift, and command keys.
- Explore all classes in your app and linked systems frameworks (public and private).
- Quickly access useful objects such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
- Dynamically view and modify `NSUserDefaults` values.

Unlike many other debugging tools, FLEX runs entirely inside your app, so you don't need to be connected to LLDB/Xcode or a different remote debugging server. It works well in the simulator and on physical devices.


## Usage

In the iOS simulator, you can use keyboard shortcuts to activate FLEX. `f` will toggle the FLEX toolbar. Hit the `?` key for a full list of shortcuts. You can also show FLEX programmatically:

Short version:

```objc
// Objective-C
[[FLEXManager sharedManager] showExplorer];
```

```swift
// Swift
FLEXManager.shared.showExplorer()
```

More complete version:

```objc
#if DEBUG
#import "FLEXManager.h"
#endif

...

- (void)handleSixFingerQuadrupleTap:(UITapGestureRecognizer *)tapRecognizer
{
#if DEBUG
    if (tapRecognizer.state == UIGestureRecognizerStateRecognized) {
        // This could also live in a handler for a keyboard shortcut, debug menu item, etc.
        [[FLEXManager sharedManager] showExplorer];
    }
#endif
}
```


## Feature Examples
### Modify Views
Once a view is selected, you can tap on the info bar below the toolbar to present more details about the view. From there, you can modify properties and call methods.

<img alt="Modify Views" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271816-c5c2b480-176c-11ea-8bf4-2c5a755bc392.gif>

### Network History
When enabled, network debugging allows you to view all requests made using NSURLConnection or NSURLSession. Settings allow you to adjust what kind of response bodies get cached and the maximum size limit of the response cache. You can choose to have network debugging enabled automatically on app launch. This setting is persisted across launches.

<img alt="Network History" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271876-e5f27380-176c-11ea-98ef-24170205b706.gif>

### All Objects on the Heap
FLEX queries malloc for all the live allocated memory blocks and searches for ones that look like objects. You can see everything from here.

<img alt="Heap/Live Objects Explorer" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271850-d83cee00-176c-11ea-9750-ee3a479c6769.gif>

### Explore-at-address

If you get your hands on an arbitrary address, you can try explore the object at that address, and FLEX will open it if it can verify the address points to a valid object. If FLEX isn't sure, it'll warn you and refuse to dereference the pointer. If you know better, however, you can choose to explore it anyway by choosing "Unsafe Explore"

<img alt="Address Explorer" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271798-bb081f80-176c-11ea-806d-9d74ac293641.gif>

### Simulator Keyboard Shortcuts
Default keyboard shortcuts allow you to activate the FLEX tools, scroll with the arrow keys, and close modals using the escape key. You can also add custom keyboard shortcuts via `-[FLEXManager registerSimulatorShortcutWithKey:modifiers:action:description]`

<img alt="Simulator Keyboard Shortcuts" width=40% height=40% src="https://user-images.githubusercontent.com/8371943/70272984-d3793980-176e-11ea-89a2-66d187d71b4c.png">

### File Browser
View the file system within your app's bundle or sandbox container. FLEX shows file sizes, image previews, and pretty prints `.json` and `.plist` files. You can rename and delete files and folders. You can "share" any file if you want to inspect them outside of your app.

<img alt="File Browser" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271831-d115e000-176c-11ea-8078-ada291f980f3.gif>

### SQLite Browser
SQLite database files (with either `.db` or `.sqlite` extensions), or [Realm](https://realm.io) database files can be explored using FLEX. The database browser lets you view all tables, and individual tables can be sorted by tapping column headers.

<img alt="SQLite Browser" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271881-ea1e9100-176c-11ea-9a42-01618311c869.gif>

### 3D Touch in the Simulator
Using a combination of the command, control, and shift keys, you can simulate different levels of 3D touch pressure in the simulator. Each key contributes 1/3 of maximum possible force. Note that you need to move the touch slightly to get pressure updates.

<img alt="Simulator 3D Touch" width=36% height=36% src=https://cloud.githubusercontent.com/assets/1422245/11786615/5d4ef96c-a23c-11e5-975e-67275341e439.gif>

### Explore Loaded Libraries
Go digging for all things public and private. To learn more about a class, you can create an instance of it and explore its default state. You can also type in a class name to jump to that class directly if you know which class you're looking for.

<img alt="Loaded Libraries Exploration" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271868-dffc9280-176c-11ea-8704-a0c05b75cc5f.gif>

### NSUserDefaults Editing
FLEX allows you to edit defaults that are any combination of strings, numbers, arrays, and dictionaries. The input is parsed as `JSON`. If other kinds of objects are set for a defaults key (i.e. `NSDate`), you can view them but not edit them.

<img alt="NSUserDefaults Editing" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271889-edb21800-176c-11ea-92b4-71e07d2b6ce7.gif>

### Learning from Other Apps
The code injection is left as an exercise for the reader. :innocent:

<p float="left">
    <img alt="Springboard Lock Screen" width=25% height=25% src= https://engineering.flipboard.com/assets/flex/flex-readme-reverse-1.png>
    <img alt="Springboard Home Screen" width=25% height=25% src= https://engineering.flipboard.com/assets/flex/flex-readme-reverse-2.png>
</p>


## Installation

FLEX requires an app that targets iOS 9 or higher. To run the Example project, open a Terminal window in the Example/ folder and run `pod install`, then open the generated workspace.

### CocoaPods

FLEX is available on [CocoaPods](https://cocoapods.org/pods/FLEX). Simply add the following line to your podfile:

```ruby
pod 'FLEX', :configurations => ['Debug']
```

### Carthage

Add the following to your Cartfile:

```
github "flipboard/FLEX"
```

### Buck

If you're using Buck, you may want to silence some of the warnings emitted by FLEX. You will need to build FLEX as an `apple_library` and pass the `-Wno-unsupported-availability-guard` flag, as well as the other warning flags below to disable any other warnings FLEX may have.

### Manual

Manually add the files in `Classes/` to your Xcode project, or just drag in the entire `FLEX/` folder. Be sure to exclude FLEX from `Release` builds or your app will be rejected.

##### Silencing warnings

Add the following flags to  to **Other Warnings Flags** in **Build Settings:** 

- `-Wno-deprecated-declarations`
- `-Wno-strict-prototypes`
- `-Wno-unsupported-availability-guard`

## Excluding FLEX from Release (App Store) Builds

FLEX makes it easy to explore the internals of your app, so it is not something you should expose to your users. Fortunately, it is easy to exclude FLEX files from Release builds. The strategies differ depending on how you integrated FLEX in your project, and are described below.

Wrap the places in your code where you integrate FLEX with an `#if DEBUG` statement to ensure the tool is only accessible in your `Debug` builds and to avoid errors in your `Release` builds. For more help with integrating FLEX, see the example project.

### CocoaPods

CocoaPods automatically excludes FLEX from release builds if you only specify the Debug configuration for FLEX in your Podfile:

```ruby
pod 'FLEX', :configurations => ['Debug']
```

### Carthage

1. Do NOT add `FLEX.framework` to the embedded binaries of your target, as it would otherwise be included in all builds (therefore also in release ones).
1. Instead, add `$(PROJECT_DIR)/Carthage/Build/iOS` to your target _Framework Search Paths_ (this setting might already be present if you already included other frameworks with Carthage). This makes it possible to import the FLEX framework from your source files. It does not harm if this setting is added for all configurations, but it should at least be added for the debug one. 
1. Add a _Run Script Phase_ to your target (inserting it after the existing `Link Binary with Libraries` phase, for example), and which will embed `FLEX.framework` in debug builds only:

	```shell
	if [ "$CONFIGURATION" == "Debug" ]; then
	  /usr/local/bin/carthage copy-frameworks
	fi
	```
	
	Finally, add `$(SRCROOT)/Carthage/Build/iOS/FLEX.framework` as input file of this script phase.
	
<img width=75% height=75% src=https://user-images.githubusercontent.com/8371943/70274062-0d4b3f80-1771-11ea-94ea-ca7e7b5ca244.jpg>

### FLEX files added manually to a project

In Xcode, navigate to `Build Settings > Build Options > Excluded Source File Names`. For your `Release` configuration, set it to `FLEX*` like this to exclude all files with the `FLEX` prefix:

<img width=75% height=75% src=https://user-images.githubusercontent.com/8371943/70281926-e21d1c00-1781-11ea-92eb-aee340791da8.png>

## Additional Notes

- When setting fields of type `id` or values in `NSUserDefaults`, FLEX attempts to parse the input string as `JSON`. This allows you to use a combination of strings, numbers, arrays, and dictionaries. If you want to set a string value, it must be wrapped in quotes. For ivars or properties that are explicitly typed as `NSStrings`, quotes are not required.
- You may want to disable the exception breakpoint while using FLEX. Certain functions that FLEX uses throw exceptions when they get input they can't handle (i.e. `NSGetSizeAndAlignment()`). FLEX catches these to avoid crashing, but your breakpoint will get hit if it is active.


## Thanks & Credits
FLEX builds on ideas and inspiration from open source tools that came before it. The following resources have been particularly helpful:
- [MirrorKit](https://github.com/NSExceptional/MirrorKit): an Objective-C wrapper around the Objective-C runtime.
- [DCIntrospect](https://github.com/domesticcatsoftware/DCIntrospect): view hierarchy debugging for the iOS simulator.
- [PonyDebugger](https://github.com/square/PonyDebugger): network, core data, and view hierarchy debugging using the Chrome Developer Tools interface.
- [Mike Ash](https://www.mikeash.com/pyblog/): well written, informative blog posts on all things obj-c and more. The links below were very useful for this project:
 - [MAObjCRuntime](https://github.com/mikeash/MAObjCRuntime)
 - [Let's Build Key Value Coding](https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html)
 - [ARM64 and You](https://www.mikeash.com/pyblog/friday-qa-2013-09-27-arm64-and-you.html)
- [RHObjectiveBeagle](https://github.com/heardrwt/RHObjectiveBeagle): a tool for scanning the heap for live objects. It should be noted that the source code of RHObjectiveBeagle was not consulted due to licensing concerns.
- [heap_find.cpp](https://www.opensource.apple.com/source/lldb/lldb-179.1/examples/darwin/heap_find/heap/heap_find.cpp): an example of enumerating malloc blocks for finding objects on the heap.
- [Gist](https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396) from [@samdmarshall](https://github.com/samdmarshall): another example of enumerating malloc blocks.
- [Non-pointer isa](http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html): an explanation of changes to the isa field on iOS for ARM64 and mention of the useful `objc_debug_isa_class_mask` variable.
- [GZIP](https://github.com/nicklockwood/GZIP): A library for compressing/decompressing data on iOS using libz.
- [FMDB](https://github.com/ccgus/fmdb): This is an Objective-C wrapper around SQLite.
- [InAppViewDebugger](https://github.com/indragiek/InAppViewDebugger): The inspiration and reference implementation for FLEX 4's 3D view explorer, by @indragiek.




## Contributing
Please see our [Contributing Guide](https://github.com/Flipboard/FLEX/blob/master/CONTRIBUTING.md).


## TODO
- Swift runtime introspection (swift classes, swift objects on the heap, etc.)
- Add new NSUserDefault key/value pairs on the fly
