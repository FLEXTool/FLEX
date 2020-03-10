//
//  NSUserDefaults+FLEX.m
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSUserDefaults+FLEX.h"

static NSString * const kFLEXToolbarTopMarginKey = @"com.flex.FLEXToolbar.topMargin";
static NSString * const kFLEXHideRedundantIvarsKey = @"com.flipboard.FLEX.hide_redundant_ivars";
static NSString * const kFLEXHideRedundantMethodsKey = @"com.flipboard.FLEX.hide_redundant_methods";
static NSString * const kFLEXiOSPersistentOSLogKey = @"com.flipborad.flex.enable_persistent_os_log";

@implementation NSUserDefaults (FLEX)

- (double)flex_toolbarTopMargin {
    if ([self objectForKey:kFLEXToolbarTopMarginKey]) {
        return [self doubleForKey:kFLEXToolbarTopMarginKey];
    }
    
    return 100;
}

- (void)setFlex_toolbarTopMargin:(double)margin {
    [self setDouble:margin forKey:kFLEXToolbarTopMarginKey];
}

- (BOOL)flex_cacheOSLogMessages {
    return [self boolForKey:kFLEXiOSPersistentOSLogKey];
}

- (void)setFlex_cacheOSLogMessages:(BOOL)cache {
    [self setBool:cache forKey:kFLEXiOSPersistentOSLogKey];
}

- (BOOL)flex_explorerHidesRedundantIvars {
    return [self boolForKey:kFLEXHideRedundantIvarsKey];
}

- (void)setFlex_explorerHidesRedundantIvars:(BOOL)hide {
    [self setBool:hide forKey:kFLEXHideRedundantIvarsKey];
}

- (BOOL)flex_explorerHidesRedundantMethods {
    return [self boolForKey:kFLEXHideRedundantMethodsKey];
}

- (void)setFlex_explorerHidesRedundantMethods:(BOOL)hide {
    [self setBool:hide forKey:kFLEXHideRedundantMethodsKey];
}

@end
