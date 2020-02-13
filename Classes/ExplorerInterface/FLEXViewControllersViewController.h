//
//  FLEXViewControllersViewController.h
//  FLEX
//
//  Created by Tanner Bennett on 2/13/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXViewControllersViewController : FLEXTableViewController

+ (instancetype)controllersForViews:(NSArray<UIView *> *)views;

@end

NS_ASSUME_NONNULL_END
