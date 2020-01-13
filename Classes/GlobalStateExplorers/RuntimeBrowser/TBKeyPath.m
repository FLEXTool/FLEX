//
//  FLEXKeyPath.m
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPath.h"


@interface TBKeyPath () {
    NSString *tb_description;
}
@end

@implementation TBKeyPath

+ (instancetype)empty {
    static TBKeyPath *empty = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TBToken *any = [TBToken any];

        empty = [self new];
        empty->_bundleKey = any;
        empty->tb_description = @"";
    });

    return empty;
}

+ (instancetype)bundle:(TBToken *)bundle
                 class:(TBToken *)cls
                method:(TBToken *)method
            isInstance:(NSNumber *)instance
                string:(NSString *)keyPathString {
    TBKeyPath *keyPath  = [self new];
    keyPath->_bundleKey = bundle;
    keyPath->_classKey  = cls;
    keyPath->_methodKey = method;

    keyPath->_instanceMethods = instance;

    // Remove irrelevant trailing '*' for equality purposes
    if ([keyPathString hasSuffix:@"*"]) {
        keyPathString = [keyPathString substringToIndex:keyPathString.length];
    }
    keyPath->tb_description = keyPathString;

    return keyPath;
}

- (NSString *)description {
    return tb_description;
}

- (NSUInteger)hash {
    return tb_description.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TBKeyPath class]]) {
        TBKeyPath *kp = object;
        return [tb_description isEqualToString:kp->tb_description];
    }

    return NO;
}

@end
