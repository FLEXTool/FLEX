# FLEX

## TODO:

### Must haves:
- README
 - Note only supported back to iOS 6
 - Usage & feature explanations
 - Exception breakpoint note
 - Notes on unsupported: Classes that don't inherit from NSObject. Unions. Packed structs. C array arguments. Etc.
 - Note that heap objects may have some false positives
 - Thanks/credits section
- Blog post
- Cleanup and comments

### Nice to haves:
- Image preview in the file browser for image files
- Search bar filtering in file browser
- View hierarchy 3D perspective
- UIColor argument input view
- UIFont argument input view
- File browser: try to parse binary files as plists even if they lack the .plist extension
- Demo app
- Considder a custom UILabel explorer that extends the UIView explorer
- Toast when method calling or property setting fails
- Support setting mutable array/dictionary properties
- Mutable collection editing
- Drill in from class explorer to properties, ivars, and methods for full names and attributes ("call/set" disabled/hidden)

### Community feature ideas
- Swift runtime introspection (swift classes, swift objects on the heap, etc.)
- Layer hierarchy support
- Consider a custom data approach that allows users to prioritize their own relevant information.
- Keyboard shortcuts (that don't interfere with existing keyboard shortcuts)
- Add new NSUserDefault key/value pair on the fly
