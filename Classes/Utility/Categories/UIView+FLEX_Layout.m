//
//  UIView+FLEX_Layout.m
//  FLEX
//
//  Created by Tanner Bennett on 7/18/19.
//Copyright © 2019 Flipboard. All rights reserved.
//

#import "UIView+FLEX_Layout.h"

@implementation UIView (FLEX_Layout)

- (void)centerInView:(UIView *)view {
    [self.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [self.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
}

- (void)pinEdgesTo:(UIView *)view {
    [self.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [self.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    [self.rightAnchor constraintEqualToAnchor:view.rightAnchor].active = YES;
}

- (void)pinEdgesTo:(UIView *)view withInsets:(UIEdgeInsets)i {
    [self.topAnchor constraintEqualToAnchor:view.topAnchor constant:i.top].active = YES;
    [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:i.left].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-i.bottom].active = YES;
    [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-i.right].active = YES;
}

- (void)pinEdgesToSuperview {
    [self pinEdgesTo:self.superview];
}

- (void)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets {
    [self pinEdgesTo:self.superview withInsets:insets];
}

@end
