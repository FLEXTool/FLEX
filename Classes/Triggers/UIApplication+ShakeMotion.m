//
//  UIApplication+ShakeMotion.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "NSObject+Swizzle.h"

#import "FLEXShakeTrigger.h"

#import "UIApplication+ShakeMotion.h"

@implementation UIApplication (ShakeMotion)

+ (void)load
{
    [UIApplication swizzleInstanceMethod:@selector(sendEvent:) withMethod:@selector(flex_sendEvent:)];
}

- (void)flex_sendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FLEXShakeMotionNotification object:nil];
    }
    
    [self flex_sendEvent:event];
}

@end
