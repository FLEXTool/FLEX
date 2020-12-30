//
//  UIView+FLEX_Layout.h
//  FLEX
//
//  Created by Tanner Bennett on 7/18/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#define Padding(p) UIEdgeInsetsMake(p, p, p, p)

@interface UIView (FLEX_Layout)

- (void)flex_centerInView:(UIView *)view;
- (void)flex_pinEdgesTo:(UIView *)view;
- (void)flex_pinEdgesTo:(UIView *)view withInsets:(UIEdgeInsets)insets;
- (void)flex_pinEdgesToSuperview;
- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;
- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets aboveView:(UIView *)sibling;
- (void)flex_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets belowView:(UIView *)sibling;

@end
