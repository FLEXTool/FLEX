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

- (void)centerInView:(UIView *)view;
- (void)pinEdgesTo:(UIView *)view;
- (void)pinEdgesTo:(UIView *)view withInsets:(UIEdgeInsets)insets;
- (void)pinEdgesToSuperview;
- (void)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;
- (void)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets aboveView:(UIView *)sibling;
- (void)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets belowView:(UIView *)sibling;

@end
