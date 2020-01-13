//
//  TBRuntime.m
//  TBTweakViewController
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBRuntime.h"
#import "NSObject+Reflection.h"
#import "FLEXMethod.h"
#import "NSArray+Functional.h"
//#import "MKRuntimeSafety.h"


#define TBEquals(a, b) ([a compare:b options:NSCaseInsensitiveSearch] == NSOrderedSame)
#define TBContains(a, b) ([a rangeOfString:b options:NSCaseInsensitiveSearch].location != NSNotFound)
#define TBHasPrefix(a, b) ([a rangeOfString:b options:NSCaseInsensitiveSearch].location == 0)
#define TBHasSuffix(a, b) ([a rangeOfString:b options:NSCaseInsensitiveSearch].location == (a.length - b.length))


@interface TBRuntime () {
    NSMutableArray<NSString*> *_imageDisplayNames;
}

@property (nonatomic) NSMutableDictionary *bundles_pathToShort;
@property (nonatomic) NSCache *bundles_pathToClassNames;
@property (nonatomic) NSMutableArray<NSString*> *imagePaths;

@end

/// @return success if the map passes.
static inline NSString * TBWildcardMap_(NSString *token, NSString *candidate, NSString *success, TBWildcardOptions options) {
    switch (options) {
        case TBWildcardOptionsNone:
            // Only "if equals"
            if (TBEquals(candidate, token)) {
                return success;
            }
        default: {
            // Only "if contains"
            if (options & TBWildcardOptionsPrefix &&
                options & TBWildcardOptionsSuffix) {
                if (TBContains(candidate, token)) {
                    return success;
                }
            }
            // Only "if candidate ends with with token"
            else if (options & TBWildcardOptionsPrefix) {
                if (TBHasSuffix(candidate, token)) {
                    return success;
                }
            }
            // Only "if candidate starts with with token"
            else if (options & TBWildcardOptionsSuffix) {
                // Case like "Bundle." where we want "" to match anything
                if (!token.length) {
                    return success;
                }
                if (TBHasPrefix(candidate, token)) {
                    return success;
                }
            }
        }
    }

    return nil;
}

/// @return candidate if the map passes.
static inline NSString * TBWildcardMap(NSString *token, NSString *candidate, TBWildcardOptions options) {
    return TBWildcardMap_(token, candidate, candidate, options);
}

@implementation TBRuntime

#pragma mark - Initialization

+ (instancetype)runtime {
    static TBRuntime *runtime;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runtime = [self new];
        [runtime reloadLibrariesList];
    });

    return runtime;
}

- (id)init {
    self = [super init];
    if (self) {
        _imagePaths = [NSMutableArray array];
        _bundles_pathToShort = [NSMutableDictionary dictionary];
        _bundles_pathToClassNames = [NSCache new];
    }

    return self;
}

#pragma mark - Private

- (void)reloadLibrariesList {
    unsigned int imageCount = 0;
    const char **imageNames = objc_copyImageNames(&imageCount);

    if (imageNames) {
        NSMutableArray *imageNameStrings = [NSMutableArray flex_forEachUpTo:imageCount map:^NSString *(NSUInteger i) {
            return @(imageNames[i]);
        }];

        self.imagePaths = imageNameStrings;
        free(imageNames);

        // Sort alphabetically
        [imageNameStrings sortUsingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
            NSString *shortName1 = [self shortNameForImageName:name1];
            NSString *shortName2 = [self shortNameForImageName:name2];
            return [shortName1 caseInsensitiveCompare:shortName2];
        }];

        // Cache image display names
        _imageDisplayNames = [imageNameStrings flex_mapped:^id(NSString *path, NSUInteger idx) {
            return [self shortNameForImageName:path];
        }];
    }
}

- (NSString *)shortNameForImageName:(NSString *)imageName {
    // Cache
    NSString *shortName = _bundles_pathToShort[imageName];
    if (shortName) {
        return shortName;
    }

    NSArray *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        NSString *parentDir = components[components.count - 2];
        if ([parentDir hasSuffix:@".framework"] || [parentDir hasSuffix:@".axbundle"]) {
            shortName = parentDir;
        }
    }

    if (!shortName) {
        shortName = imageName.lastPathComponent;
    }

    _bundles_pathToShort[imageName] = shortName;
    return shortName;
}

- (NSMutableArray<NSString*> *)classNamesInImageAtPath:(NSString *)path {
    // Check cache
    NSMutableArray *classNameStrings = [_bundles_pathToClassNames objectForKey:path];
    if (classNameStrings) {
        return classNameStrings.mutableCopy;
    }

    unsigned int classCount = 0;
    const char **classNames = objc_copyClassNamesForImage(path.UTF8String, &classCount);

    if (classNames) {
        classNameStrings = [NSMutableArray flex_forEachUpTo:classCount map:^id(NSUInteger i) {
            return @(classNames[i]);
        }];

        free(classNames);

        [classNameStrings sortUsingSelector:@selector(caseInsensitiveCompare:)];
        [_bundles_pathToClassNames setObject:classNameStrings forKey:path];

        return classNameStrings.mutableCopy;
    }

    return [NSMutableArray array];
}

#pragma mark - Public

- (NSMutableArray<NSString*> *)bundleNamesForToken:(TBToken *)token {
    if (self.imagePaths.count) {
        TBWildcardOptions options = token.options;
        NSString *query = token.string;

        // Optimization, avoid a loop
        if (options == TBWildcardOptionsAny) {
            return _imageDisplayNames;
        }

        // No dot syntax because imageDisplayNames is only mutable internally
        return [_imageDisplayNames flex_mapped:^id(NSString *binary, NSUInteger idx) {
            NSString *UIName = [self shortNameForImageName:binary];
            return TBWildcardMap(query, UIName, options);
        }];
    }

    return [NSMutableArray array];
}

- (NSMutableArray<NSString*> *)bundlePathsForToken:(TBToken *)token {
    if (self.imagePaths.count) {
        TBWildcardOptions options = token.options;
        NSString *query = token.string;

        // Optimization, avoid a loop
        if (options == TBWildcardOptionsAny) {
            return self.imagePaths;
        }

        return [self.imagePaths flex_mapped:^id(NSString *binary, NSUInteger idx) {
            NSString *UIName = [self shortNameForImageName:binary];
            // If query == UIName, -> binary
            return TBWildcardMap_(query, UIName, binary, options);
        }];
    }

    return [NSMutableArray array];
}

- (NSMutableArray<NSString*> *)classesForToken:(TBToken *)token inBundles:(NSMutableArray<NSString*> *)bundles {
    // Edge case where token is the class we want already
    if (token.isAbsolute) {
        if (MKClassIsSafe(NSClassFromString(token.string))) {
            return [NSMutableArray arrayWithObject:token.string];
        }

        return [NSMutableArray array];
    }

    if (bundles.count) {
        // Get class names, remove unsafe classes
        NSMutableArray<NSString*> *names = [self _classesForToken:token inBundles:bundles];
        return [names flex_mapped:^NSString *(NSString *cls, NSUInteger idx) {
            NSSet *ignored = MKKnownUnsafeClassNames();
            BOOL safe = ![ignored containsObject:cls];
            return safe ? cls : nil;
        }];
    }

    return [NSMutableArray array];
}

- (NSMutableArray<NSString*> *)_classesForToken:(TBToken *)token inBundles:(NSMutableArray<NSString*> *)bundles {
    TBWildcardOptions options = token.options;
    NSString *query = token.string;

    // Optimization, avoid unnecessary sorting
    if (bundles.count == 1) {
        // Optimization, avoid a loop
        if (options == TBWildcardOptionsAny) {
            return [self classNamesInImageAtPath:bundles.firstObject];
        }

        return [[self classNamesInImageAtPath:bundles.firstObject] flex_mapped:^id(NSString *className, NSUInteger idx) {
            return TBWildcardMap(query, className, options);
        }];
    }
    else {
        // Optimization, avoid a loop
        if (options == TBWildcardOptionsAny) {
            return [[bundles flex_mapped:^NSArray *(NSString *bundlePath, NSUInteger idx) {
                return [self classNamesInImageAtPath:bundlePath];
            }] sortedUsingSelector:@selector(caseInsensitiveCompare:)];
        }

        return [[bundles flex_mapped:^NSArray *(NSString *bundlePath, NSUInteger idx) {
            return [[self classNamesInImageAtPath:bundlePath] flex_mapped:^id(NSString *className, NSUInteger idx) {
                return TBWildcardMap(query, className, options);
            }];
        }] sortedUsingSelector:@selector(caseInsensitiveCompare:)];
    }
}

- (NSMutableArray<FLEXMethod*> *)methodsForToken:(TBToken *)token
                                      instance:(NSNumber *)checkInstance
                                     inClasses:(NSMutableArray *)classes {
    if (classes.count) {
        TBWildcardOptions options = token.options;
        BOOL instance = checkInstance.boolValue;
        NSString *selector = token.string;

        switch (options) {
            /// In practice, I don't think this case is ever used with methods
            case TBWildcardOptionsNone: {
                SEL sel = (SEL)selector.UTF8String;
                return [classes flex_mapped:^id(NSString *name, NSUInteger idx) {
                    Class cls = NSClassFromString(name);

                    // Method is absolute
                    return [MKLazyMethod methodForSelector:sel class:cls instance:instance];
                }];
            }
            case TBWildcardOptionsAny: {
                return [classes flex_mapped:^NSArray *(NSString *name, NSUInteger idx) {
                    // Any means `instance` was not specified
                    Class cls = NSClassFromString(name);
                    return [cls flex_allMethods];
                }];
            }
            default: {
                // Only "if contains"
                if (options & TBWildcardOptionsPrefix &&
                    options & TBWildcardOptionsSuffix) {
                    return [classes flex_mapped:^NSArray *(NSString *name, NSUInteger idx) {
                        Class cls = NSClassFromString(name);
                        return [[cls flex_allMethods] flex_mapped:^id(FLEXMethod *method, NSUInteger idx) {

                            // Method is a prefix-suffix wildcard
                            if (TBContains(method.selectorString, selector)) {
                                return method;
                            }
                            return nil;
                        }];
                    }];
                }
                // Only "if method ends with with selector"
                else if (options & TBWildcardOptionsPrefix) {
                    return [classes flex_mapped:^NSArray *(NSString *name, NSUInteger idx) {
                        Class cls = NSClassFromString(name);

                        return [[cls flex_allMethods] flex_mapped:^id(FLEXMethod *method, NSUInteger idx) {
                            // Method is a prefix wildcard
                            if (TBHasSuffix(method.selectorString, selector)) {
                                return method;
                            }
                            return nil;
                        }];
                    }];
                }
                // Only "if method starts with with selector"
                else if (options & TBWildcardOptionsSuffix) {
                    assert(checkInstance);

                    return [classes flex_mapped:^NSArray *(NSString *name, NSUInteger idx) {
                        Class cls = NSClassFromString(name);

                        // Case like "Bundle.class.-" where we want "-" to match anything
                        if (!selector.length) {
                            if (instance) {
                                return [cls flex_allInstanceMethods];
                            } else {
                                return [cls flex_allClassMethods];
                            }
                        }

                        id mapping = ^id(FLEXMethod *method) {
                            // Method is a suffix wildcard
                            if (TBHasPrefix(method.selectorString, selector)) {
                                return method;
                            }
                            return nil;
                        };

                        if (instance) {
                            return [[cls flex_allInstanceMethods] flex_mapped:mapping];
                        } else {
                            return [[cls flex_allClassMethods] flex_mapped:mapping];
                        }
                    }];
                }
            }
        }
    }
    
    return [NSMutableArray array];
}

@end
