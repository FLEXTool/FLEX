//
//  FLEXWindow.m
//  Flipboard
//
//  Created by Ryan Olson on 4/13/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXWindow.h"

@implementation FLEXWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // Some apps have windows at UIWindowLevelStatusBar + n.
        // Using CGFLOAT_MAX works on 7.0 devieces but doesn't work in the 7.1 sim.
        // Hopefully status bar level + 1000.0 gets the job done. It works in the 7.1 sim.
        self.windowLevel = UIWindowLevelStatusBar + 1000.0;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL pointInside = NO;
    if ([self.eventDelegate shouldHandleTouchAtPoint:point]) {
        pointInside = [super pointInside:point withEvent:event];
    }
    return pointInside;
}

@end
