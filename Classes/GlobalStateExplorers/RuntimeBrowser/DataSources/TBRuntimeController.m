//
//  TBRuntimeController.m
//  TBTweakViewController
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBRuntimeController.h"
#import "TBRuntime.h"
#import "FLEXMethod.h"


@interface TBRuntimeController ()
@property (nonatomic, readonly) NSCache *bundlePathsCache;
@property (nonatomic, readonly) NSCache *bundleNamesCache;
@property (nonatomic, readonly) NSCache *classNamesCache;
@property (nonatomic, readonly) NSCache *methodsCache;
@end

@implementation TBRuntimeController

#pragma mark Initialization

static TBRuntimeController *controller = nil;
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [self new];
    });

    return controller;
}

- (id)init {
    self = [super init];
    if (self) {
        _bundlePathsCache = [NSCache new];
        _bundleNamesCache = [NSCache new];
        _classNamesCache  = [NSCache new];
        _methodsCache     = [NSCache new];
    }

    return self;
}

#pragma mark Public

+ (NSArray *)dataForKeyPath:(TBKeyPath *)keyPath {
    if (keyPath.bundleKey) {
        if (keyPath.classKey) {
            if (keyPath.methodKey) {
                return [[self shared] methodsForKeyPath:keyPath];
            } else {
                return [[self shared] classesForClassToken:keyPath.classKey andBundleToken:keyPath.bundleKey];
            }
        } else {
            return [[self shared] bundleNamesForToken:keyPath.bundleKey];
        }
    } else {
        return @[];
    }
}

+ (NSDictionary *)methodsForToken:(TBToken *)token
                         instance:(NSNumber *)inst
                        inClasses:(NSArray<NSString*> *)classes {
    NSMutableDictionary *methods = [NSMutableDictionary dictionary];
    for (NSString *className in classes) {
        NSMutableArray *target = [NSMutableArray arrayWithObject:className];
        methods[className] = [[TBRuntime runtime] methodsForToken:token
                                                         instance:inst
                                                        inClasses:target];
    }

    return methods;
}

+ (NSString *)shortBundleNameForClass:(NSString *)name {
    NSString *imagePath = @(class_getImageName(NSClassFromString(name)));
    return [[TBRuntime runtime] shortNameForImageName:imagePath];
}

+ (NSArray *)allBundleNames {
    return [TBRuntime runtime].imageDisplayNames;
}

#pragma mark Private

- (NSMutableArray *)bundlePathsForToken:(TBToken *)token {
    // Only cache if no wildcard
    BOOL shouldCache = token == TBWildcardOptionsNone;

    if (shouldCache) {
        NSMutableArray<NSString*> *cached = [self.bundlePathsCache objectForKey:token];
        if (cached) {
            return cached;
        }

        NSMutableArray<NSString*> *bundles = [[TBRuntime runtime] bundlePathsForToken:token];
        [self.bundlePathsCache setObject:bundles forKey:token];
        return bundles;
    }
    else {
        return [[TBRuntime runtime] bundlePathsForToken:token];
    }
}

- (NSMutableArray<NSString*> *)bundleNamesForToken:(TBToken *)token {
    // Only cache if no wildcard
    BOOL shouldCache = token == TBWildcardOptionsNone;

    if (shouldCache) {
        NSMutableArray<NSString*> *cached = [self.bundleNamesCache objectForKey:token];
        if (cached) {
            return cached;
        }

        NSMutableArray<NSString*> *bundles = [[TBRuntime runtime] bundleNamesForToken:token];
        [self.bundleNamesCache setObject:bundles forKey:token];
        return bundles;
    }
    else {
        return [[TBRuntime runtime] bundleNamesForToken:token];
    }
}

- (NSMutableArray<NSString*> *)classesForClassToken:(TBToken *)clsToken andBundleToken:(TBToken *)bundleToken {
    // Only cache if no wildcard
    BOOL shouldCache = bundleToken.options == 0 && clsToken.options == 0;
    NSString *key = nil;

    if (shouldCache) {
        key = [@[bundleToken.description, clsToken.description] componentsJoinedByString:@"+"];
        NSMutableArray<NSString*> *cached = [self.classNamesCache objectForKey:key];
        if (cached) {
            return cached;
        }
    }

    NSMutableArray<NSString*> *bundles = [self bundlePathsForToken:bundleToken];
    NSMutableArray<NSString*> *classes = [[TBRuntime runtime] classesForToken:clsToken inBundles:bundles];

    if (shouldCache) {
        [self.classNamesCache setObject:classes forKey:key];
    }

    return classes;
}

- (NSMutableArray<FLEXMethod*> *)methodsForKeyPath:(TBKeyPath *)keyPath {
    // Only cache if no wildcard, but check cache anyway bc I'm lazy
    NSMutableArray<FLEXMethod*> *cached = [self.methodsCache objectForKey:keyPath];
    if (cached) {
        return cached;
    }

    NSMutableArray<NSString*> *classes = [self classesForClassToken:keyPath.classKey andBundleToken:keyPath.bundleKey];
    NSMutableArray<FLEXMethod*> *methods = [[TBRuntime runtime] methodsForToken:keyPath.methodKey
                                                                     instance:keyPath.instanceMethods
                                                                    inClasses:classes];

    [methods sortUsingComparator:^NSComparisonResult(FLEXMethod *m1, FLEXMethod *m2) {
        return [m1.description caseInsensitiveCompare:m2.description];
    }];

    // Only cache if no wildcard
    if (keyPath.bundleKey.isAbsolute &&
        keyPath.classKey.isAbsolute) {
        [self.methodsCache setObject:methods forKey:keyPath];
    }

    return methods;
}

@end
