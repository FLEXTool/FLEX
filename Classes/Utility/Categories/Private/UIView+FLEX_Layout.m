//
//  UIView+FLEX_Layout.m
//  FLEX
//
//  Created by Tanner Bennett on 7/18/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIView+FLEX_Layout.h"

@implementation UIView (FLEX_Layout)

- (void)flex_centerInView:(UIView *)view {
    [NSLayoutConstraint activateConstraints:@[
        [self.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
    ]];
}

- (void)flex_pinEdgesTo:(UIView *)view {
   [NSLayoutConstraint activateConstraints:@[
       [self.topAnchor constraintEqualToAnchor:view.topAnchor],
       [self.leftAnchor constraintEqualToAnchor:view.leftAnchor],
       [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
       [self.rightAnchor constraintEqualToAnchor:view.rightAnchor],
   ]]; 
}

- (void)flex_pinEdgesTo:(UIView *)view withInsets:(UIEdgeInsets)i {
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:view.topAnchor constant:i.top],
        [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:i.left],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-i.bottom],
        [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-i.right],
    ]];
}

- (void)flex_pinEdgesToSuperview {
    [self flex_pinEdgesTo:self.superview];
}

- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets {
    [self flex_pinEdgesTo:self.superview withInsets:insets];
}

- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)i aboveView:(UIView *)sibling {
    UIView *view = self.superview;
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:view.topAnchor constant:i.top],
        [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:i.left],
        [self.bottomAnchor constraintEqualToAnchor:sibling.topAnchor constant:-i.bottom],
        [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-i.right],
    ]];
}

- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)i belowView:(UIView *)sibling {
    UIView *view = self.superview;
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:sibling.bottomAnchor constant:i.top],
        [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:i.left],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-i.bottom],
        [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-i.right],
    ]];
}

@end
