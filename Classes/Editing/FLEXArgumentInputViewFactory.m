//
//  FLEXArgumentInputViewFactory.m
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "Classes/Editing/FLEXArgumentInputViewFactory.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputObjectView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputNumberView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputSwitchView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputStructView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputNotSupportedView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputStringView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputFontView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputColorView.h"
#import "Classes/Editing/ArgumentInputViews/FLEXArgumentInputDateView.h"
#import "Classes/Utility/Runtime/FLEXRuntimeUtility.h"

@implementation FLEXArgumentInputViewFactory

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding {
    return [self argumentInputViewForTypeEncoding:typeEncoding currentValue:nil];
}

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    Class subclass = [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue];
    if (!subclass) {
        // Fall back to a FLEXArgumentInputNotSupportedView if we can't find a subclass that fits the type encoding.
        // The unsupported view shows "nil" and does not allow user input.
        subclass = [FLEXArgumentInputNotSupportedView class];
    }
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [FLEXRuntimeUtility fieldNameOffsetForTypeEncoding:typeEncoding];
    return [[subclass alloc] initWithArgumentTypeEncoding:typeEncoding + fieldNameOffset];
}

+ (Class)argumentInputViewSubclassForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [FLEXRuntimeUtility fieldNameOffsetForTypeEncoding:typeEncoding];
    Class argumentInputViewSubclass = nil;
    NSArray<Class> *inputViewClasses = @[[FLEXArgumentInputColorView class],
                                         [FLEXArgumentInputFontView class],
                                         [FLEXArgumentInputStringView class],
                                         [FLEXArgumentInputStructView class],
                                         [FLEXArgumentInputSwitchView class],
                                         [FLEXArgumentInputDateView class],
                                         [FLEXArgumentInputNumberView class],
                                         [FLEXArgumentInputObjectView class]];

    // Note that order is important here since multiple subclasses may support the same type.
    // An example is the number subclass and the bool subclass for the type @encode(BOOL).
    // Both work, but we'd prefer to use the bool subclass.
    for (Class inputViewClass in inputViewClasses) {
        if ([inputViewClass supportsObjCType:typeEncoding + fieldNameOffset withCurrentValue:currentValue]) {
            argumentInputViewSubclass = inputViewClass;
            break;
        }
    }

    return argumentInputViewSubclass;
}

+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    return [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue] != nil;
}

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    [FLEXArgumentInputStructView registerFieldNames:names forTypeEncoding:typeEncoding];
}

@end
