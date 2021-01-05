//
//  KBSlider.h
//  KBSlider
//
//  Created by Kevin Bradley on 12/25/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DPadState) {
    DPadStateSelect,
    DPadStateRight,
    DPadStateLeft,
    DPadStateUp,
    DPadStateDown,
};


@interface KBSlider : UIControl

@property CGFloat value;
@property CGFloat minimumValue;
@property CGFloat maximumValue;
@property(nonatomic,getter=isContinuous) BOOL continuous;
@property UIColor *maximumTrackTintColor;
@property UIColor *minimumTrackTintColor;
@property UIColor *thumbTintColor;
@property CGFloat focusScaleFactor;
@property CGFloat stepValue;

@property UIImage *currentMinimumTrackImage;
@property UIImage *currentMaximumTrackImage;

@property CGFloat storedValue;

- (UIImage *)currentThumbImage;
- (void)setValue:(CGFloat)value animated:(BOOL)animated;
- (void)setMinimumTrackImage:(UIImage *)minTrackImage forState:(UIControlState)state;
- (void)setMaximumTrackImage:(UIImage *)maxTrackImage forState:(UIControlState)state;
- (void)setThumbImage:(UIImage *)thumbImage forState:(UIControlState)state;
- (UIImage *)minimumTrackImageForState:(UIControlState)state;
- (UIImage *)maximumTrackImageForState:(UIControlState)state;
- (UIImage *)thumbImageForState:(UIControlState)state;
@end

NS_ASSUME_NONNULL_END
