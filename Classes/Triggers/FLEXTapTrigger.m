//
//  FLEXTapTrigger.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXTrigger+Private.h"

#import "FLEXTapTrigger.h"

@interface FLEXTapTrigger ()

@property (nonatomic, strong, readwrite) UILongPressGestureRecognizer *recognizer;

@end

@implementation FLEXTapTrigger

- (UILongPressGestureRecognizer *)recognizer
{
    if (!_recognizer)
    {
        _recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(trigger:)];
        _recognizer.numberOfTouchesRequired = 4;
        _recognizer.minimumPressDuration = 2.0;
    }
    
    return _recognizer;
}

- (void)integrate
{
    UIWindow *keyWindow = [FLEXTrigger keyWindow];
    [keyWindow addGestureRecognizer:self.recognizer];
}

@end
