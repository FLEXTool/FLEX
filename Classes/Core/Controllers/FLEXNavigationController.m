//
//  FLEXNavigationController.m
//  FLEX
//
//  Created by Tanner on 1/30/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXNavigationController.h"
#import "FLEXExplorerViewController.h"
#import "FLEXTabList.h"

@interface UINavigationController (Private) <UIGestureRecognizerDelegate>
- (void)_gestureRecognizedInteractiveHide:(UIGestureRecognizer *)sender;
@end
@interface UIPanGestureRecognizer (Private)
- (void)_setDelegate:(id)delegate;
@end

@interface FLEXNavigationController ()
@property (nonatomic, readonly) BOOL toolbarWasHidden;
@property (nonatomic) BOOL waitingToAddTab;
@end

@implementation FLEXNavigationController

+ (instancetype)withRootViewController:(UIViewController *)rootVC {
    FLEXNavigationController *instance =  [[self alloc] initWithRootViewController:rootVC];
    
    // Give root view controllers a Done button
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:instance
        action:@selector(dismissAnimated)
    ];
    
    // Prepend the button if other buttons exist already
    NSArray *existingItems = rootVC.navigationItem.rightBarButtonItems;
    if (existingItems.count) {
        rootVC.navigationItem.rightBarButtonItems = [@[done] arrayByAddingObjectsFromArray:existingItems];
    } else {
        rootVC.navigationItem.rightBarButtonItem = done;
    }
    
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.waitingToAddTab = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.waitingToAddTab) {
        // Only add new tab if we're presented properly
        if ([self.presentingViewController isKindOfClass:[FLEXExplorerViewController class]]) {
            // New navigation controllers always add themselves as new tabs,
            // tabs are closed by FLEXExplorerViewController
            [FLEXTabList.sharedList addTab:self];
            self.waitingToAddTab = NO;
        }
    }
}

- (void)dismissAnimated {
    // TODO tabs not closed on swipe down gesture
    [FLEXTabList.sharedList closeTab:self];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_gestureRecognizedInteractiveHide:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        BOOL show = self.topViewController.toolbarItems.count;
        CGFloat yTranslation = [sender translationInView:self.view].y;
        CGFloat yVelocity = [sender velocityInView:self.view].y;
        if (yVelocity > 2000) {
            [self setToolbarHidden:YES animated:YES];
        } else if (show && yTranslation > 20 && yVelocity > 250) {
            [self setToolbarHidden:NO animated:YES];
        } else if (yTranslation < -20) {
            [self setToolbarHidden:YES animated:YES];
        }
    }
}

@end
