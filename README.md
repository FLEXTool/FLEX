# FLEX 
[![CocoaPods](https://img.shields.io/cocoapods/v/FLEX.svg)](http://cocoapods.org/?q=FLEX)
 [![CocoaPods](https://img.shields.io/cocoapods/l/FLEX.svg)](https://github.com/Flipboard/FLEX/blob/master/LICENSE)
 [![CocoaPods](https://img.shields.io/cocoapods/p/FLEX.svg)]()
 [![Twitter: @ryanolsonk](https://img.shields.io/badge/contact-@ryanolsonk-blue.svg?style=flat)](https://twitter.com/ryanolsonk)
 [![Build Status](https://travis-ci.org/Flipboard/FLEX.svg?branch=master)](https://travis-ci.org/Flipboard/FLEX)

FLEX (Flipboard Explorer) is a set of in-app debugging and exploration tools for iOS development. When presented, FLEX shows a toolbar that lives in a window above your application. From this toolbar, you can view and modify nearly every piece of state in your running application.

![View Hierarchy Exploration](http://engineering.flipboard.com/assets/flex/basic-view-exploration.gif)


## Give Yourself Debugging Superpowers
- Inspect and modify views in the hierarchy.
- See the properties and ivars on any object.
- Dynamically modify many properties and ivars.
- Dynamically call instance and class methods.
- Observe detailed network request history with timing, headers, and full responses.
- View system log messages (e.g. from `NSLog`).
- Access any live object via a scan of the heap.
- View the file system within your app's sandbox.
- Explore all classes in your app and linked systems frameworks (public and private).
- Quickly access useful objects such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
- Dynamically view and modify `NSUserDefaults` values.

Unlike many other debugging tools, FLEX runs entirely inside your app, so you don't need to be connected to LLDB/Xcode or a different remote debugging server. It works well in the simulator and on physical devices.


## Usage
Short version:

```objc
[[FLEXManager sharedManager] showExplorer];
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

![View Modification](http://engineering.flipboard.com/assets/flex/advanced-view-editing.gif)

### Network History
When enabled, network debugging allows you to view all requests made using NSURLConnection or NSURLSession. Settings allow you to adjust what kind of response bodies get cached and the maximum size limit of the response cache. You can choose to have network debugging enabled automatically on app launch. This setting is persisted accross launches.

![Network History](http://engineering.flipboard.com/assets/flex/network-history.gif)

### All Objects on the Heap
FLEX queries malloc for all the live allocated memory blocks and searches for ones that look like objects. You can see everything from here.

![Heap Exploration](http://engineering.flipboard.com/assets/flex/heap-browser.gif)

### File Browser
View the file system within your app's sandbox. FLEX shows file sizes, image previews, and pretty prints `.json` and `.plist` files. You can copy text and image files to the pasteboard if you want to inspect them outside of your app.

![File Browser](http://engineering.flipboard.com/assets/flex/file-browser.gif)

### System Library Exploration
Go digging for all things public and private. To learn more about a class, you can create an instance of it and explore its default state.

![System Libraries Browser](http://engineering.flipboard.com/assets/flex/system-libraries-browser.gif)

### NSUserDefaults Editing
FLEX allows you to edit defaults that are any combination of strings, numbers, arrays, and dictionaries. The input is parsed as `JSON`. If other kinds of objects are set for a defaults key (i.e. `NSDate`), you can view them but not edit them.

![NSUserDefaults Editor](http://engineering.flipboard.com/assets/flex/nsuserdefaults-editor.gif)

### Learning from Other Apps
The code injection is left as an exercise for the reader. :innocent:

![Springboard Lock Screen](http://engineering.flipboard.com/assets/flex/flex-readme-reverse-1.png) ![Springboard Home Screen](http://engineering.flipboard.com/assets/flex/flex-readme-reverse-2.png)


## Installation
FLEX is available on [Cocoapods](http://cocoapods.org/?q=FLEX). Simply add the following line to your podfile:

```ruby
pod 'FLEX', '~> 2.0', :configurations => ['Debug']
```

Alternatively, you can manually add the files in `Classes/` to your Xcode project. FLEX requires iOS 7 or higher.


## Excluding FLEX from Release (App Store) Builds
*Note: CocoaPods handles this automatically if you only specify the Debug configuration for FLEX in your Podfile.*
FLEX makes it easy to explore the internals of your app, so it is not something you should expose to your users. Fortunately, it is easy to exclude FLEX files from Release builds. In Xcode, navigate to the "Build Settings" tab of your project. Click the plus and select `Add User-Defined Setting`.

![Add User-Defined Setting](http://engineering.flipboard.com/assets/flex/flex-readme-exclude-1.png)

Name the setting `EXCLUDED_SOURCE_FILE_NAMES`. For your `Release` configuration, set the value to `FLEX*`. This will exclude all files with the prefix FLEX from compilation. Leave the value blank for your `Debug` configuration.

![EXCLUDED_SOURCE_FILE_NAMES](http://engineering.flipboard.com/assets/flex/flex-readme-exclude-2.png)

At the places in your code where you integrate FLEX, do a `#if DEBUG` check to ensure the tool is only accessible in your `Debug` builds and to avoid errors in your `Release` builds. For more help with integrating FLEX, see the example project.


## Additional Notes
- When setting fields of type `id` or values in `NSUserDefaults`, FLEX attempts to parse the input string as `JSON`. This allows you to use a combination of strings, numbers, arrays, and dictionaries. If you want to set a string value, it must be wrapped in quotes. For ivars or properties that are explicitly typed as `NSStrings`, quotes are not required.
- You may want to disable the exception breakpoint while using FLEX. Certain functions that FLEX uses throw exceptions when they get input they can't handle (i.e. `NSGetSizeAndAlignment()`). FLEX catches these to avoid crashing, but your breakpoint will get hit if it is active.


## Thanks & Credits
FLEX builds on ideas and inspiration from open source tools that came before it. The following resources have been particularly helpful:
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



## Contributing
We welcome pull requests for bug fixes, new features, and improvements to FLEX. Contributors to the main FLEX repository must accept Flipboard's Apache-style [Individual Contributor License Agreement (CLA)](https://docs.google.com/forms/d/1gh9y6_i8xFn6pA15PqFeye19VqasuI9-bGp_e0owy74/viewform) before any changes can be merged.


## TODO
- Swift runtime introspection (swift classes, swift objects on the heap, etc.)
- Improved file type detection and display in the file browser
- Add new NSUserDefault key/value pairs on the fly
