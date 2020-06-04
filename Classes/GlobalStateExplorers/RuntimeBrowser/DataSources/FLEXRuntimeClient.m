//
//  FLEXRuntimeClient.m
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXRuntimeClient.h"
#import "NSObject+FLEX_Reflection.h"
#import "FLEXMethod.h"
#import "NSArray+FLEX.h"
#import "FLEXRuntimeSafety.h"
#include <dlfcn.h>

#define Equals(a, b)    ([a compare:b options:NSCaseInsensitiveSearch] == NSOrderedSame)
#define Contains(a, b)  ([a rangeOfString:b options:NSCaseInsensitiveSearch].location != NSNotFound)
#define HasPrefix(a, b) ([a rangeOfString:b options:NSCaseInsensitiveSearch].location == 0)
#define HasSuffix(a, b) ([a rangeOfString:b options:NSCaseInsensitiveSearch].location == (a.length - b.length))


@interface FLEXRuntimeClient () {
    NSMutableArray<NSString *> *_imageDisplayNames;
}

@property (nonatomic) NSMutableDictionary *bundles_pathToShort;
@property (nonatomic) NSMutableDictionary *bundles_shortToPath;
@property (nonatomic) NSCache *bundles_pathToClassNames;
@property (nonatomic) NSMutableArray<NSString *> *imagePaths;

@end

/// @return success if the map passes.
static inline NSString * TBWildcardMap_(NSString *token, NSString *candidate, NSString *success, TBWildcardOptions options) {
    switch (options) {
        case TBWildcardOptionsNone:
            // Only "if equals"
            if (Equals(candidate, token)) {
                return success;
            }
        default: {
            // Only "if contains"
            if (options & TBWildcardOptionsPrefix &&
                options & TBWildcardOptionsSuffix) {
                if (Contains(candidate, token)) {
                    return success;
                }
            }
            // Only "if candidate ends with with token"
            else if (options & TBWildcardOptionsPrefix) {
                if (HasSuffix(candidate, token)) {
                    return success;
                }
            }
            // Only "if candidate starts with with token"
            else if (options & TBWildcardOptionsSuffix) {
                // Case like "Bundle." where we want "" to match anything
                if (!token.length) {
                    return success;
                }
                if (HasPrefix(candidate, token)) {
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

@implementation FLEXRuntimeClient

#pragma mark - Initialization

+ (instancetype)runtime {
    static FLEXRuntimeClient *runtime;
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
        _imagePaths = [NSMutableArray new];
        _bundles_pathToShort = [NSMutableDictionary new];
        _bundles_shortToPath = [NSMutableDictionary new];
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
            if ([imageName hasSuffix:@".dylib"]) {
                shortName = imageName.lastPathComponent;
            } else {
                shortName = parentDir;
            }
        }
    }

    if (!shortName) {
        shortName = imageName.lastPathComponent;
    }

    _bundles_pathToShort[imageName] = shortName;
    _bundles_shortToPath[shortName] = imageName;
    return shortName;
}

- (NSString *)imageNameForShortName:(NSString *)imageName {
    return _bundles_shortToPath[imageName];
}

- (NSMutableArray<NSString *> *)classNamesInImageAtPath:(NSString *)path {
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

    return [NSMutableArray new];
}

#pragma mark - Public

+ (void)initializeWebKitLegacy {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *handle = dlopen(
            "/System/Library/PrivateFrameworks/WebKitLegacy.framework/WebKitLegacy",
            RTLD_LAZY
        );
        void (*WebKitInitialize)() = dlsym(handle, "WebKitInitialize");
        if (WebKitInitialize) {
            NSAssert(NSThread.isMainThread,
                @"WebKitInitialize can only be called on the main thread"
            );
            WebKitInitialize();
        }
    });
}

- (NSArray<Class> *)copySafeClassList {
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    return [NSArray flex_forEachUpTo:count map:^id(NSUInteger i) {
        Class cls = classes[i];
        return FLEXClassIsSafe(cls) ? cls : nil;
    }];
}

- (NSArray<Protocol *> *)copyProtocolList {
    unsigned int count = 0;
    Protocol *__unsafe_unretained *protocols = objc_copyProtocolList(&count);
    return [NSArray arrayWithObjects:protocols count:count];
}

- (NSMutableArray<NSString *> *)bundleNamesForToken:(FLEXSearchToken *)token {
    if (self.imagePaths.count) {
        TBWildcardOptions options = token.options;
        NSString *query = token.string;

        // Optimization, avoid a loop
        if (options == TBWildcardOptionsAny) {
            return _imageDisplayNames;
        }

        // No dot syntax because imageDisplayNames is only mutable internally
        return [_imageDisplayNames flex_mapped:^id(NSString *binary, NSUInteger idx) {
//            NSString *UIName = [self shortNameForImageName:binary];
            return TBWildcardMap(query, binary, options);
        }];
    }

    return [NSMutableArray new];
}

- (NSMutableArray<NSString *> *)bundlePathsForToken:(FLEXSearchToken *)token {
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

    return [NSMutableArray new];
}

- (NSMutableArray<NSString *> *)classesForToken:(FLEXSearchToken *)token inBundles:(NSMutableArray<NSString *> *)bundles {
    // Edge case where token is the class we want already; return superclasses
    if (token.isAbsolute) {
        if (FLEXClassIsSafe(NSClassFromString(token.string))) {
            return [NSMutableArray arrayWithObject:token.string];
        }

        return [NSMutableArray new];
    }

    if (bundles.count) {
        // Get class names, remove unsafe classes
        NSMutableArray<NSString *> *names = [self _classesForToken:token inBundles:bundles];
        return [names flex_mapped:^NSString *(NSString *name, NSUInteger idx) {
            Class cls = NSClassFromString(name);
            BOOL safe = FLEXClassIsSafe(cls);
            return safe ? name : nil;
        }];
    }

    return [NSMutableArray new];
}

- (NSMutableArray<NSString *> *)_classesForToken:(FLEXSearchToken *)token inBundles:(NSMutableArray<NSString *> *)bundles {
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
            return [[bundles flex_flatmapped:^NSArray *(NSString *bundlePath, NSUInteger idx) {
                return [self classNamesInImageAtPath:bundlePath];
            }] sortedUsingSelector:@selector(caseInsensitiveCompare:)];
        }

        return [[bundles flex_flatmapped:^NSArray *(NSString *bundlePath, NSUInteger idx) {
            return [[self classNamesInImageAtPath:bundlePath] flex_mapped:^id(NSString *className, NSUInteger idx) {
                return TBWildcardMap(query, className, options);
            }];
        }] sortedUsingSelector:@selector(caseInsensitiveCompare:)];
    }
}

- (NSArray<NSMutableArray<FLEXMethod *> *> *)methodsForToken:(FLEXSearchToken *)token
                                                    instance:(NSNumber *)checkInstance
                                                   inClasses:(NSArray<NSString *> *)classes {
    if (classes.count) {
        TBWildcardOptions options = token.options;
        BOOL instance = checkInstance.boolValue;
        NSString *selector = token.string;

        switch (options) {
            // In practice I don't think this case is ever used with methods,
            // since they will always have a suffix wildcard at the end
            case TBWildcardOptionsNone: {
                SEL sel = (SEL)selector.UTF8String;
                return @[[classes flex_mapped:^id(NSString *name, NSUInteger idx) {
                    Class cls = NSClassFromString(name);
                    // Use metaclass if not instance
                    if (!instance) {
                        cls = object_getClass(cls);
                    }
                    
                    // Method is absolute
                    return [FLEXMethod selector:sel class:cls];
                }]];
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
                            if (Contains(method.selectorString, selector)) {
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
                            if (HasSuffix(method.selectorString, selector)) {
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
                            if (HasPrefix(method.selectorString, selector)) {
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
    
    return [NSMutableArray new];
}

@end
