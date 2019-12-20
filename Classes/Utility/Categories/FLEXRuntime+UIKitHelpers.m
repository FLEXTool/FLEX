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

@implementation FLEXProperty (UIKitHelpers)

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

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    BOOL objectIsInstance = !object_isClass(object);

    // Decide whether to use object or [object class] to check for a potential value
    id targetForValueCheck = nil;
    if (objectIsInstance) {
        if (self.isClassProperty) {
            targetForValueCheck = [object class];
        } else {
            targetForValueCheck = object;
        }
    } else {
        if (self.isClassProperty) {
            targetForValueCheck = object;
        } else {
            // Instance property with a class object
            return UITableViewCellAccessoryNone;
        }
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

@end


@implementation FLEXIvar (UIKitHelpers)

- (BOOL)isEditable {
    const FLEXTypeEncoding *typeEncoding = self.typeEncoding.UTF8String;
    return [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:nil];
}

- (BOOL)isCallable {
    return NO;
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

@end


@implementation FLEXMethodBase (UIKitHelpers)

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    // We shouldn't be using any FLEXMethodBase objects for this
    @throw NSInternalInconsistencyException;
    return UITableViewCellAccessoryNone;
}

@end

@implementation FLEXMethod (UIKitHelpers)

- (BOOL)isCallable {
    return self.signature != nil;
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
