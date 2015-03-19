//
//  FLEXExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXExplorerViewControllerDelegate;

@interface FLEXExplorerViewController : UIViewController

@property (nonatomic, weak) id <FLEXExplorerViewControllerDelegate> delegate;

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

@end

@protocol FLEXExplorerViewControllerDelegate <NSObject>

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController;

@end
