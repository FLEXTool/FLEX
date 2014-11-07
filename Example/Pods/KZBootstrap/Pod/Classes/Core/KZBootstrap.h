#import "KZBootstrapMacros.h"

@import Foundation;

@interface KZBootstrap : NSObject
+ (NSString *)shortVersionString;

+ (NSString *)gitBranch;

+ (NSInteger)buildNumber;

+ (void)setDefaultBuildEnvironment:(NSString*)defaultBuildEnv;

//! loads from ENV variable by default
+ (NSString *)currentEnvironment;

+ (void)setCurrentEnvironment:(NSString *)environment;

+ (void)setOnCurrentEnvironmentChanged:(void (^)(NSString *newEnv, NSString *oldEnv))block;

+ (id)envVariableForKey:(NSString *)key;

+ (void)ready;

/**
 *  Returns all environments that are included in environments PLIST
 *
 *  @return array of strings that represent environments
 */
+ (NSArray *)environments;
@end