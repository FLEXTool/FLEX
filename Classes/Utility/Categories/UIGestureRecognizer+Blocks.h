//
//  UIGestureRecognizer+Blocks.h
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^GestureBlock)(UIGestureRecognizer *gesture);


@interface UIGestureRecognizer (Blocks)

+ (instancetype)flex_action:(GestureBlock)action;

@property (nonatomic, setter=flex_setAction:) GestureBlock flex_action;

@end

