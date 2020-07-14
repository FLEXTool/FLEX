//
//  UIBarButtonItem+FLEX.h
//  FLEX
//
//  Created by Tanner on 2/4/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FLEXBarButtonItemSystem(item, tgt, sel) \
    [UIBarButtonItem systemItem:UIBarButtonSystemItem##item target:tgt action:sel]

@interface UIBarButtonItem (FLEX)

@property (nonatomic, readonly, class) UIBarButtonItem *flex_flexibleSpace;
@property (nonatomic, readonly, class) UIBarButtonItem *flex_fixedSpace;

+ (instancetype)itemWithCustomView:(UIView *)customView;
+ (instancetype)backItemWithTitle:(NSString *)title;

+ (instancetype)systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action;

+ (instancetype)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action;

+ (instancetype)itemWithImage:(UIImage *)image target:(id)target action:(SEL)action;

+ (instancetype)disabledSystemItem:(UIBarButtonSystemItem)item;
+ (instancetype)disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style;
+ (instancetype)disabledItemWithImage:(UIImage *)image;

/// @return the receiver
- (UIBarButtonItem *)withTintColor:(UIColor *)tint;

- (void)_setWidth:(CGFloat)width;

@end
