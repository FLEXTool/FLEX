//
//  UIBarButtonItem+FLEX.m
//  FLEX
//
//  Created by Tanner on 2/4/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIBarButtonItem+FLEX.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIBarButtonItem (FLEX)

+ (UIBarButtonItem *)flex_flexibleSpace {
    return [self flex_systemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *)flex_fixedSpace {
    UIBarButtonItem *fixed = [self flex_systemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 60;
    return fixed;
}

+ (instancetype)flex_systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action {
    return [[self alloc] initWithBarButtonSystemItem:item target:target action:action];
}

+ (instancetype)flex_itemWithCustomView:(UIView *)customView {
    return [[self alloc] initWithCustomView:customView];
}

+ (instancetype)flex_backItemWithTitle:(NSString *)title {
    return [self flex_itemWithTitle:title target:nil action:nil];
}

+ (instancetype)flex_itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)flex_doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:target action:action];
}

+ (instancetype)flex_itemWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    return [[self alloc] initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)flex_disabledSystemItem:(UIBarButtonSystemItem)system {
    UIBarButtonItem *item = [self flex_systemItem:system target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)flex_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style {
    UIBarButtonItem *item = [self flex_itemWithTitle:title target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)flex_disabledItemWithImage:(UIImage *)image {
    UIBarButtonItem *item = [self flex_itemWithImage:image target:nil action:nil];
    item.enabled = NO;
    return item;
}

- (UIBarButtonItem *)flex_withTintColor:(UIColor *)tint {
    self.tintColor = tint;
    return self;
}

@end
