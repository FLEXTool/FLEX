//
//  FLEXRuntime+UIKitHelpers.h
//  FLEX
//
//  Created by Tanner Bennett on 12/16/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXProperty.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"

@protocol FLEXRuntimeMetadata <NSObject>
/// YES for properties and ivars which surely support editing, NO for all methods.
@property (nonatomic, readonly) BOOL isEditable;
/// NO for ivars, YES for supported methods and properties
@property (nonatomic, readonly) BOOL isCallable;

/// For internal use
@property (nonatomic) id tag;

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object;
@end

// Even if a property is readonly, it still may be editable
// via a setter. Checking isEditable will not reflect that
// unless the property was initialized with a class.
@interface FLEXProperty (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXIvar (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXMethodBase (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXMethod (UIKitHelpers) <FLEXRuntimeMetadata> @end
