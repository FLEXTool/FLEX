//
//  FLEXTriggerManager.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXTapTrigger.h"
#import "FLEXShakeTrigger.h"

#import "FLEXTriggerManager.h"

@interface FLEXTriggerManager ()

@property (nonatomic, strong) NSMutableSet *baseTriggers;

@end

@implementation FLEXTriggerManager

#pragma mark - Getters and Setters

+ (instancetype)sharedManager
{
    static FLEXTriggerManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (NSArray *)triggers
{
    return [self.baseTriggers copy];
}

- (NSMutableSet *)baseTriggers
{
    if (!_baseTriggers)
    {
        _baseTriggers = [NSMutableSet set];
    }
    
    return _baseTriggers;
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        
    }
    
    return self;
}

#pragma mark - Methods

+ (void)load
{
    //
    // Sign to a notification
    //
    
    [[NSNotificationCenter defaultCenter] addObserver:[FLEXTriggerManager sharedManager] selector:@selector(activate) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)addTrigger:(FLEXTrigger *)trigger
{
    [self.baseTriggers addObject:trigger];
    
    //
    // Integrate trigger
    //
    
    [trigger integrate];
}

- (void)activate
{
    [self addTrigger:[[FLEXShakeTrigger alloc] init]];
    [self addTrigger:[[FLEXTapTrigger alloc] init]];
}

@end
