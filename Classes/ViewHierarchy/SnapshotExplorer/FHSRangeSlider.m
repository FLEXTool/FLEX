//
//  FHSRangeSlider.m
//  FLEX
//
//  Created by Tanner Bennett on 1/7/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FHSRangeSlider.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FHSRangeSlider ()
@property (nonatomic, readonly) UIImageView *track;
@property (nonatomic, readonly) UIImageView *fill;
@property (nonatomic, readonly) UIImageView *leftHandle;
@property (nonatomic, readonly) UIImageView *rightHandle;

@property (nonatomic, getter=isTrackingLeftHandle) BOOL trackingLeftHandle;
@property (nonatomic, getter=isTrackingRightHandle) BOOL trackingRightHandle;
@end

@implementation FHSRangeSlider

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _allowedMaxValue = 1.f;
        _maxValue = 1.f;
        [self initSubviews];
    }

    return self;
}

- (void)initSubviews {
    self.userInteractionEnabled = YES;
    UIImageView * (^newSubviewImageView)() = ^UIImageView *(UIImage *image) {
        UIImageView *iv = [UIImageView new];
        iv.image = image;
//        iv.userInteractionEnabled = YES;
        [self addSubview:iv];
        return iv;
    };

    _track = newSubviewImageView(FLEXResources.rangeSliderTrack);
    _fill = newSubviewImageView(FLEXResources.rangeSliderFill);
    _leftHandle = newSubviewImageView(FLEXResources.rangeSliderLeftHandle);
    _rightHandle = newSubviewImageView(FLEXResources.rangeSliderRightHandle);
}

#pragma mark - Setters / Private

- (CGFloat)valueAt:(CGFloat)x {
    CGFloat minX = self.leftHandle.image.size.width;
    CGFloat maxX = self.bounds.size.width - self.rightHandle.image.size.width;
    CGFloat cappedX = MIN(MAX(x, minX), maxX);
    CGFloat delta = maxX - minX;
    CGFloat maxDelta = self.allowedMaxValue - self.allowedMinValue;

    return ((delta > 0) ? (cappedX - minX) / delta : 0) * maxDelta + self.allowedMinValue;
}

- (void)setAllowedMinValue:(CGFloat)allowedMinValue {
    _allowedMinValue = allowedMinValue;

    if (self.minValue < self.allowedMaxValue) {
        self.minValue = self.allowedMaxValue;
    } else {
        [self setNeedsLayout];
    }
}

- (void)setAllowedMaxValue:(CGFloat)allowedMaxValue {
    _allowedMaxValue = allowedMaxValue;

    if (self.maxValue > self.allowedMaxValue) {
        self.maxValue = self.allowedMaxValue;
    } else {
        [self valuesChanged:NO];
    }
}

- (void)setMinValue:(CGFloat)minValue {
    _minValue = minValue;
    [self valuesChanged:YES];
}

- (void)setMaxValue:(CGFloat)maxValue {
    _maxValue = maxValue;
    [self valuesChanged:YES];
}

- (void)valuesChanged:(BOOL)sendActions {
    if (NSThread.isMainThread) {
        if (sendActions) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        [self setNeedsLayout];
    }
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.leftHandle.image.size.height);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize lhs = self.leftHandle.image.size;
    CGSize rhs = self.rightHandle.image.size;
    CGSize trackSize = self.track.image.size;

    CGFloat delta = self.allowedMaxValue - self.allowedMinValue;
    CGFloat minPercent, maxPercent;

    if (delta <= 0) {
        minPercent = maxPercent = 0;
    } else {
        minPercent = MAX(0, (self.minValue - self.allowedMinValue) / delta);
        maxPercent = MAX(minPercent, (self.maxValue - self.allowedMinValue) / delta);
    }

    CGFloat rangeSliderWidth = self.bounds.size.width - lhs.width - rhs.width;

    self.leftHandle.frame = FLEXRectMake(
        rangeSliderWidth * minPercent,
        CGRectGetMidY(self.bounds) - (lhs.height / 2.f) + 3.f,
        lhs.width,
        lhs.height
    );

    self.rightHandle.frame = FLEXRectMake(
        lhs.width + (rangeSliderWidth * maxPercent),
        CGRectGetMidY(self.bounds) - (rhs.height / 2.f) + 3.f,
        rhs.width,
        rhs.height
    );

    self.track.frame = FLEXRectMake(
        lhs.width / 2.f,
        CGRectGetMidY(self.bounds) - trackSize.height / 2.f,
        self.bounds.size.width - (lhs.width / 2.f) - (rhs.width / 2.f),
        trackSize.height
    );

    self.fill.frame = FLEXRectMake(
        CGRectGetMidX(self.leftHandle.frame),
        CGRectGetMinY(self.track.frame),
        CGRectGetMidX(self.rightHandle.frame) - CGRectGetMidX(self.leftHandle.frame),
        self.track.frame.size.height
    );
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint loc = [touch locationInView:self];

    if (CGRectContainsPoint(self.leftHandle.frame, loc)) {
        self.trackingLeftHandle = YES;
        self.trackingRightHandle = NO;
    } else if (CGRectContainsPoint(self.rightHandle.frame, loc)) {
        self.trackingLeftHandle = NO;
        self.trackingRightHandle = YES;
    } else {
        return NO;
    }

    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint loc = [touch locationInView:self];

    if (self.isTrackingLeftHandle) {
        self.minValue = MIN(MAX(self.allowedMinValue, [self valueAt:loc.x]), self.maxValue);
    } else if (self.isTrackingRightHandle) {
        self.maxValue = MAX(MIN(self.allowedMaxValue, [self valueAt:loc.x]), self.minValue);
    } else {
        return NO;
    }

    [self setNeedsLayout];
    [self layoutIfNeeded];

    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.trackingLeftHandle = NO;
    self.trackingRightHandle = NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

@end
