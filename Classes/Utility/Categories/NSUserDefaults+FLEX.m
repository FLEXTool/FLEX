//
//  NSUserDefaults+FLEX.m
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSUserDefaults+FLEX.h"

NSString * const kFLEXDefaultsToolbarTopMarginKey = @"com.flex.FLEXToolbar.topMargin";
NSString * const kFLEXDefaultsiOSPersistentOSLogKey = @"com.flipborad.flex.enable_persistent_os_log";
NSString * const kFLEXDefaultsHidePropertyIvarsKey = @"com.flipboard.FLEX.hide_property_ivars";
NSString * const kFLEXDefaultsHidePropertyMethodsKey = @"com.flipboard.FLEX.hide_property_methods";
NSString * const kFLEXDefaultsHideMethodOverridesKey = @"com.flipboard.FLEX.hide_method_overrides";
NSString * const kFLEXDefaultsNetworkHostBlacklistKey = @"com.flipboard.FLEX.network_host_blacklist";

#define FLEXDefaultsPathForFile(name) ({ \
    NSArray *paths = NSSearchPathForDirectoriesInDomains( \
        NSLibraryDirectory, NSUserDomainMask, NO \
    ); \
    [paths[0] stringByAppendingPathComponent:@"Preferences"]; \
})

@implementation NSUserDefaults (FLEX)

/// @param filename the name of a plist file without any extension
- (NSString *)flex_defaultsPathForFile:(NSString *)filename {
    filename = [filename stringByAppendingPathExtension:@"plist"];
    
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSUserDomainMask, YES
    );
    NSString *preferences = [paths[0] stringByAppendingPathComponent:@"Preferences"];
    return [preferences stringByAppendingPathComponent:filename];
}

- (void)toggleBoolForKey:(NSString *)key {
    [self setBool:![self boolForKey:key] forKey:key];
    [NSNotificationCenter.defaultCenter postNotificationName:key object:nil];
}

- (double)flex_toolbarTopMargin {
    if ([self objectForKey:kFLEXDefaultsToolbarTopMarginKey]) {
        return [self doubleForKey:kFLEXDefaultsToolbarTopMarginKey];
    }
    
    return 100;
}

- (void)setFlex_toolbarTopMargin:(double)margin {
    [self setDouble:margin forKey:kFLEXDefaultsToolbarTopMarginKey];
}

- (BOOL)flex_cacheOSLogMessages {
    return [self boolForKey:kFLEXDefaultsiOSPersistentOSLogKey];
}

- (void)setFlex_cacheOSLogMessages:(BOOL)cache {
    [self setBool:cache forKey:kFLEXDefaultsiOSPersistentOSLogKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsiOSPersistentOSLogKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesPropertyIvars {
    return [self boolForKey:kFLEXDefaultsHidePropertyIvarsKey];
}

- (void)setFlex_explorerHidesPropertyIvars:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHidePropertyIvarsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHidePropertyIvarsKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesPropertyMethods {
    return [self boolForKey:kFLEXDefaultsHidePropertyMethodsKey];
}

- (void)setFlex_explorerHidesPropertyMethods:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHidePropertyMethodsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHidePropertyMethodsKey
        object:nil
    ];
}

- (BOOL)flex_explorerShowsMethodOverrides {
    return [self boolForKey:kFLEXDefaultsHideMethodOverridesKey];
}

- (void)setFlex_explorerShowsMethodOverrides:(BOOL)show {
    [self setBool:show forKey:kFLEXDefaultsHideMethodOverridesKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHideMethodOverridesKey
        object:nil
    ];
}

- (NSArray<NSString *> *)flex_networkHostBlacklist {
    return [NSArray arrayWithContentsOfFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostBlacklistKey
    ]] ?: @[];
}

- (void)setFlex_networkHostBlacklist:(NSArray<NSString *> *)blacklist {
    NSParameterAssert(blacklist);
    [blacklist writeToFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostBlacklistKey
    ] atomically:YES];
}

@end
