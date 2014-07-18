//
//  FLEXArgumentInputStringView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXArgumentInputStringView.h"
#import "FLEXRuntimeUtility.h"

@implementation FLEXArgumentInputStringView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding
{
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.targetSize = FLEXArgumentInputViewSizeLarge;
    }
    return self;
}

- (void)setInputValue:(id)inputValue
{
    self.inputTextView.text = inputValue;
}

- (id)inputValue
{
    // Interpret empty string as nil. We loose the ablitiy to set empty string as a string value,
    // but we accept that tradeoff in exchange for not having to type quotes for every string.
    return [self.inputTextView.text length] > 0 ? [self.inputTextView.text copy] : nil;
}


#pragma mark -

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value
{
    BOOL supported = type && strcmp(type, FLEXEncodeClass(NSString)) == 0;
    supported = supported || (value && [value isKindOfClass:[NSString class]]);
    return supported;
}

@end
