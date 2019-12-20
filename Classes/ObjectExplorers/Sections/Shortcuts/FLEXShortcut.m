//
//  FLEXShortcut.m
//  FLEX
//
//  Created by Tanner Bennett on 12/10/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXShortcut.h"
#import "FLEXProperty.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"
#import "FLEXRuntime+UIKitHelpers.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXMetadataSection.h"

@interface FLEXShortcut () {
    id _item;
}

@property (nonatomic, readonly) FLEXMetadataKind metadataKind;
@property (nonatomic, readonly) FLEXProperty *property;
@property (nonatomic, readonly) FLEXMethod *method;
@property (nonatomic, readonly) FLEXIvar *ivar;
@property (nonatomic, readonly) id<FLEXRuntimeMetadata> metadata;
@end

@implementation FLEXShortcut

+ (id<FLEXShortcut>)shortcutFor:(id)item {
    if ([item conformsToProtocol:@protocol(FLEXShortcut)]) {
        return item;
    }
    
    FLEXShortcut *shortcut = [self new];
    shortcut->_item = item;

    if ([item isKindOfClass:[FLEXProperty class]]) {
        if (shortcut.property.isClassProperty) {
            shortcut->_metadataKind =  FLEXMetadataKindClassProperties;
        } else {
            shortcut->_metadataKind =  FLEXMetadataKindProperties;
        }
    }
    if ([item isKindOfClass:[FLEXIvar class]]) {
        shortcut->_metadataKind = FLEXMetadataKindIvars;
    }
    if ([item isKindOfClass:[FLEXMethod class]]) {
        // We don't care if it's a class method or not
        shortcut->_metadataKind = FLEXMetadataKindMethods;
    }

    return shortcut;
}

- (id)propertyOrIvarValue:(id)object {
    BOOL objectIsInstance = !object_isClass(object);

    // We use -[FLEXObjectExplorer valueFor...:] instead of getValue: below
    // because we want to "preview" what object is being stored if this is
    // a void * or something and we're given an NSValue back from getValue:
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindClassProperties: {
            // Decide whether to use object or [object class] to check for a potential value
            id targetForValueCheck = nil;
            if (objectIsInstance) {
                if (self.property.isClassProperty) {
                    targetForValueCheck = [object class];
                } else {
                    targetForValueCheck = object;
                }
            } else {
                if (self.property.isClassProperty) {
                    targetForValueCheck = object;
                } else {
                    // Instance property with a class object
                    return nil;
                }
            }

            return [self.property getPotentiallyUnboxedValue:targetForValueCheck];
        }
        case FLEXMetadataKindIvars: {
            if (objectIsInstance) {
                return [self.ivar getPotentiallyUnboxedValue:object];
            }

            return nil;
        }

        // Methods: nil
        case FLEXMetadataKindMethods:
        case FLEXMetadataKindClassMethods:
            return nil;
    }
}

- (NSString *)titleWith:(id)object {
    switch (self.metadataKind) {
        case FLEXMetadataKindClassProperties:
        case FLEXMetadataKindProperties:
            // Since we're outside of the "properties" section, prepend @property for clarity.
            return [@"@property " stringByAppendingString:[_item description]];
        case FLEXMetadataKindIvars:
        case FLEXMetadataKindMethods:
            return [_item description];

        default:
            break;
    }

    if ([_item isKindOfClass:[NSString class]]) {
        return _item;
    }

    [NSException
        raise:NSInvalidArgumentException
        format:@"Unsupported shortcut '%@':\n%@",
        [_item class], [_item description]
    ];
    return nil;
}

- (NSString *)subtitleWith:(id)fromObject {
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindIvars:
            return [FLEXRuntimeUtility
                summaryForObject:[self propertyOrIvarValue:fromObject]
            ];
        case FLEXMetadataKindMethods:
        case FLEXMetadataKindClassMethods:
            return [_item selectorString];

        default:
            break;
    }

    if ([_item isKindOfClass:[NSString class]]) {
        // Must return empty string since these will be
        // gathered into an array. If the object is a
        // just a string, it doesn't get a subtitle.
        return @"";
    }

    [NSException
        raise:NSInvalidArgumentException
        format:@"Unsupported shortcut '%@':\n%@",
        [_item class], [_item description]
    ];
    return nil;
}

- (UIViewController *)viewerWith:(id)object {
    // View or edit a property or ivar
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindIvars:
            return [FLEXObjectExplorerFactory
                explorerViewControllerForObject:[self propertyOrIvarValue:object]
            ];
        case FLEXMetadataKindMethods:
        case FLEXMetadataKindClassMethods:
            object = self.method.isInstanceMethod ? object : (object_isClass(object) ? object : [object class]);
            return [FLEXMethodCallingViewController target:object method:self.method];

        default:
            return nil;
    }

    return nil;
}

- (UIViewController *)editorWith:(id)object {
    BOOL objectIsInstance = !object_isClass(object);
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
            NSAssert(objectIsInstance, @"Unreachable state: class object editing instance property");
            return [FLEXFieldEditorViewController target:object property:self.property];
        case FLEXMetadataKindClassProperties:
            if (objectIsInstance) {
                return [FLEXFieldEditorViewController target:[object class] property:self.property];
            } else {
                return [FLEXFieldEditorViewController target:object property:self.property];
            }
        case FLEXMetadataKindIvars:
            NSAssert(objectIsInstance, @"Unreachable state: class object editing ivar");
            return [FLEXFieldEditorViewController target:object ivar:self.ivar];

        default:
            break;
    }

    // Methods can't be edited
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    if (self.metadataKind) {
        return [self.metadata suggestedAccessoryTypeWithTarget:object];
    }

    return UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark - Helpers

- (FLEXProperty *)property { return _item; }
- (FLEXMethodBase *)method { return _item; }
- (FLEXIvar *)ivar { return _item; }
- (id<FLEXRuntimeMetadata>)metadata { return _item; }

@end
