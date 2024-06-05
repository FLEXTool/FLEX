//
//  FLEXNavigationController.h
//  FLEX
//
//  Created by Tanner on 1/30/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXNavigationController : UINavigationController

+ (instancetype)withRootViewController:(UIViewController *)rootVC;

@end

@interface UINavigationController (FLEXObjectExploring)

/// Push an object explorer view controller onto the navigation stack
- (void)pushExplorerForObject:(id)object;
/// Push an object explorer view controller onto the navigation stack
- (void)pushExplorerForObject:(id)object animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
