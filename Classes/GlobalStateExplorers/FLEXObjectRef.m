//
//  FLEXObjectRef.m
//  FLEX
//
//  Created by Tanner Bennett on 7/24/18.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXObjectRef.h"
#import "FLEXRuntimeUtility.h"
#import "NSArray+FLEX.h"

@interface FLEXObjectRef ()
@property (nonatomic, readonly) BOOL wantsSummary;
@end

@implementation FLEXObjectRef
@synthesize summary = _summary;

+ (instancetype)referencing:(id)object {
    return [self referencing:object showSummary:YES];
}

+ (instancetype)referencing:(id)object showSummary:(BOOL)showSummary {
    return [[self alloc] initWithObject:object ivarName:nil showSummary:showSummary];
}

+ (instancetype)referencing:(id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName showSummary:YES];
}

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects {
    return [objects flex_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:YES];
    }];
}

+ (NSArray<FLEXObjectRef *> *)referencingClasses:(NSArray<Class> *)classes {
    return [classes flex_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:NO];
    }];
}

- (id)initWithObject:(id)object ivarName:(NSString *)ivar showSummary:(BOOL)showSummary {
    self = [super init];
    if (self) {
        _object = object;
        _wantsSummary = showSummary;

        NSString *class = [FLEXRuntimeUtility safeClassNameForObject:object];
        if (ivar) {
            _reference = [NSString stringWithFormat:@"%@ %@", class, ivar];
        } else if (showSummary) {
            _reference = [NSString stringWithFormat:@"%@ %p", class, object];
        } else {
            _reference = class;
        }
    }

    return self;
}

- (NSString *)summary {
    if (self.wantsSummary) {
        if (!_summary) {
            _summary = [FLEXRuntimeUtility summaryForObject:self.object];
        }
        
        return _summary;
    }
    else {
        return nil;
    }
}

@end
