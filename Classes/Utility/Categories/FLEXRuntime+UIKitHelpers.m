//
//  FLEXRuntime+UIKitHelpers.m
//  FLEX
//
//  Created by Tanner Bennett on 12/16/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXRuntime+UIKitHelpers.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXTableView.h"

@implementation FLEXProperty (UIKitHelpers)

/// Decide whether to use object or [object class] to get or set property
- (id)targetForPropertyTypeGivenObject:(id)object {
    if (!object_isClass(object)) {
        if (self.isClassProperty) {
            return [object class];
        } else {
            return object;
        }
    } else {
        if (self.isClassProperty) {
            return object;
        } else {
            // Instance property with a class object
            return nil;
        }
    }
}

- (BOOL)isEditable {
    if (self.attributes.isReadOnly) {
        return self.likelySetterExists;
    }
    
    const FLEXTypeEncoding *typeEncoding = self.attributes.typeEncoding.UTF8String;
    return [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:nil];
}

- (BOOL)isCallable {
    return YES;
}

- (id)currentValueWithTarget:(id)object {
    return [self getPotentiallyUnboxedValue:
        [self targetForPropertyTypeGivenObject:object]
    ];
}

- (NSString *)previewWithTarget:(id)object {
    if (object_isClass(object) && !self.isClassProperty) {
        return self.attributes.fullDeclaration;
    } else {
        return [FLEXRuntimeUtility
            summaryForObject:[self currentValueWithTarget:object]
        ];
    }
}

- (UIViewController *)viewerWithTarget:(id)object {
    id value = [self currentValueWithTarget:object];
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:value];
}

- (UIViewController *)editorWithTarget:(id)object {
    id target = [self targetForPropertyTypeGivenObject:object];
    return [FLEXFieldEditorViewController target:target property:self];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    id targetForValueCheck = [self targetForPropertyTypeGivenObject:object];
    if (!targetForValueCheck) {
        // Instance property with a class object
        return UITableViewCellAccessoryNone;
    }

    // We use .tag to store the cached value of .isEditable that is
    // initialized by FLEXObjectExplorer in -reloadMetada
    if ([self getPotentiallyUnboxedValue:targetForValueCheck]) {
        if (self.tag) {
            // Editable non-nil value, both
            return UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            // Uneditable non-nil value, chevron only
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        if (self.tag) {
            // Editable nil value, just (i)
            return UITableViewCellAccessoryDetailButton;
        } else {
            // Non-editable nil value, neither
            return UITableViewCellAccessoryNone;
        }
    }
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

@end


@implementation FLEXIvar (UIKitHelpers)

- (BOOL)isEditable {
    const FLEXTypeEncoding *typeEncoding = self.typeEncoding.UTF8String;
    return [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:nil];
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    if (!object_isClass(object)) {
        return [self getPotentiallyUnboxedValue:object];
    }

    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    if (object_isClass(object)) {
        return self.details;
    }
    return [FLEXRuntimeUtility
        summaryForObject:[self currentValueWithTarget:object]
    ];
}

- (UIViewController *)viewerWithTarget:(id)object {
    NSAssert(!object_isClass(object), @"Unreachable state: viewing ivar on class object");
    id value = [self currentValueWithTarget:object];
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:value];
}

- (UIViewController *)editorWithTarget:(id)object {
    NSAssert(!object_isClass(object), @"Unreachable state: editing ivar on class object");
    return [FLEXFieldEditorViewController target:object ivar:self];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    if (object_isClass(object)) {
        return UITableViewCellAccessoryNone;
    }

    // Could use .isEditable here, but we use .tag for speed since it is cached
    if ([self getPotentiallyUnboxedValue:object]) {
        if (self.tag) {
            // Editable non-nil value, both
            return UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            // Uneditable non-nil value, chevron only
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        if (self.tag) {
            // Editable nil value, just (i)
            return UITableViewCellAccessoryDetailButton;
        } else {
            // Non-editable nil value, neither
            return UITableViewCellAccessoryNone;
        }
    }
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

@end


@implementation FLEXMethodBase (UIKitHelpers)

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    // Methods can't be "edited" and have no "value"
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return [self.selectorString stringByAppendingFormat:@"  —  %@", self.typeEncoding];
}

- (UIViewController *)viewerWithTarget:(id)object {
    // We disallow calling of FLEXMethodBase methods
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UIViewController *)editorWithTarget:(id)object {
    // Methods cannot be edited
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    // We shouldn't be using any FLEXMethodBase objects for this
    @throw NSInternalInconsistencyException;
    return UITableViewCellAccessoryNone;
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

@end

@implementation FLEXMethod (UIKitHelpers)

- (BOOL)isCallable {
    return self.signature != nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    object = self.isInstanceMethod ? object : (object_isClass(object) ? object : [object class]);
    return [FLEXMethodCallingViewController target:object method:self];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    if (self.isInstanceMethod) {
        if (object_isClass(object)) {
            // Instance method from class, can't call
            return UITableViewCellAccessoryNone;
        } else {
            // Instance method from instance, can call
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        return UITableViewCellAccessoryDisclosureIndicator;
    }
}

@end


@implementation FLEXProtocol (UIKitHelpers)

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:self];
}

- (UIViewController *)editorWithTarget:(id)object {
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    return UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

@end


@interface FLEXStaticMetadata ()
@property (nonatomic, readonly) FLEXTableViewCellReuseIdentifier reuse;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) id metadata;
@end

@implementation FLEXStaticMetadata
@synthesize name = _name;
@synthesize tag = _tag;

+ (instancetype)style:(FLEXStaticMetadataRowStyle)style title:(NSString *)title string:(NSString *)string {
    return [[self alloc] initWithStyle:style title:title subtitle:string];
}

+ (instancetype)style:(FLEXStaticMetadataRowStyle)style title:(NSString *)title number:(NSNumber *)number {
    return [[self alloc] initWithStyle:style title:title subtitle:number.stringValue];
}

- (id)initWithStyle:(FLEXStaticMetadataRowStyle)style title:(NSString *)title subtitle:(NSString *)subtitle  {
    self = [super init];
    if (self) {
        if (style == FLEXStaticMetadataRowStyleKeyValue) {
            _reuse = kFLEXKeyValueCell;
        } else {
            _reuse = kFLEXMultilineDetailCell;
        }

        _name = title;
        _subtitle = subtitle;
    }

    return self;
}

- (NSString *)description {
    return self.name;
}

- (NSString *)reuseIdentifierWithTarget:(id)object {
    return self.reuse;
}

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return self.subtitle;
}

- (UIViewController *)viewerWithTarget:(id)object {
    return nil;
}

- (UIViewController *)editorWithTarget:(id)object {
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    return UITableViewCellAccessoryNone;
}

@end
