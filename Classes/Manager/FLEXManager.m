//
//  FLEXManager.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXUtility.h"
#import "FLEXExplorerViewController.h"
#import "FLEXWindow.h"
#import "FLEXNavigationController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFileBrowserController.h"

@interface FLEXManager () <FLEXWindowEventDelegate, FLEXExplorerViewControllerDelegate>

@property (nonatomic, readonly, getter=isHidden) BOOL hidden;

@property (nonatomic) FLEXWindow *explorerWindow;
@property (nonatomic) FLEXExplorerViewController *explorerViewController;

@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *userGlobalEntries;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, FLEXCustomContentViewerFuture> *customContentTypeViewers;

@end

@implementation FLEXManager

+ (instancetype)sharedManager {
    static FLEXManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userGlobalEntries = [NSMutableArray new];
        _customContentTypeViewers = [NSMutableDictionary new];
    }
    return self;
}

- (FLEXWindow *)explorerWindow {
    NSAssert(NSThread.isMainThread, @"You must use %@ from the main thread only.", NSStringFromClass([self class]));
    
    if (!_explorerWindow) {
        _explorerWindow = [[FLEXWindow alloc] initWithFrame:FLEXUtility.appKeyWindow.bounds];
        _explorerWindow.eventDelegate = self;
        _explorerWindow.rootViewController = self.explorerViewController;
    }
    
    return _explorerWindow;
}

- (FLEXExplorerViewController *)explorerViewController {
    if (!_explorerViewController) {
        _explorerViewController = [FLEXExplorerViewController new];
        _explorerViewController.delegate = self;
    }

    return _explorerViewController;
}

- (void)showExplorer {
    UIWindow *flex = self.explorerWindow;
    flex.hidden = NO;
    if (@available(iOS 13.0, *)) {
        // Only look for a new scene if we don't have one
        if (!flex.windowScene) {
            flex.windowScene = FLEXUtility.appKeyWindow.windowScene;
        }
    }
}

- (void)hideExplorer {
    self.explorerWindow.hidden = YES;
}

- (void)toggleExplorer {
    if (self.explorerWindow.isHidden) {
        if (@available(iOS 13.0, *)) {
            [self showExplorerFromScene:FLEXUtility.appKeyWindow.windowScene];
        } else {
            [self showExplorer];
        }
    } else {
        [self hideExplorer];
    }
}

- (void)dismissAnyPresentedTools:(void (^)(void))completion {
    if (self.explorerViewController.presentedViewController) {
        [self.explorerViewController dismissViewControllerAnimated:YES completion:completion];
    } else if (completion) {
        completion();
    }
}

- (void)presentTool:(UINavigationController * _Nonnull (^)(void))future completion:(void (^)(void))completion {
    [self showExplorer];
    [self.explorerViewController presentTool:future completion:completion];
}

- (void)presentEmbeddedTool:(UIViewController *)tool completion:(void (^)(UINavigationController *))completion {
    FLEXNavigationController *nav = [FLEXNavigationController withRootViewController:tool];
    [self presentTool:^UINavigationController *{
        return nav;
    } completion:^{
        if (completion) completion(nav);
    }];
}

- (void)presentObjectExplorer:(id)object completion:(void (^)(UINavigationController *))completion {
    UIViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
    [self presentEmbeddedTool:explorer completion:completion];
}

- (void)showExplorerFromScene:(UIWindowScene *)scene {
    if (@available(iOS 13.0, *)) {
        self.explorerWindow.windowScene = scene;
    }
    self.explorerWindow.hidden = NO;
}

- (BOOL)isHidden {
    return self.explorerWindow.isHidden;
}

- (FLEXExplorerToolbar *)toolbar {
    return self.explorerViewController.explorerToolbar;
}


#pragma mark - FLEXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow {
    // Ask the explorer view controller
    return [self.explorerViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}

- (BOOL)canBecomeKeyWindow {
    // Only when the explorer view controller wants it because
    // it needs to accept key input & affect the status bar.
    return self.explorerViewController.wantsWindowToBecomeKey;
}


#pragma mark - FLEXExplorerViewControllerDelegate

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController {
    [self hideExplorer];
}

@end
