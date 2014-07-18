//
//  FLEXArgumentInputNumberView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXArgumentInputNumberView.h"
#import "FLEXRuntimeUtility.h"

@implementation FLEXArgumentInputNumberView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding
{
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.targetSize = FLEXArgumentInputViewSizeSmall;
    }
    return self;
}

- (void)setInputValue:(id)inputValue
{
    if ([inputValue respondsToSelector:@selector(stringValue)]) {
        self.inputTextView.text = [inputValue stringValue];
    }
}

- (id)inputValue
{
    return [FLEXRuntimeUtility valueForNumberWithObjCType:[self.typeEncoding UTF8String] fromInputString:self.inputTextView.text];
}

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value
{
    static NSArray *primitiveTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        primitiveTypes = @[@(@encode(char)),
                           @(@encode(int)),
                           @(@encode(short)),
                           @(@encode(long)),
                           @(@encode(long long)),
                           @(@encode(unsigned char)),
                           @(@encode(unsigned int)),
                           @(@encode(unsigned short)),
                           @(@encode(unsigned long)),
                           @(@encode(unsigned long long)),
                           @(@encode(float)),
                           @(@encode(double))];
    });
    return type && [primitiveTypes containsObject:@(type)];
}

@end
