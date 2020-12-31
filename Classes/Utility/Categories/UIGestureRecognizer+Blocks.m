//
//  UIGestureRecognizer+Blocks.m
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIGestureRecognizer+Blocks.h"
#import <objc/runtime.h>


@implementation UIGestureRecognizer (Blocks)

static void * actionKey;

+ (instancetype)flex_action:(GestureBlock)action {
    UIGestureRecognizer *gesture = [[self alloc] initWithTarget:nil action:nil];
    [gesture addTarget:gesture action:@selector(flex_invoke)];
    gesture.flex_action = action;
    return gesture;
}

- (void)flex_invoke {
    self.flex_action(self);
}

- (GestureBlock)flex_action {
    return objc_getAssociatedObject(self, &actionKey);
}

- (void)flex_setAction:(GestureBlock)action {
    objc_setAssociatedObject(self, &actionKey, action, OBJC_ASSOCIATION_COPY);
}

@end
