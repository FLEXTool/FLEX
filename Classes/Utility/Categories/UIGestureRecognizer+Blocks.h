//
//  UIGestureRecognizer+Blocks.h
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^GestureBlock)(UIGestureRecognizer *gesture);


@interface UIGestureRecognizer (Blocks)

+ (instancetype)action:(GestureBlock)action;

@property (nonatomic) GestureBlock action;

@end

