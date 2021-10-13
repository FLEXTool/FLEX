//
//  NSUserDefaults+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

// Only use these if the getters and setters aren't good enough for whatever reason
extern NSString * const kFLEXDefaultsToolbarTopMarginKey;
extern NSString * const kFLEXDefaultsiOSPersistentOSLogKey;
extern NSString * const kFLEXDefaultsHidePropertyIvarsKey;
extern NSString * const kFLEXDefaultsHidePropertyMethodsKey;
extern NSString * const kFLEXDefaultsHidePrivateMethodsKey;
extern NSString * const kFLEXDefaultsShowMethodOverridesKey;
extern NSString * const kFLEXDefaultsHideVariablePreviewsKey;
extern NSString * const kFLEXDefaultsNetworkObserverEnabledKey;
extern NSString * const kFLEXDefaultsNetworkHostDenylistKey;
extern NSString * const kFLEXDefaultsDisableOSLogForceASLKey;
extern NSString * const kFLEXDefaultsRegisterJSONExplorerKey;

/// All BOOL preferences are NO by default
@interface NSUserDefaults (FLEX)

- (void)flex_toggleBoolForKey:(NSString *)key;

@property (nonatomic) double flex_toolbarTopMargin;

@property (nonatomic) BOOL flex_networkObserverEnabled;
// Not actually stored in defaults, but written to a file
@property (nonatomic) NSArray<NSString *> *flex_networkHostDenylist;

/// Whether or not to register the object explorer as a JSON viewer on launch
@property (nonatomic) BOOL flex_registerDictionaryJSONViewerOnLaunch;

/// Disable os_log and re-enable ASL. May break Console.app output.
@property (nonatomic) BOOL flex_disableOSLog;
@property (nonatomic) BOOL flex_cacheOSLogMessages;

@property (nonatomic) BOOL flex_explorerHidesPropertyIvars;
@property (nonatomic) BOOL flex_explorerHidesPropertyMethods;
@property (nonatomic) BOOL flex_explorerHidesPrivateMethods;
@property (nonatomic) BOOL flex_explorerShowsMethodOverrides;
@property (nonatomic) BOOL flex_explorerHidesVariablePreviews;

@end
