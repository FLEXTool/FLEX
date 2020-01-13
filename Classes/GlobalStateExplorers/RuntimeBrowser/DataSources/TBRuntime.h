//
//  TBRuntime.h
//  TBTweakViewController
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBToken.h"
@class FLEXMethod;


/// Accepts runtime queries given a token.
@interface TBRuntime : NSObject

+ (instancetype)runtime;

/// Called automatically when \c TBRuntime is first used.
/// You may call it again when you think a library has
/// been loaded since this method was first called.
- (void)reloadLibrariesList;

/// An array of strings representing the currently loaded libraries.
@property (nonatomic, readonly) NSArray<NSString*> *imageDisplayNames;

- (NSString *)shortNameForImageName:(NSString *)imageName;

/// @return Bundle names for the UI
- (NSMutableArray<NSString*> *)bundleNamesForToken:(TBToken *)token;
/// @return Bundle paths for more queries
- (NSMutableArray<NSString*> *)bundlePathsForToken:(TBToken *)token;
/// @return Class names
- (NSMutableArray<NSString*> *)classesForToken:(TBToken *)token inBundles:(NSMutableArray<NSString*> *)bundlePaths;
/// @return Actual methods
- (NSMutableArray<FLEXMethod*> *)methodsForToken:(TBToken *)token
                                      instance:(NSNumber *)onlyInstanceMethods
                                     inClasses:(NSMutableArray<NSString*> *)classes;

@end
