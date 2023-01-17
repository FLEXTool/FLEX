//
//  FLEXArgumentInputNotSupportedView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/18/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputNotSupportedView.h"
#import "Classes/Utility/FLEXColor.h"

@implementation FLEXArgumentInputNotSupportedView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView.userInteractionEnabled = NO;
        self.inputTextView.backgroundColor = [FLEXColor secondaryGroupedBackgroundColorWithAlpha:0.5];
        self.inputPlaceholderText = @"nil  (type not supported)";
        self.targetSize = FLEXArgumentInputViewSizeSmall;
    }
    return self;
}

@end
