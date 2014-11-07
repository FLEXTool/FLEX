@import Foundation;
@import ObjectiveC.runtime;
@import UIKit.UIApplication;

#import <KZAsserts/KZAsserts.h>
#import "KZBootstrap.h"

static NSString *const kLastEnvKey = @"KZBCurrentEnv";

@implementation KZBootstrap

+ (void)ready
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkEnvironmentOverride) name:UIApplicationWillEnterForegroundNotification object:nil];
  [self environmentVariables];
  [self checkEnvironmentOverride];
}

+ (NSString *)shortVersionString
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)gitBranch
{
  NSArray *components = [self.versionString componentsSeparatedByString:@"-"];
  return components.count == 2 ? components[1] : nil;
}

+ (NSInteger)buildNumber
{
  NSArray *components = [self.versionString componentsSeparatedByString:@"-"];
  return components.count >= 1 ? [(NSString *)components[0] integerValue] : 0;
}

+ (NSString *)versionString
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (void)checkEnvironmentOverride
{
  NSString *envOverride = self.environmentOverride;
  if (envOverride && ![self.currentEnvironment isEqualToString:envOverride]) {
    self.currentEnvironment = envOverride;
  }
}

+ (id)envVariableForKey:(NSString *)key
{
  id value = self.environmentVariables[key][self.currentEnvironment];
  AssertTrueOrReturnNil(value);
  return value;
}

+ (NSArray *)environments
{
  static dispatch_once_t onceToken;
  static NSArray *listOfEnvironments;
  
  dispatch_once(&onceToken, ^{
    NSDictionary *propertyList = [self environment];
        
    NSString *envKey = @"KZBEnvironments";
    listOfEnvironments = propertyList[envKey];
  });
  
  return listOfEnvironments;
}

+ (NSDictionary *)environmentVariables
{
  static dispatch_once_t onceToken;
  static NSDictionary *environmentVariables;
    
  dispatch_once(&onceToken, ^{
    NSMutableDictionary *propertyList = [[self environment] mutableCopy];
      
    NSString *envKey = @"KZBEnvironments";
    [propertyList removeObjectForKey:envKey];
    environmentVariables = [propertyList copy];
  });
    
  return environmentVariables;
}

+ (NSDictionary *)environment
{
  static dispatch_once_t onceToken;
  static NSDictionary *environment;

  dispatch_once(&onceToken, ^{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"KZBEnvironments" withExtension:@"plist"];
    AssertTrueOrReturn(url);
    NSError *error = nil;
    NSMutableDictionary *propertyList = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:url] options:NSPropertyListMutableContainers format:NULL error:&error];
    AssertTrueOrReturn(propertyList);
      
    environment = [propertyList copy];

    NSString *envKey = @"KZBEnvironments";
    NSArray *listOfEnvironments = [propertyList valueForKey:envKey];
    [propertyList removeObjectForKey:envKey];
    [self ensureValidityOfEnvironmentVariables:propertyList forEnvList:listOfEnvironments];
  });

  return environment;
}

+ (void)ensureValidityOfEnvironmentVariables:(NSMutableDictionary *)dictionary forEnvList:(NSArray *)list
{
  __block BOOL environmentVariablesAreValid = YES;
  [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *configurations, BOOL *stop) {
    //! format check.
    if (![key isKindOfClass:NSString.class] || ![configurations isKindOfClass:NSDictionary.class]) {
      environmentVariablesAreValid = NO;
      *stop = YES;
      return;
    }

    //! make sure all env have set variable
    NSMutableArray *listOfEnvSetup = [list mutableCopy];
    [configurations.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
      if (![key isKindOfClass:NSString.class]) {
        environmentVariablesAreValid = NO;
        *stop = YES;
      }

      [listOfEnvSetup removeObject:key];
    }];

    if (listOfEnvSetup.count != 0) {
      environmentVariablesAreValid = NO;
    }

    if (!environmentVariablesAreValid) {
      *stop = YES;
    }
  }];

  AssertTrueOrReturn(environmentVariablesAreValid);
}

+ (NSString *)environmentOverride
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:@"KZBEnvOverride"];
}

static const void *kEnvKey = &kEnvKey;
static const void *kDefaultBuildEnvKey = &kDefaultBuildEnvKey;

+ (void)setDefaultBuildEnvironment:(NSString*)defaultBuildEnv
{
  objc_setAssociatedObject(self, kDefaultBuildEnvKey, defaultBuildEnv, OBJC_ASSOCIATION_COPY);
}

+ (NSString*)defaultBuildEnvironment
{
  return objc_getAssociatedObject(self, kDefaultBuildEnvKey);
}

+ (NSString *)currentEnvironment
{
  NSString *env = objc_getAssociatedObject(self, kEnvKey);
  if (!env) {
    NSString *defaultBuildEnv = self.defaultBuildEnvironment;
    AssertTrueOrReturnNil(defaultBuildEnv);
    env = self.previousEnvironment ?: defaultBuildEnv;
    objc_setAssociatedObject(self, kEnvKey, env, OBJC_ASSOCIATION_COPY);
    return env;
  }
  return env;
}

+ (void)setCurrentEnvironment:(NSString *)environment
{
  NSString *oldEnv = self.currentEnvironment;
  objc_setAssociatedObject(self, kEnvKey, environment, OBJC_ASSOCIATION_COPY);
  if (oldEnv && self.onCurrentEnvironmentChanged && ![oldEnv isEqualToString:environment]) {
    self.onCurrentEnvironmentChanged(environment, oldEnv);
  }

  //! persist current env between versions
  [[NSUserDefaults standardUserDefaults] setObject:environment forKey:kLastEnvKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (NSString *)previousEnvironment
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:kLastEnvKey];
}

static const void *kOnCurrentEnvChangedKey = &kOnCurrentEnvChangedKey;

+ (void (^)(NSString *, NSString *))onCurrentEnvironmentChanged
{
  return objc_getAssociatedObject(self, kOnCurrentEnvChangedKey);
}

+ (void)setOnCurrentEnvironmentChanged:(void (^)(NSString *, NSString *))block
{
  objc_setAssociatedObject(self, kOnCurrentEnvChangedKey, block, OBJC_ASSOCIATION_COPY);
}

@end
