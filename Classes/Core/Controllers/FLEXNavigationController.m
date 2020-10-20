//
//  FLEXNavigationController.m
//  FLEX
//
//  Created by Tanner on 1/30/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
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
@property (nonatomic) BOOL didSetupPendingDismissButtons;
@property (nonatomic) UISwipeGestureRecognizer *navigationBarSwipeGesture;
@end

@implementation FLEXNavigationController

+ (instancetype)withRootViewController:(UIViewController *)rootVC {
    return [[self alloc] initWithRootViewController:rootVC];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.waitingToAddTab = YES;
    
    // Add gesture to reveal toolbar if hidden
    self.navigationBar.userInteractionEnabled = YES;
    [self.navigationBar addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleNavigationBarTap:)
    ]];
    
    // Add gesture to dismiss if not presented with a sheet style
    if (@available(iOS 13, *)) {
        switch (self.modalPresentationStyle) {
            case UIModalPresentationAutomatic:
            case UIModalPresentationPageSheet:
            case UIModalPresentationFormSheet:
                break;
                
            default:
                [self addNavigationBarSwipeGesture];
                break;
        }
    } else {
        [self addNavigationBarSwipeGesture];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.beingPresented && !self.didSetupPendingDismissButtons) {
        for (UIViewController *vc in self.viewControllers) {
            [self addNavigationBarItemsToViewController:vc.navigationItem];
        }
        
        self.didSetupPendingDismissButtons = YES;
    }
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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self addNavigationBarItemsToViewController:viewController.navigationItem];
}

- (void)dismissAnimated {
    // Tabs are only closed if the done button is pressed; this
    // allows you to leave a tab open by dragging down to dismiss
    [FLEXTabList.sharedList closeTab:self];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addNavigationBarItemsToViewController:(UINavigationItem *)navigationItem {
    if (!self.presentingViewController) {
        return;
    }
    
    // Check if a done item already exists
    for (UIBarButtonItem *item in navigationItem.rightBarButtonItems) {
        if (item.style == UIBarButtonItemStyleDone) {
            return;
        }
    }
    
    // Give root view controllers a Done button if it does not already have one
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self
        action:@selector(dismissAnimated)
    ];
    
    // Prepend the button if other buttons exist already
    NSArray *existingItems = navigationItem.rightBarButtonItems;
    if (existingItems.count) {
        navigationItem.rightBarButtonItems = [@[done] arrayByAddingObjectsFromArray:existingItems];
    } else {
        navigationItem.rightBarButtonItem = done;
    }
    
    // Keeps us from calling this method again on
    // the same view controllers in -viewWillAppear:
    self.didSetupPendingDismissButtons = YES;
}

- (void)addNavigationBarSwipeGesture {
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleNavigationBarSwipe:)
    ];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    swipe.delegate = self;
    self.navigationBarSwipeGesture = swipe;
    [self.navigationBar addGestureRecognizer:swipe];
}

- (void)handleNavigationBarSwipe:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
     
- (void)handleNavigationBarTap:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        if (self.toolbarHidden) {
            [self setToolbarHidden:NO animated:YES];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g1 shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)g2 {
    if (g1 == self.navigationBarSwipeGesture && g2 == self.barHideOnSwipeGestureRecognizer) {
        return YES;
    }
    
    return NO;
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
