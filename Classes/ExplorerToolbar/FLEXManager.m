//
//  FLEXManager.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXWindow.h"
#import "FLEXGlobalsTableViewControllerEntry.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXKeyboardShortcutManager.h"
#import "FLEXFileBrowserTableViewController.h"
#import "FLEXNetworkHistoryTableViewController.h"
#import "FLEXKeyboardHelpViewController.h"

@interface FLEXManager () <FLEXWindowEventDelegate, FLEXExplorerViewControllerDelegate>

@property (nonatomic, strong) FLEXWindow *explorerWindow;
@property (nonatomic, strong) FLEXExplorerViewController *explorerViewController;

@property (nonatomic, readonly, strong) NSMutableArray *userGlobalEntries;

@end

@implementation FLEXManager

+ (instancetype)sharedManager
{
    static FLEXManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userGlobalEntries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (FLEXWindow *)explorerWindow
{
    NSAssert([NSThread isMainThread], @"You must use %@ from the main thread only.", NSStringFromClass([self class]));
    
    if (!_explorerWindow) {
        _explorerWindow = [[FLEXWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _explorerWindow.eventDelegate = self;
        _explorerWindow.rootViewController = self.explorerViewController;
    }
    
    return _explorerWindow;
}

- (FLEXExplorerViewController *)explorerViewController
{
    if (!_explorerViewController) {
        _explorerViewController = [[FLEXExplorerViewController alloc] init];
        _explorerViewController.delegate = self;
    }

    return _explorerViewController;
}

- (void)showExplorer
{
    self.explorerWindow.hidden = NO;
}

- (void)hideExplorer
{
    self.explorerWindow.hidden = YES;
}

- (void)toggleExplorer {
    if (self.explorerWindow.isHidden) {
        [self showExplorer];
    } else {
        [self hideExplorer];
    }
}

- (BOOL)isHidden
{
    return self.explorerWindow.isHidden;
}

- (BOOL)isNetworkDebuggingEnabled
{
    return [FLEXNetworkObserver isEnabled];
}

- (void)setNetworkDebuggingEnabled:(BOOL)networkDebuggingEnabled
{
    [FLEXNetworkObserver setEnabled:networkDebuggingEnabled];
}

- (NSUInteger)networkResponseCacheByteLimit
{
    return [[FLEXNetworkRecorder defaultRecorder] responseCacheByteLimit];
}

- (void)setNetworkResponseCacheByteLimit:(NSUInteger)networkResponseCacheByteLimit
{
    [[FLEXNetworkRecorder defaultRecorder] setResponseCacheByteLimit:networkResponseCacheByteLimit];
}

#pragma mark - FLEXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow
{
    // Ask the explorer view controller
    return [self.explorerViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}

- (BOOL)canBecomeKeyWindow
{
    // Only when the explorer view controller wants it because it needs to accept key input & affect the status bar.
    return [self.explorerViewController wantsWindowToBecomeKey];
}


#pragma mark - FLEXExplorerViewControllerDelegate

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController
{
    [self hideExplorer];
}

#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description
{
# if TARGET_OS_SIMULATOR
    [[FLEXKeyboardShortcutManager sharedManager] registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description];
#endif
}

- (void)setSimulatorShortcutsEnabled:(BOOL)simulatorShortcutsEnabled
{
# if TARGET_OS_SIMULATOR
    [[FLEXKeyboardShortcutManager sharedManager] setEnabled:simulatorShortcutsEnabled];
#endif
}

- (BOOL)simulatorShortcutsEnabled
{
# if TARGET_OS_SIMULATOR
    return [[FLEXKeyboardShortcutManager sharedManager] isEnabled];
#else
    return NO;
#endif
}

- (void)registerDefaultSimulatorShortcuts
{
    [self registerSimulatorShortcutWithKey:@"f" modifiers:0 action:^{
        [self toggleExplorer];
    } description:@"Toggle FLEX toolbar"];
    
    [self registerSimulatorShortcutWithKey:@"g" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMenuTool];
    } description:@"Toggle FLEX globlas menu"];
    
    [self registerSimulatorShortcutWithKey:@"v" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleViewsTool];
    } description:@"Toggle view hierarchy menu"];
    
    [self registerSimulatorShortcutWithKey:@"s" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleSelectTool];
    } description:@"Toggle select tool"];
    
    [self registerSimulatorShortcutWithKey:@"m" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMoveTool];
    } description:@"Toggle move tool"];
    
    [self registerSimulatorShortcutWithKey:@"n" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXNetworkHistoryTableViewController class]];
    } description:@"Toggle network history view"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputDownArrow modifiers:0 action:^{
        if ([self isHidden]) {
            [self tryScrollDown];
        } else {
            [self.explorerViewController handleDownArrowKeyPressed];
        }
    } description:@"Cycle view selection\n\t\tMove view down\n\t\tScroll down"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputUpArrow modifiers:0 action:^{
        if ([self isHidden]) {
            [self tryScrollUp];
        } else {
            [self.explorerViewController handleUpArrowKeyPressed];
        }
    } description:@"Cycle view selection\n\t\tMove view up\n\t\tScroll up"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputRightArrow modifiers:0 action:^{
        if (![self isHidden]) {
            [self.explorerViewController handleRightArrowKeyPressed];
        }
    } description:@"Move selected view right"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputLeftArrow modifiers:0 action:^{
        if ([self isHidden]) {
            [self tryGoBack];
        } else {
            [self.explorerViewController handleLeftArrowKeyPressed];
        }
    } description:@"Move selected view left"];
    
    [self registerSimulatorShortcutWithKey:@"?" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXKeyboardHelpViewController class]];
    } description:@"Toggle (this) help menu"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputEscape modifiers:0 action:^{
        [[[self topViewController] presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } description:@"End editing text\n\t\tDismiss top view controller"];
    
    [self registerSimulatorShortcutWithKey:@"o" modifiers:UIKeyModifierCommand|UIKeyModifierShift action:^{
        [self toggleTopViewControllerOfClass:[FLEXFileBrowserTableViewController class]];
    } description:@"Toggle file browser menu"];
}

+ (void)load
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self class] sharedManager] registerDefaultSimulatorShortcuts];
    });
}

#pragma mark - Extensions

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock
{
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsTableViewControllerEntry *entry = [FLEXGlobalsTableViewControllerEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock
{
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsTableViewControllerEntry *entry = [FLEXGlobalsTableViewControllerEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)tryScrollDown
{
    UIScrollView *firstScrollView = [self firstScrollView];
    CGPoint contentOffset = [firstScrollView contentOffset];
    CGFloat distance = floor(firstScrollView.frame.size.height / 2.0);
    CGFloat maxContentOffsetY = firstScrollView.contentSize.height + firstScrollView.contentInset.bottom - firstScrollView.frame.size.height;
    distance = MIN(maxContentOffsetY - firstScrollView.contentOffset.y, distance);
    contentOffset.y += distance;
    [firstScrollView setContentOffset:contentOffset animated:YES];
}

- (void)tryScrollUp
{
    UIScrollView *firstScrollView = [self firstScrollView];
    CGPoint contentOffset = [firstScrollView contentOffset];
    CGFloat distance = floor(firstScrollView.frame.size.height / 2.0);
    CGFloat minContentOffsetY = -firstScrollView.contentInset.top;
    distance = MIN(firstScrollView.contentOffset.y - minContentOffsetY, distance);
    contentOffset.y -= distance;
    [firstScrollView setContentOffset:contentOffset animated:YES];
}

- (UIScrollView *)firstScrollView
{
    NSMutableArray *views = [[[[UIApplication sharedApplication] keyWindow] subviews] mutableCopy];
    UIScrollView *scrollView = nil;
    while ([views count] > 0) {
        UIView *view = [views firstObject];
        [views removeObjectAtIndex:0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
            break;
        } else {
            [views addObjectsFromArray:[view subviews]];
        }
    }
    return scrollView;
}

- (void)tryGoBack
{
    UINavigationController *navigationController = nil;
    UIViewController *topViewController = [self topViewController];
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)topViewController;
    } else {
        navigationController = topViewController.navigationController;
    }
    [navigationController popViewControllerAnimated:YES];
}

- (UIViewController *)topViewController
{
    UIViewController *topViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    while ([topViewController presentedViewController]) {
        topViewController = [topViewController presentedViewController];
    }
    return topViewController;
}

- (void)toggleTopViewControllerOfClass:(Class)class
{
    UIViewController *topViewController = [self topViewController];
    if ([topViewController isKindOfClass:[UINavigationController class]] && [[[(UINavigationController *)topViewController viewControllers] firstObject] isKindOfClass:[class class]]) {
        [[topViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        id viewController = [[class alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [topViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)showExplorerIfNeeded
{
    if ([self isHidden]) {
        [self showExplorer];
    }
}

@end
