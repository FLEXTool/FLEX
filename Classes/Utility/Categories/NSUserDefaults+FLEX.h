//
//  NSUserDefaults+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

// Only use these if the getters and setters aren't good enough for whatever reaso
extern NSString * const kFLEXDefaultsToolbarTopMarginKey;
extern NSString * const kFLEXDefaultsiOSPersistentOSLogKey;
extern NSString * const kFLEXDefaultsHidePropertyIvarsKey;
extern NSString * const kFLEXDefaultsHidePropertyMethodsKey;
extern NSString * const kFLEXDefaultsHideMethodOverridesKey;

@interface NSUserDefaults (FLEX)

- (void)toggleBoolForKey:(NSString *)key;

@property (nonatomic) double flex_toolbarTopMargin;

/// NO by default
@property (nonatomic) BOOL flex_cacheOSLogMessages;

/// NO by default
@property (nonatomic) BOOL flex_explorerHidesPropertyIvars;
/// NO by default
@property (nonatomic) BOOL flex_explorerHidesPropertyMethods;
/// NO by default
@property (nonatomic) BOOL flex_explorerShowsMethodOverrides;

@end
