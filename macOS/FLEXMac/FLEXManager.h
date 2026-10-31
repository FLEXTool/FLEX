//
//  FLEXManager.h
//  FLEX (macOS)
//
//  The public entry point of FLEX for macOS. Mirrors the iOS FLEXManager API
//  where it makes sense on the Mac.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^FLEXGlobalsEntryObjectFuture)(void);
typedef NSViewController * _Nullable (^FLEXGlobalsEntryViewControllerFuture)(void);

@interface FLEXManager : NSObject

@property (nonatomic, readonly, class) FLEXManager *sharedManager NS_SWIFT_NAME(shared);

#pragma mark Showing and hiding

/// Whether the FLEX toolbar is hidden
@property (nonatomic, readonly) BOOL isHidden;

/// Shows the floating FLEX toolbar
- (void)showExplorer;
/// Hides the toolbar and all FLEX windows
- (void)hideExplorer;
- (void)toggleExplorer;

/// Shows the main menu of FLEX tools in the explorer window
- (void)showGlobals;
/// Shows the view hierarchy of every window in the app
- (void)showViewHierarchy;
/// Starts "select" mode: hover to highlight views, click to select one
- (void)beginViewSelection;
/// Shows the network history
- (void)showNetworkHistory;

/// Opens an object explorer for any object or class
- (void)presentObjectExplorer:(id)object;
/// Pushes any view controller onto the FLEX explorer window
- (void)presentTool:(NSViewController *(^)(void))viewControllerFuture;

#pragma mark Keyboard shortcut

/// Toggles the explorer when pressed while the app is active.
/// Defaults to ⌥⌘F (option-command-F). Set \c keyboardShortcutEnabled to NO to disable it.
@property (nonatomic, copy) NSString *keyboardShortcutKey;
@property (nonatomic) NSEventModifierFlags keyboardShortcutModifiers;
@property (nonatomic) BOOL keyboardShortcutEnabled;

/// Adds an "Explore with FLEX" item (⌥⌘F) to the application's main menu,
/// under the Window menu, or a new "Debug" menu if there is no Window menu
- (void)installMainMenuItem;

#pragma mark Globals

/// Adds an entry at the top of the list of Global State items.
/// @param objectFutureBlock called when the row is selected; its result is explored.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(FLEXGlobalsEntryObjectFuture)objectFutureBlock;
/// Adds an entry at the top of the list of Global State items.
/// @param viewControllerFutureBlock called when the row is selected; its result is pushed.
- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(FLEXGlobalsEntryViewControllerFuture)viewControllerFutureBlock;

#pragma mark Networking

/// If this property is set to YES, FLEX will swizzle NSURLConnection*Delegate and NSURLSession*Delegate methods
/// on classes that conform to the protocols. This allows you to view network activity history from the main FLEX menu.
/// Full responses are kept temporarily in a size-limited cache and may be pruned under memory pressure.
@property (nonatomic, getter=isNetworkDebuggingEnabled) BOOL networkDebuggingEnabled;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
/// The response cache uses an NSCache, so it may purge prior to hitting the limit when the app is under memory pressure.
@property (nonatomic) NSUInteger networkResponseCacheByteLimit;

/// Requests whose host ends with one of the excluded entries in this array will be not be recorded (eg. google.com).
/// Wildcard or subdomain entries are not required (eg. google.com will match any subdomain under google.com).
/// Useful to remove requests that are typically noisy, such as analytics requests that you aren't interested in tracking.
@property (nonatomic) NSMutableArray<NSString *> *networkRequestHostDenylist;

#pragma mark Misc

/// Default database password is nil by default.
/// Set this to the password you want the databases to open with.
@property (nonatomic, copy, nullable) NSString *defaultSqliteDatabasePassword;

/// The file browser opens to this path. Defaults to the app's home/container directory.
@property (nonatomic, copy, nullable) NSString *fileBrowserRootPath;

@end

NS_ASSUME_NONNULL_END
