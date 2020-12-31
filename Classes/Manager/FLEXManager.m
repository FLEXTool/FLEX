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
#import "FLEXObjectExplorerViewController.h"
#import "FLEXFileBrowserController.h"
#import "NSObject+FLEX_Reflection.h"

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
        _explorerWindow = [[FLEXWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        _explorerWindow.eventDelegate = self;
        _explorerWindow.rootViewController = self.explorerViewController;
    }
    
    return _explorerWindow;
}

- (void)showHintsIfNecessary {
    BOOL dontShowHints = [[NSUserDefaults standardUserDefaults] boolForKey:@"DontShowHintsOnLaunch"];
    if (!dontShowHints){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showHintsAlert];
        });
    }
}

- (void)showHintsAlert {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Usage Guide"
                                          message:@"Triple tap 'Play/Pause' to hide or show the explorer view.\nIn selection mode 'Menu' will exit to the toolbar, and a long press on 'Select', 'Play/Pause' or a right siri tap/arrow click will bring up a contextual menu for view info & movement.\nWhen browsing view/object details a long press on 'Select' or a right siri tap/arrow click will bring up the controller to edit view details.\nIf you inject into HeadBoard the siri remote will NOT work for navigation and you will need to use something like AirMagic to navigate."
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *hideForeverAction = [UIAlertAction
                                        actionWithTitle:@"Don't Show This Again"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                                        {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DontShowHintsOnLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showExplorer];
    }];
    UIAlertAction *showForeverAction = [UIAlertAction
                                        actionWithTitle:@"Always Show On Launch"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                                        {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DontShowHintsOnLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showExplorer];
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Dismiss"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
        [self showExplorer];
    }];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontShowHintsOnLaunch"]) {
        [alertController addAction:showForeverAction];
    }
    else {
        [alertController addAction:hideForeverAction];
    }
    [alertController addAction:cancelAction];
    
    #if TARGET_OS_TV
    [[self topViewController] presentViewController:alertController animated:YES completion:nil];
    #endif
}

- (void)tripleTap:(UITapGestureRecognizer *)tapRecognizer {
    FXLog(@"triple tap!");
    if ([self isHidden]){
        [self showExplorer];
    } else {
        [self hideExplorer];
    }
}


- (void)_addTVOSGestureRecognizer:(UIViewController *)explorer {
    UITapGestureRecognizer *tripleTaps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tripleTap:)];
    tripleTaps.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    tripleTaps.numberOfTapsRequired = 3;
    [explorer.view addGestureRecognizer:tripleTaps];
}

- (FLEXExplorerViewController *)explorerViewController {
    if (!_explorerViewController) {
        _explorerViewController = [FLEXExplorerViewController new];
        _explorerViewController.delegate = self;
        #if TARGET_OS_TV
                [self _addTVOSGestureRecognizer:_explorerViewController];
        #endif
    }

    return _explorerViewController;
}

- (void)showExplorer {
    UIWindow *flex = self.explorerWindow;
    flex.hidden = NO;
    #if TARGET_OS_TV
    FLEXWindow *exp = [self explorerWindow];
    [exp makeKeyWindow];
    #endif
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        // Only look for a new scene if we don't have one
        if (!flex.windowScene) {
            flex.windowScene = FLEXUtility.activeScene;
        }
    }
#endif
}

- (void)hideExplorer {
    self.explorerWindow.hidden = YES;
}

- (void)toggleExplorer {
    if (self.explorerWindow.isHidden) {
        [self showExplorer];
    } else {
        [self hideExplorer];
    }
}

- (void)showExplorerFromScene:(UIWindowScene *)scene {
    #if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        self.explorerWindow.windowScene = scene;
    }
    #endif
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
