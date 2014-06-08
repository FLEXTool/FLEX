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
        // Some apps have windows at UIWindowLevelStatusBar + 1.0, so we go one more above that.
        // If necessary, this could be increased further.
        self.windowLevel = UIWindowLevelStatusBar + 2.0;
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
