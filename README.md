# FLEX
FLEX (Flipboard Explorer) is a set of in-app debugging and exploration tools for iOS development.

## Feature Overview
- Inspect and modify views in the hierarchy.
- See the properties and ivars on any object.
- Dynamically modify many properties and ivars.
- Dynamically call instance and class methods.
- Access any live object via a scan of the heap.
- View the file system within your app's sandbox.
- Explore all classes in your app and linked systems frameworks (public and private).
- Quick access to useful singletons such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
- Dynamically view and modify `NSUserDefaults` values.

## Usage

## Feature Examples
### View Hierarchy Exploration

### Object Exploration

### All Objects on the Heap

### File Browser

### System Library Exploration

### NSUserDefaults Editing

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
- [Gist](https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396) from @samdmarshall: another example of enumerating malloc blocks.
- [Non-pointer isa](http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html): an explanation of changes to the isa field on iOS for ARM64 and mention of the useful `objc_debug_isa_class_mask` variable.

## TODO
- Search bar filtering in file browser
- Sorting by file size in file browser
- File browser: try to parse binary files as plists or keyed archives even if they lack the extension?
- Demo app
- Swift runtime introspection (swift classes, swift objects on the heap, etc.)
- Layer hierarchy support
- Add new NSUserDefault key/value pairs on the fly
