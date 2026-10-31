//
//  FLEXMacExplorerWindowController.m
//  FLEX (macOS)
//

#import "FLEXMacExplorerWindowController.h"
#import "FLEXMacHighlightWindow.h"

@implementation FLEXMacExplorerWindow
// A titled panel does not become key by default; FLEX needs to type into
// search fields and editors, so allow it.
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface FLEXMacExplorerWindowController () <NSWindowDelegate>
@property (nonatomic) FLEXMacNavigationController *navigationController;
@end

@implementation FLEXMacExplorerWindowController

+ (FLEXMacExplorerWindowController *)sharedController {
    static FLEXMacExplorerWindowController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

- (instancetype)init {
    FLEXMacExplorerWindow *window = [[FLEXMacExplorerWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 560, 720)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                  NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered
        defer:YES
    ];
    window.title = @"FLEX";
    window.releasedWhenClosed = NO;
    window.minSize = NSMakeSize(380, 320);
    window.hidesOnDeactivate = NO;
    window.tabbingMode = NSWindowTabbingModeDisallowed;
    // Float above the host app's windows, join every Space / full-screen app,
    // and keep receiving events while the host runs a modal alert.
    window.level = NSFloatingWindowLevel;
    window.floatingPanel = YES;
    window.becomesKeyOnlyIfNeeded = NO;
    window.worksWhenModal = YES;
    window.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorCanJoinAllSpaces;

    self = [super initWithWindow:window];
    if (self) {
        window.delegate = self;
        [window center];
        [window setFrameAutosaveName:@"com.flex.explorer.window"];
    }
    return self;
}

- (BOOL)isVisible {
    return self.window.isVisible;
}

- (FLEXMacNavigationController *)navigationControllerWithRoot:(NSViewController *)root {
    if (!self.navigationController) {
        self.navigationController = [[FLEXMacNavigationController alloc] initWithRootViewController:root];
        NSRect frame = self.window.frame;
        self.window.contentViewController = self.navigationController;
        // Assigning a content view controller resizes the window; restore the saved frame
        [self.window setFrame:frame display:NO];
    } else {
        [self.navigationController setRootViewController:root];
    }
    return self.navigationController;
}

- (void)showRootViewController:(NSViewController *)viewController {
    [self navigationControllerWithRoot:viewController];
    [self present];
}

- (void)pushViewController:(NSViewController *)viewController {
    if (!self.navigationController || !self.isVisible) {
        [self showRootViewController:viewController];
    } else {
        [self.navigationController pushViewController:viewController];
        [self present];
    }
}

- (void)present {
    [self showWindow:nil];
    [self.window makeKeyAndOrderFront:nil];
    if (!NSApp.isActive) {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)hide {
    [self.window orderOut:nil];
}

#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    // Don't leave a selection outline on screen after the window is gone.
    [FLEXMacHighlightWindow.selectionHighlight highlightView:nil];
}

@end
