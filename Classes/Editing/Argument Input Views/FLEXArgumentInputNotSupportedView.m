//
//  FLEXArgumentInputNotSupportedView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/18/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXArgumentInputNotSupportedView.h"

@implementation FLEXArgumentInputNotSupportedView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding
{
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView.userInteractionEnabled = NO;
        self.inputTextView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        self.inputTextView.text = @"nil";
        self.targetSize = FLEXArgumentInputViewSizeSmall;
    }
    return self;
}

@end
