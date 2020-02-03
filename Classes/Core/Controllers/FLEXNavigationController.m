//
//  FLEXNavigationController.m
//  FLEX
//
//  Created by Tanner on 1/30/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXNavigationController.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.waitingToAddTab = YES;
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
