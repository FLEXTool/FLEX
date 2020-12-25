//
//  FLEXArgumentInputSwitchView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/16/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXArgumentInputSwitchView.h"
#import "fakes.h"
@interface FLEXArgumentInputSwitchView ()
#if !TARGET_OS_TV
@property (nonatomic) UISwitch *inputSwitch;
#else
@property (nonatomic) UIFakeSwitch *inputSwitch;
#endif
@end

@implementation FLEXArgumentInputSwitchView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
#if !TARGET_OS_TV
        self.inputSwitch = [UISwitch new];
        [self.inputSwitch sizeToFit];
        [self.inputSwitch addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
        
#else
        self.inputSwitch = [UIFakeSwitch newSwitch];
        [self.inputSwitch addTarget:self action:@selector(changeSwitchValue:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
        [self addSubview:self.inputSwitch];
    }
    return self;
}

- (void)changeSwitchValue:(UIFakeSwitch *)switchView {
    [switchView setOn:!switchView.isOn];
    [self switchValueDidChange:switchView];
}

#pragma mark Input/Output

- (void)setInputValue:(id)inputValue {
    BOOL on = NO;
    if ([inputValue isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)inputValue;
        on = [number boolValue];
    } else if ([inputValue isKindOfClass:[NSValue class]]) {
        NSValue *value = (NSValue *)inputValue;
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            [value getValue:&on];
        }
    }
    self.inputSwitch.on = on;
}

- (id)inputValue {
    BOOL isOn = [self.inputSwitch isOn];
    NSValue *boxedBool = [NSValue value:&isOn withObjCType:@encode(BOOL)];
    return boxedBool;
}

- (void)switchValueDidChange:(id)sender {
    [self.delegate argumentInputViewValueDidChange:self];
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];
#if TARGET_OS_TV
    self.inputSwitch.frame = CGRectMake(50, 50, 200, 60);
#else
    self.inputSwitch.frame = CGRectMake(0, self.topInputFieldVerticalLayoutGuide, self.inputSwitch.frame.size.width, self.inputSwitch.frame.size.height);
#endif
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
#if TARGET_OS_TV
    fitSize.height += 110;
#else
    fitSize.height += self.inputSwitch.frame.size.height;
#endif
    return fitSize;
}


#pragma mark - Class Helpers

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    // Only BOOLs. Current value is irrelevant.
    return strcmp(type, @encode(BOOL)) == 0;
}

@end
