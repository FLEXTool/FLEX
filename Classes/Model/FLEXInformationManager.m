//
//  FLEXInformationManager.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXInformationCollector.h"
#import "FLEXInformationManager.h"

@interface FLEXInformationManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *baseCollectors;

@end

@implementation FLEXInformationManager

- (NSMutableArray *)baseCollectors
{
    if (!_baseCollectors)
    {
        _baseCollectors = [NSMutableArray array];
    }
    
    return _baseCollectors;
}

+ (instancetype)sharedManager
{
    static FLEXInformationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

/*
- (instancetype)init
{
    self = [super init];
    
    return self;
}*/

- (void)setupCollectors
{
    NSArray *collectorTypes = [FLEXInformationCollector informationCollectors];
    
    for (Class type in collectorTypes)
    {
        id instance = [[type alloc] init];
        
        if ([instance respondsToSelector:@selector(setEnabled:)])
        {
            [instance setEnabled:YES];
        }
        
        [self.baseCollectors addObject:instance];
    }
}

@end
