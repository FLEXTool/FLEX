//
//  CALayer+FLEX.m
//  FLEX
//
//  Created by Tanner on 2/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "CALayer+FLEX.h"

@interface CALayer (Private)
@property (nonatomic) BOOL continuousCorners;
@end

@implementation CALayer (FLEX)

static BOOL respondsToContinuousCorners = NO;

+ (void)load {
    respondsToContinuousCorners = [CALayer
        instancesRespondToSelector:@selector(setContinuousCorners:)
    ];
}

- (BOOL)flex_continuousCorners {
    if (respondsToContinuousCorners) {
        return self.continuousCorners;
    }
    
    return NO;
}

- (void)setFlex_continuousCorners:(BOOL)enabled {
    if (respondsToContinuousCorners) {
        if (@available(iOS 13, *)) {
            self.cornerCurve = kCACornerCurveContinuous;
        } else {
            self.continuousCorners = enabled;
//            self.masksToBounds = NO;
    //        self.allowsEdgeAntialiasing = YES;
    //        self.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerTopEdge | kCALayerBottomEdge;
        }
    }
}

@end
