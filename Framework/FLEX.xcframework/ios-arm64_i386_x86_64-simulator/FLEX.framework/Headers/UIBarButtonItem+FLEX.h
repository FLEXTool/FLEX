//
//  UIBarButtonItem+FLEX.h
//  FLEX
//
//  Created by Tanner on 2/4/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FLEXBarButtonItemSystem(item, tgt, sel) \
    [UIBarButtonItem flex_systemItem:UIBarButtonSystemItem##item target:tgt action:sel]

@interface UIBarButtonItem (FLEX)

@property (nonatomic, readonly, class) UIBarButtonItem *flex_flexibleSpace;
@property (nonatomic, readonly, class) UIBarButtonItem *flex_fixedSpace;

+ (instancetype)flex_itemWithCustomView:(UIView *)customView;
+ (instancetype)flex_backItemWithTitle:(NSString *)title;

+ (instancetype)flex_systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action;

+ (instancetype)flex_itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)flex_doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action;

+ (instancetype)flex_itemWithImage:(UIImage *)image target:(id)target action:(SEL)action;

+ (instancetype)flex_disabledSystemItem:(UIBarButtonSystemItem)item;
+ (instancetype)flex_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style;
+ (instancetype)flex_disabledItemWithImage:(UIImage *)image;

/// @return the receiver
- (UIBarButtonItem *)flex_withTintColor:(UIColor *)tint;

- (void)_setWidth:(CGFloat)width;

@end
