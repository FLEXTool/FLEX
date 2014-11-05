//
//  FLEXShakeTrigger.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "NSObject+Swizzle.h"

#import "FLEXShakeTrigger.h"

NSString* const FLEXShakeMotionNotification = @"kFLEXShakeMotionNotification";

@implementation FLEXShakeTrigger

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trigger:) name:FLEXShakeMotionNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
