//
//  FLEXMacGlobalsViewController.m
//  FLEX (macOS)
//

#import "FLEXMacGlobalsViewController.h"
#import "FLEXManager+Private.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacObjectListViewController.h"
#import "FLEXMacViewHierarchyViewController.h"
#import "FLEXMacNetworkViewController.h"
#import "FLEXMacHeapViewController.h"
#import "FLEXMacRuntimeBrowserViewController.h"
#import "FLEXMacFileBrowserViewController.h"
#import "FLEXMacSystemLogViewController.h"
#import "FLEXMacKeychainViewController.h"
#import "FLEXMacUtility.h"
#import "FLEXObjcInternal.h"
#import "FLEXRuntimeUtility.h"

@implementation FLEXMacGlobalsViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"FLEX";
        self.showsRefreshButton = YES;
    }
    return self;
}

static FLEXMacRow *FLEXMacGlobal(NSString *symbol, NSString *title, id (^future)(void)) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:nil pushing:^NSViewController *{
        // nil (e.g. no main window while the app is inactive) explores nothing
        NSViewController *explorer = [FLEXMacObjectExplorerViewController explorerForObject:future()];
        if (!explorer) NSBeep();
        return explorer;
    }];
    row.subtitle = [FLEXMacUtility summaryForObject:future() maxLength:120];
    row.subtitleMaxLines = 1;
    row.image = [FLEXMacUtility symbol:symbol];
    return row;
}

static FLEXMacRow *FLEXMacTool(NSString *symbol, NSString *title, NSString *subtitle, NSViewController *(^future)(void)) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:subtitle pushing:future];
    row.image = [FLEXMacUtility symbol:symbol];
    return row;
}

- (NSArray<FLEXMacSection *> *)makeSections {
    NSMutableArray *sections = [NSMutableArray new];

    NSArray *custom = FLEXManager.sharedManager.userGlobalEntryRows;
    if (custom.count) {
        [sections addObject:[FLEXMacSection title:@"Custom Additions" rows:custom]];
    }

    __weak typeof(self) weakSelf = self;
    [sections addObject:[FLEXMacSection title:@"Tools" rows:@[
        FLEXMacTool(@"network", @"Network History", @"Requests made with NSURLSession and NSURLConnection", ^NSViewController *{
            return [FLEXMacNetworkViewController new];
        }),
        FLEXMacTool(@"list.bullet.indent", @"View Hierarchy", @"Every window and view in the app", ^NSViewController *{
            return [FLEXMacViewHierarchyViewController hierarchy];
        }),
        FLEXMacTool(@"memorychip", @"Heap Objects", @"Live objects on the heap, grouped by class", ^NSViewController *{
            return [FLEXMacHeapViewController new];
        }),
        FLEXMacTool(@"books.vertical", @"Runtime Browser", @"Loaded libraries and their classes", ^NSViewController *{
            return [FLEXMacRuntimeBrowserViewController imagesBrowser];
        }),
        FLEXMacTool(@"app.badge", @"App Classes", @"Classes defined in the main executable", ^NSViewController *{
            return [FLEXMacRuntimeBrowserViewController classesInImage:NSBundle.mainBundle.executablePath];
        }),
        FLEXMacTool(@"folder", @"File Browser", @"The app's container, home directory and bundle", ^NSViewController *{
            return [FLEXMacFileBrowserViewController browserForPath:FLEXManager.sharedManager.fileBrowserRootPath ?: NSHomeDirectory()];
        }),
        FLEXMacTool(@"doc.plaintext", @"System Log", @"Messages logged by this process", ^NSViewController *{
            return [FLEXMacSystemLogViewController new];
        }),
        FLEXMacTool(@"key", @"Keychain", @"Generic passwords accessible to this app", ^NSViewController *{
            return [FLEXMacKeychainViewController new];
        }),
        FLEXMacTool(@"globe", @"Cookies", @"NSHTTPCookieStorage.sharedHTTPCookieStorage", ^NSViewController *{
            NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies sortedArrayUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:@"domain" ascending:YES],
                [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],
            ]];
            return [FLEXMacObjectListViewController listWithTitle:@"Cookies" objects:cookies ?: @[]];
        }),
        [self actionRowWithSymbol:@"number" title:@"Explore Address" subtitle:@"Explore an object at a memory address" action:^{
            [weakSelf exploreAddress];
        }],
        [self actionRowWithSymbol:@"magnifyingglass" title:@"Explore Class" subtitle:@"Explore a class by name" action:^{
            [weakSelf exploreClass];
        }],
    ]]];

    [sections addObject:[FLEXMacSection title:@"Application" rows:@[
        FLEXMacGlobal(@"app", @"NSApp", ^id { return NSApp; }),
        FLEXMacGlobal(@"person.crop.square", @"App Delegate", ^id { return NSApp.delegate; }),
        FLEXMacGlobal(@"macwindow", @"Key Window", ^id { return FLEXMacUtility.appKeyWindow; }),
        FLEXMacGlobal(@"macwindow.on.rectangle", @"Main Window", ^id { return NSApp.mainWindow; }),
        FLEXMacTool(@"rectangle.stack", @"All Windows", nil, ^NSViewController *{
            return [FLEXMacObjectListViewController listWithTitle:@"Windows" objects:FLEXMacUtility.appWindows];
        }),
        FLEXMacGlobal(@"filemenu.and.selection", @"Main Menu", ^id { return NSApp.mainMenu; }),
        FLEXMacGlobal(@"rectangle.and.text.magnifyingglass", @"First Responder", ^id {
            return FLEXMacUtility.appKeyWindow.firstResponder;
        }),
        FLEXMacGlobal(@"doc.on.doc", @"Document Controller", ^id { return NSDocumentController.sharedDocumentController; }),
    ]]];

    [sections addObject:[FLEXMacSection title:@"Process & System" rows:@[
        FLEXMacGlobal(@"shippingbox", @"Main Bundle", ^id { return NSBundle.mainBundle; }),
        FLEXMacGlobal(@"cpu", @"Process Info", ^id { return NSProcessInfo.processInfo; }),
        FLEXMacGlobal(@"gearshape", @"Standard User Defaults", ^id { return NSUserDefaults.standardUserDefaults; }),
        FLEXMacGlobal(@"doc", @"File Manager", ^id { return NSFileManager.defaultManager; }),
        FLEXMacGlobal(@"desktopcomputer", @"Workspace", ^id { return NSWorkspace.sharedWorkspace; }),
        FLEXMacGlobal(@"bell", @"Notification Center", ^id { return NSNotificationCenter.defaultCenter; }),
        FLEXMacGlobal(@"doc.on.clipboard", @"General Pasteboard", ^id { return NSPasteboard.generalPasteboard; }),
        FLEXMacTool(@"display", @"Screens", nil, ^NSViewController *{
            return [FLEXMacObjectListViewController listWithTitle:@"Screens" objects:NSScreen.screens];
        }),
        FLEXMacGlobal(@"textformat", @"Font Manager", ^id { return NSFontManager.sharedFontManager; }),
        FLEXMacGlobal(@"arrow.triangle.2.circlepath", @"Main Run Loop", ^id { return NSRunLoop.mainRunLoop; }),
        FLEXMacGlobal(@"point.3.connected.trianglepath.dotted", @"Main Thread", ^id { return NSThread.mainThread; }),
        FLEXMacGlobal(@"network", @"Shared URL Session", ^id { return NSURLSession.sharedSession; }),
        FLEXMacGlobal(@"externaldrive", @"Shared URL Cache", ^id { return NSURLCache.sharedURLCache; }),
    ]]];

    return sections;
}

- (FLEXMacRow *)actionRowWithSymbol:(NSString *)symbol title:(NSString *)title subtitle:(NSString *)subtitle action:(void(^)(void))action {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:subtitle];
    row.image = [FLEXMacUtility symbol:symbol];
    row.action = ^(NSViewController *host) {
        action();
    };
    return row;
}

- (void)exploreAddress {
    [FLEXMacUtility promptWithTitle:@"Explore Address" message:@"Enter the hex address of an object" defaultValue:@"0x" completion:^(NSString *text) {
        if (!text.length) {
            return;
        }
        unsigned long long address = 0;
        NSScanner *scanner = [NSScanner scannerWithString:text];
        if (![scanner scanHexLongLong:&address] || !scanner.isAtEnd) {
            [FLEXMacUtility showAlertWithTitle:@"Invalid Address" message:text];
            return;
        }
        const void *pointer = (const void *)(uintptr_t)address;
        if (!FLEXPointerIsValidObjcObject(pointer)) {
            [FLEXMacUtility showAlertWithTitle:@"Invalid Object" message:[NSString stringWithFormat:@"%@ is not a valid Objective-C object", text]];
            return;
        }
        [self flex_push:[FLEXMacObjectExplorerViewController explorerForObject:(__bridge id)pointer]];
    }];
}

- (void)exploreClass {
    [FLEXMacUtility promptWithTitle:@"Explore Class" message:@"Enter a class name" defaultValue:@"" completion:^(NSString *text) {
        if (!text.length) {
            return;
        }
        Class cls = NSClassFromString([text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]);
        if (!cls) {
            [FLEXMacUtility showAlertWithTitle:@"Class Not Found" message:text];
            return;
        }
        [self flex_push:[FLEXMacObjectExplorerViewController explorerForObject:cls]];
    }];
}

@end
