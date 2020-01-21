//
//  FLEXObjectExplorer.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorer.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "NSObject+Reflection.h"
#import "FLEXRuntime+Compare.h"
#import "FLEXRuntime+UIKitHelpers.h"
#import "FLEXPropertyAttributes.h"
#import "NSObject+Reflection.h"
#import "FLEXMetadataSection.h"

@interface FLEXObjectExplorer () {
    NSMutableArray<NSArray<FLEXProperty *> *> *_allProperties;
    NSMutableArray<NSArray<FLEXProperty *> *> *_allClassProperties;
    NSMutableArray<NSArray<FLEXIvar *> *> *_allIvars;
    NSMutableArray<NSArray<FLEXMethod *> *> *_allMethods;
    NSMutableArray<NSArray<FLEXMethod *> *> *_allClassMethods;
    NSMutableArray<NSArray<FLEXProtocol *> *> *_allConformedProtocols;
    NSMutableArray<NSNumber *> *_allInstanceSizes;
    NSMutableArray<NSString *> *_allImageNames;
}
@end

@implementation FLEXObjectExplorer

#pragma mark - Initialization

+ (id)forObject:(id)objectOrClass
{
    return [[self alloc] initWithObject:objectOrClass];
}

- (id)initWithObject:(id)objectOrClass
{
    NSParameterAssert(objectOrClass);
    
    self = [super init];
    if (self) {
        _object = objectOrClass;
        _objectIsInstance = !object_isClass(objectOrClass);
        
        [self reloadMetadata];
    }

    return self;
}


#pragma mark - Public

- (NSString *)objectDescription {
    // Hard-code UIColor description
    if ([self.object isKindOfClass:[UIColor class]]) {
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

    return description;
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

    [self reloadClassHierarchy];

    // Loop over each class and each superclass, collect
    // the fresh and unique metadata in each category
    Class superclass = nil;
    NSInteger count = self.classHierarchy.count;
    NSInteger rootIdx = count - 1;
    for (NSInteger i = 0; i < count; i++) {
        Class cls = self.classHierarchy[i];
        superclass = (i < rootIdx) ? self.classHierarchy[i+1] : nil;

        [_allProperties addObject:[self
            metadataUniquedByName:[cls flex_allInstanceProperties]
            superclass:superclass
            kind:FLEXMetadataKindProperties
        ]];
        [_allClassProperties addObject:[self
            metadataUniquedByName:[cls flex_allClassProperties]
            superclass:superclass
            kind:FLEXMetadataKindClassProperties
        ]];
        [_allIvars addObject:[self
            metadataUniquedByName:[cls flex_allIvars]
            superclass:nil
            kind:FLEXMetadataKindIvars
        ]];
        [_allMethods addObject:[self
            metadataUniquedByName:[cls flex_allInstanceMethods]
            superclass:superclass
            kind:FLEXMetadataKindMethods
        ]];
        [_allClassMethods addObject:[self
            metadataUniquedByName:[cls flex_allClassMethods]
            superclass:superclass
            kind:FLEXMetadataKindClassMethods
        ]];
        [_allConformedProtocols addObject:[self
            metadataUniquedByName:[cls flex_protocols]
            superclass:superclass
            kind:FLEXMetadataKindProtocols
        ]];
        [_allInstanceSizes addObject:@(class_getInstanceSize(cls))];
        [_allImageNames addObject:@(class_getImageName(cls))];
    }

    // Set up UIKit helper data
    // Really, we only need to call this on properties and ivars
    // because no other metadata types support editing.
    for (NSArray *matrix in @[_allProperties, _allIvars, /* _allMethods, _allClassMethods, _allConformedProtocols */]) {
        for (NSArray *metadataByClass in matrix) {
            for (id<FLEXRuntimeMetadata> metadata in metadataByClass) {
                metadata.tag = metadata.isEditable ? @YES : nil;
            }
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
    _instanceSize = self.allInstanceSizes[self.classScope].unsignedIntegerValue;
    _imageName = self.allImageNames[self.classScope];
}

/// Accepts an array of flex metadata objects and discards objects
/// with duplicate names, as well as properties and methods which
/// aren't "new" (i.e. those which the superclass responds to)
- (NSArray *)metadataUniquedByName:(NSArray *)list superclass:(Class)superclass kind:(FLEXMetadataKind)kind {
    // Remove items with same name and return filtered list
    NSMutableSet *names = [NSMutableSet new];
    return [list flex_filtered:^BOOL(id obj, NSUInteger idx) {
        NSString *name = [obj name];
        if ([names containsObject:name]) {
            return NO;
        } else {
            [names addObject:name];

            // Skip methods and properties which are just overrides
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
                    return YES; // Protocols are already uniqued
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
    _classHierarchy = [[self.object class] flex_classHierarchy];
}

@end
