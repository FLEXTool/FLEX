//
//  KBSlider.m
//  KBSlider
//
//  Created by Kevin Bradley on 12/25/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "KBSlider.h"
#import <GameController/GameController.h>

@interface KBSlider() {
    CGFloat _minimumValue;
    CGFloat _maximumValue;
    UIColor *_maximumTrackTintColor;
    UIColor *_minimumTrackTintColor;
    UIColor *_thumbTintColor;
    CGFloat _focusScaleFactor;
    
    BOOL _isEnabled;
    BOOL _isSelected;
    BOOL _isHighlighted;
}

@property CGFloat trackViewHeight;
@property CGFloat thumbSize;
@property NSTimeInterval animationDuration;
@property CGFloat defaultValue;
@property CGFloat defaultMinimumValue;
@property CGFloat defaultMaximumValue;
@property BOOL defaultIsContinuous;
@property UIColor *defaultThumbTintColor;
@property UIColor *defaultTrackColor;
@property UIColor *defaultMininumTrackTintColor;
@property CGFloat defaultFocusScaleFactor;
@property CGFloat defaultStepValue;
@property CGFloat decelerationRate;
@property CGFloat decelerationMaxVelocity;
@property CGFloat fineTunningVelocityThreshold;

@property NSMutableDictionary *thumbViewImages; //[UInt: UIImage] - not an allowed dict type in obj-c
@property UIImageView *thumbView;

@property NSMutableDictionary *trackViewImages; //[UInt: UIImage] - not an allowed dict type in obj-c
@property UIImageView *trackView;

@property NSMutableDictionary *minimumTrackViewImages; //[UInt: UIImage] - not an allowed dict type in obj-c
@property UIImageView *minimumTrackView;

@property NSMutableDictionary *maximumTrackViewImages; //[UInt: UIImage] - not an allowed dict type in obj-c
@property UIImageView *maximumTrackView;

@property UIPanGestureRecognizer *panGestureRecognizer;
@property UITapGestureRecognizer *leftTapGestureRecognizer;
@property UITapGestureRecognizer *rightTapGestureRecognizer;
@property NSLayoutConstraint *thumbViewCenterXConstraint;

@property DPadState dPadState; //.select

@property NSTimer *deceleratingTimer;
@property CGFloat deceleratingVelocity;
@property CGFloat thumbViewCenterXConstraintConstant;

@end

@implementation KBSlider

- (void)initializeDefaults {
    _trackViewHeight = 5;
    _thumbSize = 30;
    _animationDuration = 0.3;
    _defaultValue = 0;
    _defaultMinimumValue = 0;
    _defaultMaximumValue = 1;
    _defaultIsContinuous = true;
    _defaultThumbTintColor = [UIColor whiteColor];
    _defaultTrackColor = [UIColor grayColor];
    _defaultMininumTrackTintColor = [UIColor blueColor];
    _defaultFocusScaleFactor = 1.05;
    _defaultStepValue = 0.1;
    _decelerationRate = 0.92;
    _decelerationMaxVelocity = 1000;
    _fineTunningVelocityThreshold = 600;
    
    _storedValue = _defaultValue;
    _dPadState = DPadStateSelect;
    _isContinuous = _defaultIsContinuous;
    
    _minimumTrackViewImages = [NSMutableDictionary new];
    _maximumTrackViewImages = [NSMutableDictionary new];
    _trackViewImages = [NSMutableDictionary new];
    _thumbViewImages = [NSMutableDictionary new];
    
    _thumbTintColor = _defaultThumbTintColor;
    _minimumTrackTintColor = _defaultMininumTrackTintColor;
    _focusScaleFactor = _defaultFocusScaleFactor;
    _minimumValue = _defaultMinimumValue;
    _maximumValue = _defaultMaximumValue;
    _stepValue = _defaultStepValue;
    [self setEnabled:true];
    
}

- (void)setSelected:(BOOL)selected {
    _isSelected = selected;
    [self updateStateDependantViews];
}

- (BOOL)isSelected {
    return _isSelected;
}

- (void)setHighlighted:(BOOL)highlighted {
    _isHighlighted = highlighted;
    [self updateStateDependantViews];
}

- (BOOL)isHighlighted {
    return _isHighlighted;
}

- (void)setEnabled:(BOOL)enabled {
    _isEnabled = enabled;
    _panGestureRecognizer.enabled = enabled;
    [self updateStateDependantViews];
}

- (BOOL)isEnabled {
    return _isEnabled;
}


- (CGFloat)value {
    return _storedValue;
}

- (void)setValue:(CGFloat)newValue {
    _storedValue = MIN(_maximumValue, newValue);
    _storedValue = MAX(_minimumValue, _storedValue);
    CGFloat offset = _trackView.bounds.size.width * (_storedValue - _minimumValue) / (_maximumValue - _minimumValue);
    offset = MIN(_trackView.bounds.size.width, offset);
    if(isnan(offset)){
        return;
    }
    NSLog(@"[KBSlider] attempting to set offset value: %f", offset);
    _thumbViewCenterXConstraint.constant = offset;
}

- (CGFloat)maximumValue {
    return _maximumValue;
}

- (void)setMaximumValue:(CGFloat)maximumValue {
    _maximumValue = maximumValue;
    [self setValue:MIN(self.value, maximumValue)];
}

- (CGFloat)minimumValue {
    return _minimumValue;
}

- (void)setMinimumValue:(CGFloat)minimumValue {
    _minimumValue = minimumValue;
    [self setValue:MAX(self.value, minimumValue)];
}

- (UIColor *)maximumTrackTintColor {
    return _maximumTrackTintColor;
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    _maximumTrackTintColor = maximumTrackTintColor;
    _maximumTrackView.backgroundColor = maximumTrackTintColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    _minimumTrackTintColor = minimumTrackTintColor;
    _minimumTrackView.backgroundColor = minimumTrackTintColor;
}

- (UIColor *)thumbTintColor {
    return _thumbTintColor;
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    _thumbTintColor = thumbTintColor;
    _thumbView.backgroundColor = thumbTintColor;
}

- (UIColor *)minimumTrackTintColor {
    return _minimumTrackTintColor;
}

- (CGFloat)focusScaleFactor {
    return _focusScaleFactor;
}

- (void)setFocusScaleFactor:(CGFloat)focusScaleFactor {
    _focusScaleFactor = focusScaleFactor;
    [self updateStateDependantViews];
}

- (void)setupView {
    
    [self initializeDefaults];
    [self setUpTrackView];
    [self setUpMinimumTrackView];
    [self setUpMaximumTrackView];
    [self setUpThumbView];
    
    [self setUpTrackViewConstraints];
    [self setUpMinimumTrackViewConstraints];
    [self setUpMaximumTrackViewConstraints];
    [self setUpThumbViewConstraints];
    
    [self setUpGestures];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerConnected:) name:GCControllerDidConnectNotification object:nil];
    [self updateStateDependantViews];
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated {
    [self setValue:value];
    [self stopDeceleratingTimer];
    if (animated){
        [UIView animateWithDuration:self.animationDuration animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }];
    }
}

- (void)setMinimumTrackImage:(UIImage *)image forState:(UIControlState)state {
    _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}

- (void)setMaximumTrackImage:(UIImage *)image forState:(UIControlState)state {
    _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state {
    _thumbViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}


- (UIImage *)currentThumbImage {
    return _thumbView.image;
}

- (UIImage *)minimumTrackImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _minimumTrackViewImages[key];
    
}

- (UIImage *)maximumTrackImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _maximumTrackViewImages[key];
}

- (UIImage *)thumbImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _thumbViewImages[key];
}

- (void)setUpThumbView {
    _thumbView = [UIImageView new];
    _thumbView.layer.cornerRadius = _thumbSize/2;
    _thumbView.backgroundColor = _thumbTintColor;
    [self addSubview:_thumbView];
}


- (void)setUpTrackView {
    _trackView = [UIImageView new];
    _trackView.layer.cornerRadius = _trackViewHeight/2;
    _trackView.backgroundColor = _defaultTrackColor;
    [self addSubview:_trackView];
}

- (void)setUpMinimumTrackView {
    _minimumTrackView = [UIImageView new];
    _minimumTrackView.layer.cornerRadius = _trackViewHeight/2;
    _minimumTrackView.backgroundColor = _minimumTrackTintColor;
    [self addSubview:_minimumTrackView];
}

- (void)setUpMaximumTrackView {
    _maximumTrackView = [UIImageView new];
    _maximumTrackView.layer.cornerRadius = _trackViewHeight/2;
    _maximumTrackView.backgroundColor = _maximumTrackTintColor;
    [self addSubview:_maximumTrackView];
}


- (void)setUpTrackViewConstraints {
    _trackView.translatesAutoresizingMaskIntoConstraints = false;
    [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
    [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = true;
    [_trackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    [_trackView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
    
}

- (void)setUpMinimumTrackViewConstraints {
    _minimumTrackView.translatesAutoresizingMaskIntoConstraints = false;
    [_minimumTrackView.leadingAnchor constraintEqualToAnchor:_trackView.leadingAnchor].active = true;
    [_minimumTrackView.trailingAnchor constraintEqualToAnchor:_thumbView.centerXAnchor].active = true;
    [_minimumTrackView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    [_minimumTrackView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
    
}

- (void)setUpMaximumTrackViewConstraints {
    _maximumTrackView.translatesAutoresizingMaskIntoConstraints = false;
    [_maximumTrackView.leadingAnchor constraintEqualToAnchor:_thumbView.centerXAnchor].active = true;
    [_maximumTrackView.trailingAnchor constraintEqualToAnchor:_trackView.trailingAnchor].active = true;
    [_maximumTrackView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    [_maximumTrackView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
    
}

- (void)setUpThumbViewConstraints {
    _thumbView.translatesAutoresizingMaskIntoConstraints = false;
    [_thumbView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    [_thumbView.heightAnchor constraintEqualToConstant:_thumbSize].active = true;
    [_thumbView.widthAnchor constraintEqualToConstant:_thumbSize].active = true;
    _thumbViewCenterXConstraint = [_thumbView.centerXAnchor constraintEqualToAnchor:_trackView.leadingAnchor constant:self.value];
    _thumbViewCenterXConstraint.active = true;
}

- (void)setUpGestures {
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureWasTriggered:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    
    _leftTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftTapWasTriggered)];
    _leftTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    _leftTapGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    [self addGestureRecognizer:_leftTapGestureRecognizer];
    
    _rightTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightTapWasTriggered)];
    _rightTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    _rightTapGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    [self addGestureRecognizer:_rightTapGestureRecognizer];
}

- (void)updateStateDependantViews {
    
    UIImage *currentMinImage = _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    if (currentMinImage){
        _minimumTrackView.image = currentMinImage;
    } else {
        _minimumTrackView.image = _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    }
    UIImage *currentMaxImage = _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    if (currentMaxImage){
        _maximumTrackView.image = currentMaxImage;
    } else {
        _maximumTrackView.image = _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    }
    UIImage *currentThumbImage = _thumbViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    if (currentThumbImage){
        _thumbView.image = currentThumbImage;
    } else {
        _thumbView.image = _thumbViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    }
    
    if ([self isFocused]){
        self.transform = CGAffineTransformMakeScale(_focusScaleFactor, _focusScaleFactor);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
    
}

- (void)controllerConnected:(NSNotification *)n {
    GCController *controller = [n object];
    GCMicroGamepad *micro = [controller microGamepad];
    if (!micro)return;
    
    CGFloat threshold = 0.7;
    micro.reportsAbsoluteDpadValues = true;
    micro.dpad.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
      if (xValue < -threshold){
          self.dPadState = DPadStateLeft;
      } else if (xValue > threshold){
          self.dPadState = DPadStateRight;
      } else {
          self.dPadState = DPadStateSelect;
      }
    };
}

- (void)handleDeceleratingTimer:(NSTimer *)timer {
    
    CGFloat centerX = _thumbViewCenterXConstraintConstant + _deceleratingVelocity * 0.01;
    CGFloat percent = centerX / (_trackView.frame.size.width);
    CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
    [self setValue:newValue];
    if ([self isContinuous]){
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
    
    _deceleratingVelocity *= _decelerationRate;
    if (![self isFocused] || fabs(_deceleratingVelocity) < 1){
        [self stopDeceleratingTimer];
    }
}

- (void)stopDeceleratingTimer {
    [_deceleratingTimer invalidate];
    _deceleratingTimer = nil;
    _deceleratingVelocity = 0;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)isVerticalGesture:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self];
    if (fabs(translation.y) > fabs(translation.x)) {
        return true;
    }
    return false;
}

#pragma mark - Actions

- (void)panGestureWasTriggered:(UIPanGestureRecognizer *)panGestureRecognizer {
    
    if ([self isVerticalGesture:panGestureRecognizer]){
        return;
    }
    CGFloat translation = [panGestureRecognizer translationInView:self].x;
    CGFloat velocity = [panGestureRecognizer velocityInView:self].x;
    switch(panGestureRecognizer.state){
        case UIGestureRecognizerStateBegan:
            [self stopDeceleratingTimer];
            _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGFloat centerX = _thumbViewCenterXConstraintConstant + translation / 5;
            CGFloat percent = centerX / _trackView.frame.size.width;
            CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
            [self setValue:newValue];
            if ([self isContinuous]){
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
            if (fabs(velocity) > _fineTunningVelocityThreshold){
                CGFloat direction = velocity > 0 ? 1 : -1;
                _deceleratingVelocity = fabs(velocity) > _decelerationMaxVelocity ? _decelerationMaxVelocity * direction : velocity;
                _deceleratingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(handleDeceleratingTimer:) userInfo:nil repeats:true];
            } else {
                [self stopDeceleratingTimer];
            }
            break;
            
        default:
            break;
            
    }
}

- (void)leftTapWasTriggered {
    
    CGFloat newValue = [self value]-_stepValue;
    [self setValue:newValue];
}

- (void)rightTapWasTriggered {
    CGFloat newValue = [self value]+_stepValue;
    [self setValue:newValue];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    for (UIPress *press in presses){
        switch (press.type) {
            case UIPressTypeSelect:
                if(_dPadState == DPadStateLeft){
                    _panGestureRecognizer.enabled = false;
                    [self leftTapWasTriggered];
                } else if (_dPadState == DPadStateRight){
                    _panGestureRecognizer.enabled = false;
                    [self rightTapWasTriggered];
                } else {
                    _panGestureRecognizer.enabled = false;
                }
                break;
            default:
                break;
        }
    }
    _panGestureRecognizer.enabled = true;
    [super pressesBegan:presses withEvent:event];
}



- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        [self updateStateDependantViews];
    } completion:nil];
}

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self setupView];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setupView];
    return self;
}

- (id)init {
    self = [super init];
    [self setupView];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
