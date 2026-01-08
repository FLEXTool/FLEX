//
//  CALayer+FLEX.m
//  FLEX
//
//  Created by Tanner on 2/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "CALayer+FLEX.h"

@implementation CALayer (FLEX)

- (BOOL)flex_continuousCorners {
    if (@available(iOS 13, *)) {
        return self.cornerCurve == kCACornerCurveContinuous;
    }
    return NO;
}

- (void)setFlex_continuousCorners:(BOOL)enabled {
    if (@available(iOS 13, *)) {
        self.cornerCurve = enabled ? kCACornerCurveContinuous : kCACornerCurveCircular;
    }
}

@end
