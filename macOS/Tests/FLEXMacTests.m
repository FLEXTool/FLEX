//
//  FLEXMacTests.m
//  FLEXMacTests
//
//  Hosted in FLEXMacExample. Drives FLEX's AppKit interface in-process.
//

#import <XCTest/XCTest.h>
#import <FLEX/FLEX.h>
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacGlobalsViewController.h"
#import "FLEXMacViewHierarchyViewController.h"
#import "FLEXMacNetworkViewController.h"
#import "FLEXMacArgumentInputView.h"
#import "FLEXMacEditorViewControllers.h"
#import "FLEXMacExplorerWindowController.h"
#import "FLEXMacViewSelector.h"
#import "FLEXMacUtility.h"
#import "FLEXMirror.h"
#import "FLEXProperty.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXInjectEngine.h"

@interface FLEXMacTestModel : NSObject {
@public
    int _counter;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSRect frame;
@property (nonatomic) BOOL enabled;
- (NSString *)joined:(NSString *)a with:(NSInteger)b;
@end

@implementation FLEXMacTestModel
- (NSString *)joined:(NSString *)a with:(NSInteger)b {
    return [NSString stringWithFormat:@"%@-%ld", a, (long)b];
}
@end

@interface FLEXMacTests : XCTestCase
@end

@implementation FLEXMacTests

+ (NSString *)snapshotDirectory {
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"FLEXMacSnapshots"];
    [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (void)spinRunLoop:(NSTimeInterval)seconds {
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (NSWindow *)appWindow {
    for (NSWindow *window in FLEXMacUtility.appWindows) {
        if (window.isVisible && window.contentView.subviews.count) {
            return window;
        }
    }
    return nil;
}

- (void)collectViews:(NSView *)view into:(NSMutableArray *)views {
    [views addObject:view];
    for (NSView *subview in view.subviews) {
        [self collectViews:subview into:views];
    }
}

- (void)saveSnapshotOfWindow:(NSWindow *)window name:(NSString *)name {
    NSView *root = [FLEXMacUtility rootViewForWindow:window];
    [root layoutSubtreeIfNeeded];
    [root displayIfNeeded];
    NSBitmapImageRep *rep = [root bitmapImageRepForCachingDisplayInRect:root.bounds];
    [root cacheDisplayInRect:root.bounds toBitmapImageRep:rep];
    NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    NSString *path = [[FLEXMacTests.snapshotDirectory stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"png"];
    [png writeToFile:path atomically:YES];
    NSLog(@"FLEX snapshot: %@", path);
}

#pragma mark Object explorer

- (NSArray<FLEXMacSection *> *)loadExplorerFor:(id)object {
    FLEXMacObjectExplorerViewController *explorer = [FLEXMacObjectExplorerViewController explorerForObject:object];
    XCTAssertNotNil(explorer);
    [explorer view];
    [explorer reloadData];
    return explorer.sections;
}

- (void)testExploreAppKitAndFoundationObjects {
    NSWindow *window = self.appWindow;
    XCTAssertNotNil(window, @"The example app should have a window");

    NSMutableArray *objects = [NSMutableArray arrayWithArray:@[
        NSApp, NSApp.mainMenu, window, NSUserDefaults.standardUserDefaults, NSBundle.mainBundle,
        NSProcessInfo.processInfo, NSScreen.mainScreen, NSPasteboard.generalPasteboard,
        NSFileManager.defaultManager, NSWorkspace.sharedWorkspace, NSColor.systemRedColor,
        [NSImage imageNamed:NSImageNameComputer], @[@1, @"two", @{@"three": @3}], @{@"key": @"value"},
        [NSSet setWithObjects:@1, @2, nil], [@"hello" dataUsingEncoding:NSUTF8StringEncoding],
        @"A string", [NSURL fileURLWithPath:NSHomeDirectory()], NSView.class, NSObject.class,
        NSURLSession.sharedSession, NSFontManager.sharedFontManager, NSThread.mainThread,
    ]];
    if (window.contentViewController) [objects addObject:window.contentViewController];
    [self collectViews:[FLEXMacUtility rootViewForWindow:window] into:objects];
    for (NSMenuItem *item in NSApp.mainMenu.itemArray) {
        [objects addObject:item];
    }

    for (NSNumber *inherited in @[@NO, @YES]) {
        [NSUserDefaults.standardUserDefaults setBool:inherited.boolValue forKey:@"com.flex.mac.explorer.includeInherited"];
        for (id object in objects) {
            NSArray<FLEXMacSection *> *sections = [self loadExplorerFor:object];
            XCTAssertGreaterThan(sections.count, 1u, @"%@", object);
        }
    }
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"com.flex.mac.explorer.includeInherited"];
}

- (void)testExplorerShowsPropertiesIvarsAndMethods {
    FLEXMacTestModel *model = [FLEXMacTestModel new];
    model.name = @"flex";
    NSArray<FLEXMacSection *> *sections = [self loadExplorerFor:model];
    NSMutableDictionary<NSString *, FLEXMacSection *> *byTitle = [NSMutableDictionary new];
    for (FLEXMacSection *section in sections) {
        NSString *key = [section.title componentsSeparatedByString:@" "].firstObject;
        byTitle[key] = byTitle[key] ?: section;
    }

    NSArray *propertyNames = [byTitle[@"Properties"].rows valueForKey:@"title"];
    XCTAssertTrue([propertyNames containsObject:@"name"]);
    XCTAssertTrue([propertyNames containsObject:@"frame"]);
    FLEXMacRow *nameRow = byTitle[@"Properties"].rows[[propertyNames indexOfObject:@"name"]];
    XCTAssertTrue([nameRow.subtitle containsString:@"flex"], @"%@", nameRow.subtitle);

    FLEXMacRow *enabledRow = byTitle[@"Properties"].rows[[propertyNames indexOfObject:@"enabled"]];
    XCTAssertTrue([enabledRow.subtitle hasSuffix:@"= NO"], @"%@", enabledRow.subtitle);
    FLEXMacRow *frameRow = byTitle[@"Properties"].rows[[propertyNames indexOfObject:@"frame"]];
    XCTAssertTrue([frameRow.subtitle containsString:@"width: 0"], @"%@", frameRow.subtitle);

    NSArray *ivarNames = [byTitle[@"Ivars"].rows valueForKey:@"title"];
    FLEXMacRow *frameIvarRow = byTitle[@"Ivars"].rows[[ivarNames indexOfObject:@"_frame"]];
    XCTAssertTrue([frameIvarRow.subtitle containsString:@"height: 0"], @"%@", frameIvarRow.subtitle);
    XCTAssertTrue([ivarNames containsObject:@"_counter"]);

    NSArray *methodNames = [byTitle[@"Methods"].rows valueForKey:@"title"];
    XCTAssertTrue([methodNames containsObject:@"joined:with:"]);
}

#pragma mark Editing

- (void)testArgumentInputRoundTrips {
    FLEXMacArgumentInputView *rectInput = [[FLEXMacArgumentInputView alloc] initWithTypeEncoding:@encode(NSRect) title:@"rect"];
    [rectInput populateWithValue:[NSValue valueWithRect:NSMakeRect(1, 2, 3, 4)]];
    NSError *error = nil;
    NSValue *rect = [rectInput inputValueWithError:&error];
    XCTAssertNil(error);
    XCTAssertTrue(NSEqualRects(rect.rectValue, NSMakeRect(1, 2, 3, 4)));

    FLEXMacArgumentInputView *numberInput = [[FLEXMacArgumentInputView alloc] initWithTypeEncoding:@encode(NSInteger) title:nil];
    [numberInput populateWithValue:@(-42)];
    NSValue *number = [numberInput inputValueWithError:&error];
    NSInteger integer = 0;
    [number getValue:&integer];
    XCTAssertEqual(integer, -42);

    FLEXMacArgumentInputView *objectInput = [[FLEXMacArgumentInputView alloc] initWithTypeEncoding:"@\"NSArray\"" title:nil];
    [objectInput populateWithValue:@[@1, @"a"]];
    XCTAssertEqualObjects([objectInput inputValueWithError:&error], (@[@1, @"a"]));

    // Existing objects by address
    NSObject *existing = [NSObject new];
    [objectInput populateWithValue:existing];
    XCTAssertEqual([objectInput inputValueWithError:&error], existing);

    XCTAssertFalse([FLEXMacArgumentInputView supportsTypeEncoding:"^v"]);
    XCTAssertFalse([FLEXMacArgumentInputView supportsTypeEncoding:"@?"]);
}

- (void)testFieldEditorsSetPropertiesAndIvars {
    FLEXMacTestModel *model = [FLEXMacTestModel new];
    FLEXProperty *countProperty = [FLEXProperty named:@"count" onClass:FLEXMacTestModel.class];
    FLEXMacFieldEditorViewController *editor = [FLEXMacFieldEditorViewController editorForProperty:countProperty target:model commit:nil];
    XCTAssertNotNil(editor);
    [editor view];
    FLEXMacArgumentInputView *input = [editor valueForKey:@"input"];
    [(NSTextField *)input.firstInputView setStringValue:@"7"];
    [editor performSelector:NSSelectorFromString(@"commit:") withObject:nil];
    XCTAssertEqual(model.count, 7);

    FLEXMacFieldEditorViewController *frameEditor = [FLEXMacFieldEditorViewController
        editorForProperty:[FLEXProperty named:@"frame" onClass:FLEXMacTestModel.class] target:model commit:nil];
    [frameEditor view];
    FLEXMacArgumentInputView *frameInput = [frameEditor valueForKey:@"input"];
    NSArray<NSTextField *> *fields = [frameInput valueForKey:@"structTextFields"];
    XCTAssertEqual(fields.count, 4u);
    fields[2].stringValue = @"99.5";
    [frameEditor performSelector:NSSelectorFromString(@"commit:") withObject:nil];
    XCTAssertEqual(model.frame.size.width, 99.5);

    FLEXIvar *ivar = [FLEXIvar named:@"_counter" onClass:FLEXMacTestModel.class];
    FLEXMacFieldEditorViewController *ivarEditor = [FLEXMacFieldEditorViewController editorForIvar:ivar target:model commit:nil];
    [ivarEditor view];
    FLEXMacArgumentInputView *ivarInput = [ivarEditor valueForKey:@"input"];
    [(NSTextField *)ivarInput.firstInputView setStringValue:@"123"];
    [ivarEditor performSelector:NSSelectorFromString(@"commit:") withObject:nil];
    XCTAssertEqual(model->_counter, 123);

    // Struct ivars have field names in their type encodings
    FLEXIvar *frameIvar = [FLEXIvar named:@"_frame" onClass:FLEXMacTestModel.class];
    FLEXMacFieldEditorViewController *frameIvarEditor = [FLEXMacFieldEditorViewController editorForIvar:frameIvar target:model commit:nil];
    XCTAssertNotNil(frameIvarEditor);
    [frameIvarEditor view];
    NSArray<NSTextField *> *ivarFields = [[frameIvarEditor valueForKey:@"input"] valueForKey:@"structTextFields"];
    XCTAssertEqual(ivarFields.count, 4u);
    ivarFields[0].stringValue = @"12";
    [frameIvarEditor performSelector:NSSelectorFromString(@"commit:") withObject:nil];
    XCTAssertEqual(model.frame.origin.x, 12);
}

- (void)testMethodCalling {
    FLEXMacTestModel *model = [FLEXMacTestModel new];
    FLEXMethod *method = [FLEXMethod selector:@selector(joined:with:) class:FLEXMacTestModel.class];
    XCTAssertTrue([FLEXMacMethodCallViewController canCallMethod:method]);

    FLEXMacMethodCallViewController *caller = [FLEXMacMethodCallViewController callerForMethod:method target:model];
    [caller view];
    NSArray<FLEXMacArgumentInputView *> *inputs = [caller valueForKey:@"inputs"];
    XCTAssertEqual(inputs.count, 2u);
    [(NSTextField *)inputs[0].firstInputView setStringValue:@"\"abc\""];
    [(NSTextField *)inputs[1].firstInputView setStringValue:@"5"];
    [caller performSelector:NSSelectorFromString(@"call:") withObject:nil];
    XCTAssertEqualObjects([caller valueForKey:@"lastResult"], @"abc-5");
}

#pragma mark Tools

- (void)testEveryGlobalsToolLoads {
    FLEXMacGlobalsViewController *globals = [FLEXMacGlobalsViewController new];
    [globals view];
    NSUInteger loaded = 0;
    for (FLEXMacSection *section in globals.sections) {
        for (FLEXMacRow *row in section.rows) {
            if (!row.viewControllerProvider) continue;
            NSViewController *controller = row.viewControllerProvider();
            if (!controller) {
                // Only nil globals (e.g. the main window while inactive) may produce nothing
                XCTAssertTrue([row.subtitle isEqualToString:@"nil"], @"%@", row.title);
                continue;
            }
            [controller view];
            if ([controller isKindOfClass:[FLEXMacTableViewController class]]) {
                [(FLEXMacTableViewController *)controller reloadData];
            }
            loaded++;
        }
    }
    XCTAssertGreaterThan(loaded, 20u);
}

- (void)testViewHierarchyAndSelection {
    NSWindow *window = self.appWindow;
    NSView *button = nil;
    NSMutableArray *views = [NSMutableArray new];
    [self collectViews:window.contentView into:views];
    for (NSView *view in views) {
        if ([view.identifier isEqualToString:@"showFLEXButton"]) button = view;
    }
    XCTAssertNotNil(button);

    FLEXMacViewHierarchyViewController *hierarchy = [FLEXMacViewHierarchyViewController hierarchyFocusingOnView:button];
    [hierarchy view];
    NSOutlineView *outline = [hierarchy valueForKey:@"outlineView"];
    XCTAssertGreaterThan(outline.numberOfRows, 5);
    id selected = [outline itemAtRow:outline.selectedRow];
    XCTAssertEqual([selected valueForKey:@"object"], button);

    // Hit testing used by select mode. This depends on the window actually
    // being frontmost on screen, so bring our app and window to the front and
    // retry a few times before giving up.
    [NSApp activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:nil];
    [window orderFrontRegardless];

    NSRect screenRect = [FLEXMacUtility screenRectForView:button];
    NSPoint point = NSMakePoint(NSMidX(screenRect), NSMidY(screenRect));
    NSView *hit = nil;
    for (int attempt = 0; attempt < 10 && !hit; attempt++) {
        [self spinRunLoop:0.2];
        hit = [FLEXMacViewSelector viewAtScreenPoint:point];
    }
    if (!hit) {
        // The window server won't resolve the point in some headless/CI
        // contexts; the hierarchy assertions above already exercised selection.
        XCTSkip(@"Window not resolvable on screen for hit-testing");
    }
    XCTAssertTrue(hit == button || [hit isDescendantOf:button], @"hit %@", hit);
}

- (void)testNetworkRecording {
    FLEXManager.sharedManager.networkDebuggingEnabled = YES;
    XCTestExpectation *done = [self expectationWithDescription:@"request"];
    __block NSError *requestError = nil;
    NSURL *url = [NSURL URLWithString:@"https://example.com/?flex=test"];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        requestError = error;
        [done fulfill];
    }] resume];
    [self waitForExpectations:@[done] timeout:30];
    if (requestError) {
        XCTSkip(@"Network unavailable: %@", requestError.localizedDescription);
    }
    [self spinRunLoop:1];

    NSArray *urls = [FLEXNetworkRecorder.defaultRecorder.HTTPTransactions valueForKeyPath:@"request.URL"];
    XCTAssertTrue([urls containsObject:url], @"%@", urls);

    FLEXMacNetworkViewController *network = [FLEXMacNetworkViewController new];
    [network view];
    [network reloadData];
    XCTAssertGreaterThan(network.sections.firstObject.rows.count, 0u);
    FLEXMacRow *row = network.sections.firstObject.rows.firstObject;
    NSViewController *details = row.viewControllerProvider();
    [details view];
    [(FLEXMacTableViewController *)details reloadData];
    XCTAssertGreaterThan([(FLEXMacTableViewController *)details sections].count, 2u);
}

#pragma mark Injection engine

- (void)testBundledDylibIsTheFLEXBinary {
    NSString *dylib = [FLEXInjectEngine bundledFLEXDylibPath];
    XCTAssertNotNil(dylib);
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:dylib], @"%@", dylib);
    // It should be the FLEX framework's Mach-O (the thing we inject).
    XCTAssertTrue([dylib containsString:@"FLEX.framework"], @"%@", dylib);
    XCTAssertEqualObjects([NSBundle bundleForClass:FLEXManager.class].executablePath, dylib);
}

- (void)testClassifyOwnExampleAppIsInjectable {
    // The test host (FLEXMacExample) is a non-hardened debug build, so it must
    // be classified as injectable and its executable must resolve.
    NSString *appPath = NSBundle.mainBundle.bundlePath;
    FLEXInjectInfo *info = [FLEXInjectEngine inspectAppBundle:appPath];
    XCTAssertEqualObjects(info.executablePath, NSBundle.mainBundle.executablePath);
    XCTAssertEqual(info.status, FLEXInjectStatusInjectable, @"%@", info.statusDescription);
    XCTAssertTrue(info.isInjectable);
}

- (void)testClassifySystemAppIsProtected {
    // Finder lives under /System and is SIP-protected: DYLD_* is stripped.
    NSString *finder = @"/System/Library/CoreServices/Finder.app";
    if (![NSFileManager.defaultManager fileExistsAtPath:finder]) {
        XCTSkip(@"Finder not present");
    }
    FLEXInjectInfo *info = [FLEXInjectEngine inspectAppBundle:finder];
    XCTAssertEqual(info.status, FLEXInjectStatusSIPProtected, @"%@", info.statusDescription);
    XCTAssertFalse(info.isInjectable);
}

- (void)testClassifyNonAppReturnsNotAnApp {
    FLEXInjectInfo *info = [FLEXInjectEngine inspectAppBundle:@"/tmp/does-not-exist.app"];
    XCTAssertEqual(info.status, FLEXInjectStatusNotAnApp);
    XCTAssertFalse(info.isInjectable);
}

- (void)testLaunchEnvironmentInsertsDylibAndFlag {
    NSDictionary *env = [FLEXInjectEngine launchEnvironmentWithDylib:@"/tmp/libX.dylib" autoShow:YES];
    XCTAssertEqualObjects(env[@"DYLD_INSERT_LIBRARIES"], @"/tmp/libX.dylib");
    XCTAssertEqualObjects(env[@"FLEX_AUTO_SHOW"], @"1");

    NSDictionary *hidden = [FLEXInjectEngine launchEnvironmentWithDylib:@"/tmp/libX.dylib" autoShow:NO];
    XCTAssertEqualObjects(hidden[@"FLEX_AUTO_SHOW"], @"0");
}

- (void)testActuallyInjectIntoAFreshExampleProcess {
    // End-to-end: launch a second copy of the example app with FLEX inserted,
    // and confirm the injected constructor announces itself on stdout.
    NSString *appPath = NSBundle.mainBundle.bundlePath;
    FLEXInjectInfo *info = [FLEXInjectEngine inspectAppBundle:appPath];
    NSString *dylib = [FLEXInjectEngine bundledFLEXDylibPath];

    // Launch the child in the background so it doesn't steal focus from the
    // test host (the engine copies our environment to the child).
    setenv("FLEX_EXAMPLE_HEADLESS", "1", 1);

    XCTestExpectation *announced = [self expectationWithDescription:@"injected constructor logs"];
    announced.assertForOverFulfill = NO;
    NSError *error = nil;
    NSTask *task = [FLEXInjectEngine launchApp:info dylib:dylib autoShow:NO error:&error outputHandler:^(NSString *chunk) {
        if ([chunk containsString:@"[FLEX] Injected into"]) {
            [announced fulfill];
        }
    }];
    XCTAssertNotNil(task, @"%@", error);

    [self waitForExpectations:@[announced] timeout:20];
    [task terminate];
    [task waitUntilExit];
    unsetenv("FLEX_EXAMPLE_HEADLESS");
}

#pragma mark Snapshots

- (void)testZZSnapshots {
    FLEXManager *flex = FLEXManager.sharedManager;
    [flex showExplorer];
    [self spinRunLoop:0.3];
    XCTAssertFalse(flex.isHidden);

    NSWindow *toolbar = nil;
    for (NSWindow *window in NSApp.windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"FLEXMacToolbarPanel"]) toolbar = window;
    }
    XCTAssertNotNil(toolbar);
    [self saveSnapshotOfWindow:toolbar name:@"toolbar"];

    FLEXMacExplorerWindowController *explorer = FLEXMacExplorerWindowController.sharedController;
    [flex showGlobals];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"globals"];

    [flex showViewHierarchy];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"hierarchy"];

    [flex presentObjectExplorer:self.appWindow];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"window-explorer"];

    FLEXMacTestModel *model = [FLEXMacTestModel new];
    model.name = @"snapshot";
    [flex presentObjectExplorer:model];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"model-explorer"];

    [flex presentTool:^NSViewController *{
        return [FLEXMacFieldEditorViewController editorForProperty:[FLEXProperty named:@"frame" onClass:FLEXMacTestModel.class]
                                                            target:model commit:nil];
    }];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"field-editor"];

    [flex showNetworkHistory];
    [self spinRunLoop:0.5];
    [self saveSnapshotOfWindow:explorer.window name:@"network"];

    [flex hideExplorer];
    [self spinRunLoop:0.2];
    XCTAssertTrue(flex.isHidden);
}

@end
