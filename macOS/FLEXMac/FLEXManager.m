//
//  FLEXManager.m
//  FLEX (macOS)
//

#import "FLEXManager+Private.h"
#import "FLEXMacToolbarPanel.h"
#import "FLEXMacExplorerWindowController.h"
#import "FLEXMacGlobalsViewController.h"
#import "FLEXMacViewHierarchyViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacNetworkViewController.h"
#import "FLEXMacViewSelector.h"
#import "FLEXMacHighlightWindow.h"
#import "FLEXMacUtility.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"

@interface FLEXManager () <FLEXMacToolbarPanelDelegate>
@property (nonatomic) FLEXMacToolbarPanel *toolbar;
@property (nonatomic) NSMutableArray<FLEXMacRow *> *userEntries;
@property (nonatomic) id keyMonitor;
@property (nonatomic, weak) NSView *selectedView;
@end

@implementation FLEXManager

+ (FLEXManager *)sharedManager {
    static FLEXManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userEntries = [NSMutableArray new];
        _keyboardShortcutKey = @"f";
        _keyboardShortcutModifiers = NSEventModifierFlagCommand | NSEventModifierFlagOption;
        [FLEXMacUtility startTrackingKeyWindow];
        self.keyboardShortcutEnabled = YES;
    }
    return self;
}

#pragma mark Showing and hiding

- (FLEXMacToolbarPanel *)toolbar {
    NSAssert(NSThread.isMainThread, @"You must use %@ from the main thread only.", NSStringFromClass([self class]));
    if (!_toolbar) {
        _toolbar = [FLEXMacToolbarPanel toolbar];
        _toolbar.toolbarDelegate = self;
    }
    return _toolbar;
}

- (BOOL)isHidden {
    return !_toolbar.isVisible;
}

- (void)showExplorer {
    [FLEXMacUtility startTrackingKeyWindow];
    [self.toolbar orderFrontRegardless];
    self.toolbar.selectedView = self.selectedView;
}

- (void)hideExplorer {
    [FLEXMacViewSelector.sharedSelector cancel];
    [FLEXMacHighlightWindow.selectionHighlight highlightView:nil];
    [_toolbar orderOut:nil];
    [FLEXMacExplorerWindowController.sharedController hide];
}

- (void)toggleExplorer {
    if (self.isHidden) {
        [self showExplorer];
    } else {
        [self hideExplorer];
    }
}

- (void)showGlobals {
    [self showExplorer];
    [FLEXMacExplorerWindowController.sharedController showRootViewController:[FLEXMacGlobalsViewController new]];
}

- (void)showViewHierarchy {
    [self showExplorer];
    [FLEXMacExplorerWindowController.sharedController showRootViewController:
        [FLEXMacViewHierarchyViewController hierarchyFocusingOnView:self.selectedView]
    ];
}

- (void)showNetworkHistory {
    [self showExplorer];
    [FLEXMacExplorerWindowController.sharedController showRootViewController:[FLEXMacNetworkViewController new]];
}

- (void)beginViewSelection {
    [self showExplorer];
    self.toolbar.selecting = YES;

    __weak typeof(self) weakSelf = self;
    [FLEXMacViewSelector.sharedSelector beginWithHandler:^(NSView *view) {
        weakSelf.toolbar.selecting = NO;
        if (view) {
            weakSelf.selectedView = view;
        }
        // On cancel, the selector has already cleared the on-screen outline;
        // don't bring back an old one.
    }];
}

- (void)presentObjectExplorer:(id)object {
    NSViewController *explorer = [FLEXMacObjectExplorerViewController explorerForObject:object];
    if (explorer) {
        [self showExplorer];
        [FLEXMacExplorerWindowController.sharedController pushViewController:explorer];
    }
}

- (void)presentTool:(NSViewController *(^)(void))viewControllerFuture {
    NSViewController *controller = viewControllerFuture ? viewControllerFuture() : nil;
    if (controller) {
        [self showExplorer];
        [FLEXMacExplorerWindowController.sharedController pushViewController:controller];
    }
}

- (void)setSelectedView:(NSView *)view {
    _selectedView = view;
    _toolbar.selectedView = view;
}

#pragma mark FLEXMacToolbarPanelDelegate

- (void)toolbarDidSelectGlobals:(FLEXMacToolbarPanel *)toolbar {
    [self showGlobals];
}

- (void)toolbarDidSelectHierarchy:(FLEXMacToolbarPanel *)toolbar {
    [self showViewHierarchy];
}

- (void)toolbarDidSelectSelect:(FLEXMacToolbarPanel *)toolbar {
    if (FLEXMacViewSelector.sharedSelector.isActive) {
        [FLEXMacViewSelector.sharedSelector cancel];
    } else {
        [self beginViewSelection];
    }
}

- (void)toolbarDidSelectNetwork:(FLEXMacToolbarPanel *)toolbar {
    [self showNetworkHistory];
}

- (void)toolbarDidSelectDetails:(FLEXMacToolbarPanel *)toolbar {
    if (self.selectedView) {
        [FLEXMacExplorerWindowController.sharedController showRootViewController:
            [FLEXMacObjectExplorerViewController explorerForObject:self.selectedView]
        ];
    }
}

- (void)toolbarDidSelectClose:(FLEXMacToolbarPanel *)toolbar {
    [self hideExplorer];
}

#pragma mark Keyboard shortcut

- (void)setKeyboardShortcutEnabled:(BOOL)enabled {
    _keyboardShortcutEnabled = enabled;
    if (enabled && !self.keyMonitor) {
        __weak typeof(self) weakSelf = self;
        self.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
            return [weakSelf handleKeyDown:event];
        }];
    } else if (!enabled && self.keyMonitor) {
        [NSEvent removeMonitor:self.keyMonitor];
        self.keyMonitor = nil;
    }
}

- (NSEvent *)handleKeyDown:(NSEvent *)event {
    NSEventModifierFlags relevant = NSEventModifierFlagCommand | NSEventModifierFlagOption |
        NSEventModifierFlagControl | NSEventModifierFlagShift;
    NSEventModifierFlags flags = event.modifierFlags & relevant;
    if (flags == (self.keyboardShortcutModifiers & relevant) &&
        [event.charactersIgnoringModifiers.lowercaseString isEqualToString:self.keyboardShortcutKey.lowercaseString]) {
        [self toggleExplorer];
        return nil;
    }
    return event;
}

- (void)installMainMenuItem {
    NSMenu *mainMenu = NSApp.mainMenu;
    if (!mainMenu) {
        return;
    }

    NSMenu *target = NSApp.windowsMenu;
    if (!target) {
        NSMenuItem *debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
        target = [[NSMenu alloc] initWithTitle:@"Debug"];
        debugItem.submenu = target;
        [mainMenu addItem:debugItem];
    } else {
        [target addItem:NSMenuItem.separatorItem];
    }

    NSMenuItem *item = [[NSMenuItem alloc]
        initWithTitle:@"Explore with FLEX" action:@selector(toggleExplorer) keyEquivalent:@""
    ];
    item.target = self;
    // The key monitor handles the shortcut; only display it here
    if (self.keyboardShortcutEnabled) {
        item.keyEquivalent = self.keyboardShortcutKey;
        item.keyEquivalentModifierMask = self.keyboardShortcutModifiers;
    }
    [target addItem:item];
}

#pragma mark Globals

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(FLEXGlobalsEntryObjectFuture)objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    FLEXMacRow *row = [FLEXMacRow title:entryName subtitle:nil pushing:^NSViewController *{
        return [FLEXMacObjectExplorerViewController explorerForObject:objectFutureBlock()];
    }];
    [self.userEntries addObject:row];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(FLEXGlobalsEntryViewControllerFuture)viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    FLEXMacRow *row = [FLEXMacRow title:entryName subtitle:nil pushing:viewControllerFutureBlock];
    [self.userEntries addObject:row];
}

- (NSArray<FLEXMacRow *> *)userGlobalEntryRows {
    return self.userEntries.copy;
}

#pragma mark Networking

- (BOOL)isNetworkDebuggingEnabled {
    return FLEXNetworkObserver.isEnabled;
}

- (void)setNetworkDebuggingEnabled:(BOOL)networkDebuggingEnabled {
    FLEXNetworkObserver.enabled = networkDebuggingEnabled;
}

- (NSUInteger)networkResponseCacheByteLimit {
    return FLEXNetworkRecorder.defaultRecorder.responseCacheByteLimit;
}

- (void)setNetworkResponseCacheByteLimit:(NSUInteger)networkResponseCacheByteLimit {
    FLEXNetworkRecorder.defaultRecorder.responseCacheByteLimit = networkResponseCacheByteLimit;
}

- (NSMutableArray<NSString *> *)networkRequestHostDenylist {
    return FLEXNetworkRecorder.defaultRecorder.hostDenylist;
}

- (void)setNetworkRequestHostDenylist:(NSMutableArray<NSString *> *)networkRequestHostDenylist {
    FLEXNetworkRecorder.defaultRecorder.hostDenylist = networkRequestHostDenylist;
}

@end
