//
//  FLEXManager+Extensibility.m
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager+Extensibility.h"
#import "FLEXManager+Private.h"
#import "FLEXNavigationController.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXKeyboardShortcutManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXKeyboardHelpViewController.h"
#import "FLEXFileBrowserController.h"
#import "FLEXUtility.h"

@interface FLEXManager (ExtensibilityPrivate)
@property (nonatomic, readonly) UIViewController *topViewController;
@end

@implementation FLEXManager (Extensibility)

#pragma mark - Globals Screen Entries

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)clearGlobalEntries
{
  [self.userGlobalEntries removeAllObjects];
}


#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    [FLEXKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:YES];
#endif
}

- (void)setSimulatorShortcutsEnabled:(BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    [FLEXKeyboardShortcutManager.sharedManager setEnabled:simulatorShortcutsEnabled];
#endif
}

- (BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    return FLEXKeyboardShortcutManager.sharedManager.isEnabled;
#else
    return NO;
#endif
}


#pragma mark - Shortcuts Defaults

- (void)registerDefaultSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    // Don't allow override to avoid changing keys registered by the app
    [FLEXKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:NO];
#endif
}

- (void)registerDefaultSimulatorShortcuts {
    [self registerDefaultSimulatorShortcutWithKey:@"f" modifiers:0 action:^{
        [self toggleExplorer];
    } description:@"Toggle FLEX toolbar"];

    [self registerDefaultSimulatorShortcutWithKey:@"g" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMenuTool];
    } description:@"Toggle FLEX globals menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"v" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleViewsTool];
    } description:@"Toggle view hierarchy menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"s" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleSelectTool];
    } description:@"Toggle select tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"m" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMoveTool];
    } description:@"Toggle move tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"n" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXNetworkMITMViewController class]];
    } description:@"Toggle network history view"];

    // 't' is for testing: quickly present an object explorer for debugging
    [self registerDefaultSimulatorShortcutWithKey:@"t" modifiers:0 action:^{
        [self showExplorerIfNeeded];

        [self.explorerViewController toggleToolWithViewControllerProvider:^UINavigationController *{
            return [FLEXNavigationController withRootViewController:[FLEXObjectExplorerFactory
                explorerViewControllerForObject:NSBundle.mainBundle
            ]];
        } completion:nil];
    } description:@"Present an object explorer for debugging"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputDownArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleDownArrowKeyPressed]) {
            [self tryScrollDown];
        }
    } description:@"Cycle view selection\n\t\tMove view down\n\t\tScroll down"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputUpArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleUpArrowKeyPressed]) {
            [self tryScrollUp];
        }
    } description:@"Cycle view selection\n\t\tMove view up\n\t\tScroll up"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputRightArrow modifiers:0 action:^{
        if (!self.isHidden) {
            [self.explorerViewController handleRightArrowKeyPressed];
        }
    } description:@"Move selected view right"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputLeftArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryGoBack];
        } else {
            [self.explorerViewController handleLeftArrowKeyPressed];
        }
    } description:@"Move selected view left"];

    [self registerDefaultSimulatorShortcutWithKey:@"?" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXKeyboardHelpViewController class]];
    } description:@"Toggle (this) help menu"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputEscape modifiers:0 action:^{
        [[self.topViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } description:@"End editing text\n\t\tDismiss top view controller"];

    [self registerDefaultSimulatorShortcutWithKey:@"o" modifiers:UIKeyModifierCommand|UIKeyModifierShift action:^{
        [self toggleTopViewControllerOfClass:[FLEXFileBrowserController class]];
    } description:@"Toggle file browser menu"];
}

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sharedManager registerDefaultSimulatorShortcuts];
    });
}


#pragma mark - Private

- (UIEdgeInsets)contentInsetsOfScrollView:(UIScrollView *)scrollView {
    if (@available(iOS 11, *)) {
        return scrollView.adjustedContentInset;
    }

    return scrollView.contentInset;
}

- (void)tryScrollDown {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    CGFloat maxYOffset = scrollview.contentSize.height - scrollview.bounds.size.height + insets.bottom;
    contentOffset.y = MIN(contentOffset.y + 200, maxYOffset);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (void)tryScrollUp {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    contentOffset.y = MAX(contentOffset.y - 200, -insets.top);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (UIScrollView *)firstScrollView {
    NSMutableArray<UIView *> *views = FLEXUtility.appKeyWindow.subviews.mutableCopy;
    UIScrollView *scrollView = nil;
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
            break;
        } else {
            [views addObjectsFromArray:view.subviews];
        }
    }
    return scrollView;
}

- (void)tryGoBack {
    UINavigationController *navigationController = nil;
    UIViewController *topViewController = self.topViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)topViewController;
    } else {
        navigationController = topViewController.navigationController;
    }
    [navigationController popViewControllerAnimated:YES];
}

- (UIViewController *)topViewController {
    return [FLEXUtility topViewControllerInWindow:UIApplication.sharedApplication.keyWindow];
}

- (void)toggleTopViewControllerOfClass:(Class)class {
    UINavigationController *topViewController = (id)self.topViewController;
    if ([topViewController isKindOfClass:[FLEXNavigationController class]]) {
        if ([topViewController.topViewController isKindOfClass:[class class]]) {
            if (topViewController.viewControllers.count == 1) {
                // Dismiss since we are already presenting it
                [topViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                // Pop since we are viewing it but it's not the only thing on the stack
                [topViewController popViewControllerAnimated:YES];
            }
        } else {
            // Push it on the existing navigation stack
            [topViewController pushViewController:[class new] animated:YES];
        }
    } else {
        // Present it in an entirely new navigation controller
        [self.explorerViewController presentViewController:
            [FLEXNavigationController withRootViewController:[class new]]
        animated:YES completion:nil];
    }
}

- (void)showExplorerIfNeeded {
    if (self.isHidden) {
        [self showExplorer];
    }
}

@end
