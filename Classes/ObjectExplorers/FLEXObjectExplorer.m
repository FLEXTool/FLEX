//
//  FLEXObjectExplorer.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXObjectExplorer.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "NSObject+FLEX_Reflection.h"
#import "FLEXRuntime+Compare.h"
#import "FLEXRuntime+UIKitHelpers.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXMetadataSection.h"
#import "NSUserDefaults+FLEX.h"
#import "FLEXMirror.h"
#import "FLEXSwiftInternal.h"

@implementation FLEXObjectExplorerDefaults

+ (instancetype)canEdit:(BOOL)editable wantsPreviews:(BOOL)showPreviews {
    FLEXObjectExplorerDefaults *defaults = [self new];
    defaults->_isEditable = editable;
    defaults->_wantsDynamicPreviews = showPreviews;
    return defaults;
}

@end

@interface FLEXObjectExplorer () {
    NSMutableArray<NSArray<FLEXProperty *> *> *_allProperties;
    NSMutableArray<NSArray<FLEXProperty *> *> *_allClassProperties;
    NSMutableArray<NSArray<FLEXIvar *> *> *_allIvars;
    NSMutableArray<NSArray<FLEXMethod *> *> *_allMethods;
    NSMutableArray<NSArray<FLEXMethod *> *> *_allClassMethods;
    NSMutableArray<NSArray<FLEXProtocol *> *> *_allConformedProtocols;
    NSMutableArray<FLEXStaticMetadata *> *_allInstanceSizes;
    NSMutableArray<FLEXStaticMetadata *> *_allImageNames;
    NSString *_objectDescription;
}

@property (nonatomic, readonly) id<FLEXMirror> initialMirror;
@end

@implementation FLEXObjectExplorer

+ (void)initialize {
    if (self == FLEXObjectExplorer.class) {
        FLEXObjectExplorer.reflexAvailable = NSClassFromString(@"FLEXSwiftMirror") != nil;
    }
}

#pragma mark - Initialization

+ (id)forObject:(id)objectOrClass {
    return [[self alloc] initWithObject:objectOrClass];
}

- (id)initWithObject:(id)objectOrClass {
    NSParameterAssert(objectOrClass);
    
    self = [super init];
    if (self) {
        _object = objectOrClass;
        _objectIsInstance = !object_isClass(objectOrClass);
        
        [self reloadMetadata];
    }

    return self;
}

- (id<FLEXMirror>)mirrorForClass:(Class)cls {
    static Class FLEXSwiftMirror = nil;
    
    // Should we use Reflex?
    if (FLEXIsSwiftObjectOrClass(cls) && FLEXObjectExplorer.reflexAvailable) {
        // Initialize FLEXSwiftMirror class if needed
        if (!FLEXSwiftMirror) {
            FLEXSwiftMirror = NSClassFromString(@"FLEXSwiftMirror");            
        }
        
        return [(id<FLEXMirror>)[FLEXSwiftMirror alloc] initWithSubject:cls];
    }
    
    // No; not swift object, or Reflex unavailable
    return [FLEXMirror reflect:cls];
}


#pragma mark - Public

+ (void)configureDefaultsForItems:(NSArray<id<FLEXObjectExplorerItem>> *)items {
    BOOL hidePreviews = NSUserDefaults.standardUserDefaults.flex_explorerHidesVariablePreviews;
    FLEXObjectExplorerDefaults *mutable = [FLEXObjectExplorerDefaults
        canEdit:YES wantsPreviews:!hidePreviews
    ];
    FLEXObjectExplorerDefaults *immutable = [FLEXObjectExplorerDefaults
        canEdit:NO wantsPreviews:!hidePreviews
    ];

    // .tag is used to cache whether the value of .isEditable;
    // This could change at runtime so it is important that
    // it is cached every time shortcuts are requeted and not
    // just once at as shortcuts are initially registered
    for (id<FLEXObjectExplorerItem> metadata in items) {
        metadata.defaults = metadata.isEditable ? mutable : immutable;
    }
}

- (NSString *)objectDescription {
    if (!_objectDescription) {
        // Hard-code UIColor description
        if ([FLEXRuntimeUtility safeObject:self.object isKindOfClass:[UIColor class]]) {
            CGFloat h, s, l, r, g, b, a;
            [self.object getRed:&r green:&g blue:&b alpha:&a];
            [self.object getHue:&h saturation:&s brightness:&l alpha:nil];

            return [NSString stringWithFormat:
                @"HSL: (%.3f, %.3f, %.3f)\nRGB: (%.3f, %.3f, %.3f)\nAlpha: %.3f",
                h, s, l, r, g, b, a
            ];
        }

        NSString *description = [FLEXRuntimeUtility safeDescriptionForObject:self.object];

        if (!description.length) {
            NSString *address = [FLEXUtility addressOfObject:self.object];
            return [NSString stringWithFormat:@"Object at %@ returned empty description", address];
        }
        
        if (description.length > 10000) {
            description = [description substringToIndex:10000];
        }

        _objectDescription = description;
    }

    return _objectDescription;
}

- (void)setClassScope:(NSInteger)classScope {
    _classScope = classScope;
    
    [self reloadScopedMetadata];
}

- (void)reloadMetadata {
    _allProperties = [NSMutableArray new];
    _allClassProperties = [NSMutableArray new];
    _allIvars = [NSMutableArray new];
    _allMethods = [NSMutableArray new];
    _allClassMethods = [NSMutableArray new];
    _allConformedProtocols = [NSMutableArray new];
    _allInstanceSizes = [NSMutableArray new];
    _allImageNames = [NSMutableArray new];
    _objectDescription = nil;

    [self reloadClassHierarchy];
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL hideBackingIvars = defaults.flex_explorerHidesPropertyIvars;
    BOOL hidePropertyMethods = defaults.flex_explorerHidesPropertyMethods;
    BOOL hidePrivateMethods = defaults.flex_explorerHidesPrivateMethods;
    BOOL showMethodOverrides = defaults.flex_explorerShowsMethodOverrides;
    
    NSMutableArray<NSArray<FLEXProperty *> *> *allProperties = [NSMutableArray new];
    NSMutableArray<NSArray<FLEXProperty *> *> *allClassProps = [NSMutableArray new];
    NSMutableArray<NSArray<FLEXMethod *> *> *allMethods = [NSMutableArray new];
    NSMutableArray<NSArray<FLEXMethod *> *> *allClassMethods = [NSMutableArray new];

    // Loop over each class and each superclass, collect
    // the fresh and unique metadata in each category
    Class superclass = nil;
    NSInteger count = self.classHierarchyClasses.count;
    NSInteger rootIdx = count - 1;
    for (NSInteger i = 0; i < count; i++) {
        Class cls = self.classHierarchyClasses[i];
        id<FLEXMirror> mirror = [self mirrorForClass:cls];
        superclass = (i < rootIdx) ? self.classHierarchyClasses[i+1] : nil;

        [allProperties addObject:[self
            metadataUniquedByName:mirror.properties
            superclass:superclass
            kind:FLEXMetadataKindProperties
            skip:showMethodOverrides
        ]];
        [allClassProps addObject:[self
            metadataUniquedByName:mirror.classProperties
            superclass:superclass
            kind:FLEXMetadataKindClassProperties
            skip:showMethodOverrides
        ]];
        [_allIvars addObject:[self
            metadataUniquedByName:mirror.ivars
            superclass:nil
            kind:FLEXMetadataKindIvars
            skip:NO
        ]];
        [allMethods addObject:[self
            metadataUniquedByName:mirror.methods
            superclass:superclass
            kind:FLEXMetadataKindMethods
            skip:showMethodOverrides
        ]];
        [allClassMethods addObject:[self
            metadataUniquedByName:mirror.classMethods
            superclass:superclass
            kind:FLEXMetadataKindClassMethods
            skip:showMethodOverrides
        ]];
        [_allConformedProtocols addObject:[self
            metadataUniquedByName:mirror.protocols
            superclass:superclass
            kind:FLEXMetadataKindProtocols
            skip:NO
        ]];
        
        // TODO: join instance size, image name, and class hierarchy into a single model object
        // This would greatly reduce the laziness that has begun to manifest itself here
        [_allInstanceSizes addObject:[FLEXStaticMetadata
            style:FLEXStaticMetadataRowStyleKeyValue
            title:@"Instance Size" number:@(class_getInstanceSize(cls))
        ]];
        [_allImageNames addObject:[FLEXStaticMetadata
            style:FLEXStaticMetadataRowStyleDefault
            title:@"Image Name" string:@(class_getImageName(cls) ?: "Created at Runtime")
        ]];
    }
    
    _classHierarchy = [FLEXStaticMetadata classHierarchy:self.classHierarchyClasses];
    
    NSArray<NSArray<FLEXProperty *> *> *properties = allProperties;
    
    // Potentially filter property-backing ivars
    if (hideBackingIvars) {
        NSArray<NSArray<FLEXIvar *> *> *ivars = _allIvars.copy;
        _allIvars = [ivars flex_mapped:^id(NSArray<FLEXIvar *> *list, NSUInteger idx) {
            // Get a set of all backing ivar names for the current class in the hierarchy
            NSSet *ivarNames = [NSSet setWithArray:({
                [properties[idx] flex_mapped:^id(FLEXProperty *p, NSUInteger idx) {
                    // Nil if no ivar, and array is flatted
                    return p.likelyIvarName;
                }];
            })];
            
            // Remove ivars whose name is in the ivar names list
            return [list flex_filtered:^BOOL(FLEXIvar *ivar, NSUInteger idx) {
                return ![ivarNames containsObject:ivar.name];
            }];
        }];
    }
    
    // Potentially filter property-backing methods
    if (hidePropertyMethods) {
        allMethods = [allMethods flex_mapped:^id(NSArray<FLEXMethod *> *list, NSUInteger idx) {
            // Get a set of all property method names for the current class in the hierarchy
            NSSet *methodNames = [NSSet setWithArray:({
                [properties[idx] flex_flatmapped:^NSArray *(FLEXProperty *p, NSUInteger idx) {
                    if (p.likelyGetterExists) {
                        if (p.likelySetterExists) {
                            return @[p.likelyGetterString, p.likelySetterString];
                        }
                        
                        return @[p.likelyGetterString];
                    } else if (p.likelySetterExists) {
                        return @[p.likelySetterString];
                    }
                    
                    return nil;
                }];
            })];
            
            // Remove methods whose name is in the property method names list
            return [list flex_filtered:^BOOL(FLEXMethod *method, NSUInteger idx) {
                return ![methodNames containsObject:method.selectorString];
            }];
        }];
    }
    
    if (hidePrivateMethods) {
        id methodMapBlock = ^id(NSArray<FLEXMethod *> *list, NSUInteger idx) {
            // Remove methods which contain an underscore
            return [list flex_filtered:^BOOL(FLEXMethod *method, NSUInteger idx) {
                return ![method.selectorString containsString:@"_"];
            }];
        };
        id propertyMapBlock = ^id(NSArray<FLEXProperty *> *list, NSUInteger idx) {
            // Remove methods which contain an underscore
            return [list flex_filtered:^BOOL(FLEXProperty *prop, NSUInteger idx) {
                return ![prop.name containsString:@"_"];
            }];
        };
        
        allMethods = [allMethods flex_mapped:methodMapBlock];
        allClassMethods = [allClassMethods flex_mapped:methodMapBlock];
        allProperties = [allProperties flex_mapped:propertyMapBlock];
        allClassProps = [allClassProps flex_mapped:propertyMapBlock];
    }
    
    _allProperties = allProperties;
    _allClassProperties = allClassProps;
    _allMethods = allMethods;
    _allClassMethods = allClassMethods;

    // Set up UIKit helper data
    // Really, we only need to call this on properties and ivars
    // because no other metadata types support editing.
    NSArray<NSArray *>*metadatas = @[
        _allProperties, _allClassProperties, _allIvars,
       /* _allMethods, _allClassMethods, _allConformedProtocols */
    ];
    for (NSArray *matrix in metadatas) {
        for (NSArray *metadataByClass in matrix) {
            [FLEXObjectExplorer configureDefaultsForItems:metadataByClass];
        }
    }
    
    [self reloadScopedMetadata];
}


#pragma mark - Private

- (void)reloadScopedMetadata {
    _properties = self.allProperties[self.classScope];
    _classProperties = self.allClassProperties[self.classScope];
    _ivars = self.allIvars[self.classScope];
    _methods = self.allMethods[self.classScope];
    _classMethods = self.allClassMethods[self.classScope];
    _conformedProtocols = self.allConformedProtocols[self.classScope];
    _instanceSize = self.allInstanceSizes[self.classScope];
    _imageName = self.allImageNames[self.classScope];
}

/// Accepts an array of flex metadata objects and discards objects
/// with duplicate names, as well as properties and methods which
/// aren't "new" (i.e. those which the superclass responds to)
- (NSArray *)metadataUniquedByName:(NSArray *)list
                        superclass:(Class)superclass
                              kind:(FLEXMetadataKind)kind
                              skip:(BOOL)skipUniquing {
    if (skipUniquing) {
        return list;
    }
    
    // Remove items with same name and return filtered list
    NSMutableSet *names = [NSMutableSet new];
    return [list flex_filtered:^BOOL(id obj, NSUInteger idx) {
        NSString *name = [obj name];
        if ([names containsObject:name]) {
            return NO;
        } else {
            if (!name) {
                return NO;
            }
            
            [names addObject:name];

            // Skip methods and properties which are just overrides,
            // potentially skip ivars and methods associated with properties
            switch (kind) {
                case FLEXMetadataKindProperties:
                    if ([superclass instancesRespondToSelector:[obj likelyGetter]]) {
                        return NO;
                    }
                    break;
                case FLEXMetadataKindClassProperties:
                    if ([superclass respondsToSelector:[obj likelyGetter]]) {
                        return NO;
                    }
                    break;
                case FLEXMetadataKindMethods:
                    if ([superclass instancesRespondToSelector:NSSelectorFromString(name)]) {
                        return NO;
                    }
                    break;
                case FLEXMetadataKindClassMethods:
                    if ([superclass respondsToSelector:NSSelectorFromString(name)]) {
                        return NO;
                    }
                    break;

                case FLEXMetadataKindProtocols:
                case FLEXMetadataKindClassHierarchy:
                case FLEXMetadataKindOther:
                    return YES; // These types are already uniqued
                    break;
                    
                // Ivars cannot be overidden
                case FLEXMetadataKindIvars: break;
            }

            return YES;
        }
    }];
}


#pragma mark - Superclasses

- (void)reloadClassHierarchy {
    // The class hierarchy will never contain metaclass objects by this logic;
    // it is always the same for a given class and instances of it
    _classHierarchyClasses = [[self.object class] flex_classHierarchy];
}

@end


#pragma mark - Reflex
@implementation FLEXObjectExplorer (Reflex)
static BOOL _reflexAvailable = NO;

+ (BOOL)reflexAvailable { return _reflexAvailable; }
+ (void)setReflexAvailable:(BOOL)enable { _reflexAvailable = enable; }

@end
