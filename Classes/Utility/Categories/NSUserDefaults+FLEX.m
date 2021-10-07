//
//  NSUserDefaults+FLEX.m
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "NSUserDefaults+FLEX.h"

NSString * const kFLEXDefaultsToolbarTopMarginKey = @"com.FLEX.FLEXToolbar.topMargin";
NSString * const kFLEXDefaultsiOSPersistentOSLogKey = @"com.FLEX.enable_persistent_os_log";
NSString * const kFLEXDefaultsHidePropertyIvarsKey = @"com.FLEX.hide_property_ivars";
NSString * const kFLEXDefaultsHidePropertyMethodsKey = @"com.FLEX.hide_property_methods";
NSString * const kFLEXDefaultsHidePrivateMethodsKey = @"com.FLEX.hide_private_or_namespaced_methods";
NSString * const kFLEXDefaultsShowMethodOverridesKey = @"com.FLEX.show_method_overrides";
NSString * const kFLEXDefaultsHideVariablePreviewsKey = @"com.FLEX.hide_variable_previews";
NSString * const kFLEXDefaultsNetworkHostDenylistKey = @"com.FLEX.network_host_denylist";
NSString * const kFLEXDefaultsDisableOSLogForceASLKey = @"com.FLEX.try_disable_os_log";
NSString * const kFLEXDefaultsRegisterJSONExplorerKey = @"com.FLEX.view_json_as_object";

#define FLEXDefaultsPathForFile(name) ({ \
    NSArray *paths = NSSearchPathForDirectoriesInDomains( \
        NSLibraryDirectory, NSUserDomainMask, YES \
    ); \
    [paths[0] stringByAppendingPathComponent:@"Preferences"]; \
})

@implementation NSUserDefaults (FLEX)

#pragma mark Internal

/// @param filename the name of a plist file without any extension
- (NSString *)flex_defaultsPathForFile:(NSString *)filename {
    filename = [filename stringByAppendingPathExtension:@"plist"];
    
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSUserDomainMask, YES
    );
    NSString *preferences = [paths[0] stringByAppendingPathComponent:@"Preferences"];
    return [preferences stringByAppendingPathComponent:filename];
}

#pragma mark Helper

- (void)flex_toggleBoolForKey:(NSString *)key {
    [self setBool:![self boolForKey:key] forKey:key];
    [NSNotificationCenter.defaultCenter postNotificationName:key object:nil];
}

#pragma mark Misc

- (double)flex_toolbarTopMargin {
    if ([self objectForKey:kFLEXDefaultsToolbarTopMarginKey]) {
        return [self doubleForKey:kFLEXDefaultsToolbarTopMarginKey];
    }
    
    return 100;
}

- (void)setFlex_toolbarTopMargin:(double)margin {
    [self setDouble:margin forKey:kFLEXDefaultsToolbarTopMarginKey];
}

- (NSArray<NSString *> *)flex_networkHostDenylist {
    return [NSArray arrayWithContentsOfFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostDenylistKey
    ]] ?: @[];
}

- (void)setFlex_networkHostDenylist:(NSArray<NSString *> *)denylist {
    NSParameterAssert(denylist);
    [denylist writeToFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostDenylistKey
    ] atomically:YES];
}

- (BOOL)flex_registerDictionaryJSONViewerOnLaunch {
    return [self boolForKey:kFLEXDefaultsRegisterJSONExplorerKey];
}

- (void)setFlex_registerDictionaryJSONViewerOnLaunch:(BOOL)enable {
    [self setBool:enable forKey:kFLEXDefaultsRegisterJSONExplorerKey];
}

#pragma mark System Log

- (BOOL)flex_disableOSLog {
    return [self boolForKey:kFLEXDefaultsDisableOSLogForceASLKey];
}

- (void)setFlex_disableOSLog:(BOOL)disable {
    [self setBool:disable forKey:kFLEXDefaultsDisableOSLogForceASLKey];
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

#pragma mark Object Explorer

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

- (BOOL)flex_explorerHidesPrivateMethods {
    return [self boolForKey:kFLEXDefaultsHidePrivateMethodsKey];
}

- (void)setFlex_explorerHidesPrivateMethods:(BOOL)show {
    [self setBool:show forKey:kFLEXDefaultsHidePrivateMethodsKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kFLEXDefaultsHidePrivateMethodsKey
        object:nil
    ];
}

- (BOOL)flex_explorerShowsMethodOverrides {
    return [self boolForKey:kFLEXDefaultsShowMethodOverridesKey];
}

- (void)setFlex_explorerShowsMethodOverrides:(BOOL)show {
    [self setBool:show forKey:kFLEXDefaultsShowMethodOverridesKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kFLEXDefaultsShowMethodOverridesKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesVariablePreviews {
    return [self boolForKey:kFLEXDefaultsHideVariablePreviewsKey];
}

- (void)setFlex_explorerHidesVariablePreviews:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHideVariablePreviewsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHideVariablePreviewsKey
        object:nil
    ];
}

@end
