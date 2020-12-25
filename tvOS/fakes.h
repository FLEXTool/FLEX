//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXMacros.h"

typedef NS_ENUM(NSInteger, UIFakeDatePickerMode) {
    UIFakeDatePickerModeTime,           // Displays hour, minute, and optionally AM/PM designation depending on the locale setting (e.g. 6 | 53 | PM)
    UIFakeDatePickerModeDate,           // Displays month, day, and year depending on the locale setting (e.g. November | 15 | 2007)
    UIFakeDatePickerModeDateAndTime,    // Displays date, hour, minute, and optionally AM/PM designation depending on the locale setting (e.g. Wed Nov 15 | 6 | 53 | PM)
    UIFakeDatePickerModeCountDownTimer, // Displays hour and minute (e.g. 1 | 53)
} ;

typedef NS_ENUM(NSInteger, UIFakeDatePickerStyle) {
    /// Automatically pick the best style available for the current platform & mode.
    UIFakeDatePickerStyleAutomatic,
    /// Use the wheels (UIPickerView) style.
    UIFakeDatePickerStyleWheels,
    /// Use a compact style for the date picker. Editing occurs in an overlay.
    UIFakeDatePickerStyleCompact,
};

@interface UIFakeDatePicker : UIControl <NSCoding>
@property (nonatomic) UIFakeDatePickerMode datePickerMode; // default is UIFakeDatePickerModeDateAndTime

@property (nullable, nonatomic, strong) NSLocale   *locale;   // default is [NSLocale currentLocale]. setting nil returns to default
@property (null_resettable, nonatomic, copy)   NSCalendar *calendar; // default is [NSCalendar currentCalendar]. setting nil returns to default
@property (nullable, nonatomic, strong) NSTimeZone *timeZone; // default is nil. use current time zone or time zone from calendar

@property (nonatomic, strong) NSDate * _Nonnull date;        // default is current dat _Nonnull e when picker created. Ignored in countdown timer mode. for that mode, picker starts at 0:00
@property (nullable, nonatomic, strong) NSDate *minimumDate; // specify min/max date range. default is nil. When min > max, the values are ignored. Ignored in countdown timer mode
@property (nullable, nonatomic, strong) NSDate *maximumDate; // default is nil

@property (nonatomic) NSTimeInterval countDownDuration; // for UIFakeDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59 (86,399 seconds). value being set is div 60 (drops remaining seconds).
@property (nonatomic) NSInteger      minuteInterval;    // display minutes wheel with interval. interval must be evenly divided into 60. default is 1. min is 1, max is 30

- (void)setDate:(NSDate *_Nonnull)date animated:(BOOL)animated; // if a_Nonnullnimated is YES, animate the wheels of time to display the new date

/// Request a style for the date picker. If the style changed, then the date picker may need to be resized and will generate a layout pass to display correctly.
@property (nonatomic, readwrite, assign) UIFakeDatePickerStyle preferredDatePickerStyle;

/// The style that the date picker is using for its layout. This property always returns a concrete style (never automatic).
@property (nonatomic, readonly, assign) UIFakeDatePickerStyle datePickerStyle;

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
