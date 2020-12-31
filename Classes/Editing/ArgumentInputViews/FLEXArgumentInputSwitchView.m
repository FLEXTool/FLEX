//
//  FLEXArgumentInputSwitchView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/16/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXArgumentInputSwitchView.h"

@interface FLEXArgumentInputSwitchView ()

@property (nonatomic) UISwitch *inputSwitch;

@end

@implementation FLEXArgumentInputSwitchView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputSwitch = [UISwitch new];
        [self.inputSwitch addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
        [self.inputSwitch sizeToFit];
        [self addSubview:self.inputSwitch];
    }
    return self;
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
    
    self.inputSwitch.frame = CGRectMake(0, self.topInputFieldVerticalLayoutGuide, self.inputSwitch.frame.size.width, self.inputSwitch.frame.size.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height += self.inputSwitch.frame.size.height;
    return fitSize;
}


#pragma mark - Class Helpers

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    // Only BOOLs. Current value is irrelevant.
    return strcmp(type, @encode(BOOL)) == 0;
}

@end
