//
//  UIGestureRecognizer+Blocks.m
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//Copyright © 2019 Flipboard. All rights reserved.
//

#import "UIGestureRecognizer+Blocks.h"
#import <objc/runtime.h>


@implementation UIGestureRecognizer (Blocks)

static void * actionKey;

+ (instancetype)action:(GestureBlock)action {
    UIGestureRecognizer *gesture = [[self alloc] initWithTarget:nil action:nil];
    [gesture addTarget:gesture action:@selector(tb_invoke)];
    gesture.action = action;
    return gesture;
}

- (void)tb_invoke {
    self.action(self);
}

- (GestureBlock)action {
    return objc_getAssociatedObject(self, &actionKey);
}

- (void)setAction:(GestureBlock)action {
    objc_setAssociatedObject(self, &actionKey, action, OBJC_ASSOCIATION_COPY);
}

@end
