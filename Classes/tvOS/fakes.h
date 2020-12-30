//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXMacros.h"
#import "KBSlider.h"
#import "KBDatePickerView.h"

@interface KBSearchButton: UIButton <UITextFieldDelegate>
- (void)triggerSearchField;
@property UISearchBar *searchBar;
@end

@interface UIFakeSwitch : UIButton <NSCoding>
@property(nullable, nonatomic, strong) UIColor *onTintColor;
@property(nullable, nonatomic, strong) UIColor *thumbTintColor;
@property(nullable, nonatomic, strong) UIImage *onImage;
@property(nullable, nonatomic, strong) UIImage *offImage;
@property(nonatomic,getter=isOn) BOOL on;
- (instancetype _Nonnull )initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;      // This class enforces a size appropriate for the control, and so the frame size is ignored.
- (nullable instancetype)initWithCoder:(NSCoder *_Nonnull)coder NS_DESIGNATED_INITIALIZER;
- (void)setOn:(BOOL)on animated:(BOOL)animated; // does not send action
+ (id _Nonnull )newSwitch;
@end

@interface UIFakeSlider: UIControl <NSCoding>
@property(nonatomic) float value;
@property(nonatomic) float minimumValue;
@property(nonatomic) float maximumValue;
@property(nonatomic) float minValue;
@property(nonatomic) float maxValue;
@property(nonatomic) float allowedMinValue;
@property(nonatomic) float allowedMaxValue;
@property(nullable, nonatomic,strong) UIImage *minimumValueImage;
@property(nullable, nonatomic,strong) UIImage *maximumValueImage;

@property(nonatomic,getter=isContinuous) BOOL continuous;

@property(nullable, nonatomic,strong) UIColor *minimumTrackTintColor;
@property(nullable, nonatomic,strong) UIColor *maximumTrackTintColor;
@property(nullable, nonatomic,strong) UIColor *thumbTintColor;

- (void)setValue:(float)value animated:(BOOL)animated;

- (void)setThumbImage:(nullable UIImage *)image forState:(UIControlState)state;
- (void)setMinimumTrackImage:(nullable UIImage *)image forState:(UIControlState)state;
- (void)setMaximumTrackImage:(nullable UIImage *)image forState:(UIControlState)state;

- (nullable UIImage *)thumbImageForState:(UIControlState)state;
- (nullable UIImage *)minimumTrackImageForState:(UIControlState)state;
- (nullable UIImage *)maximumTrackImageForState:(UIControlState)state;

@property(nullable,nonatomic,readonly) UIImage *currentThumbImage;
@property(nullable,nonatomic,readonly) UIImage *currentMinimumTrackImage;
@property(nullable,nonatomic,readonly) UIImage *currentMaximumTrackImage;

// lets a subclass lay out the track and thumb as needed
- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)trackRectForBounds:(CGRect)bounds;
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value;

@end
