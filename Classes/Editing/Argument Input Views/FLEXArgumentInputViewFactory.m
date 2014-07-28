//
//  FLEXArgumentInputViewFactory.m
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputViewFactory.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputJSONObjectView.h"
#import "FLEXArgumentInputNumberView.h"
#import "FLEXArgumentInputSwitchView.h"
#import "FLEXArgumentInputStructView.h"
#import "FLEXArgumentInputNotSupportedView.h"
#import "FLEXArgumentInputStringView.h"
#import "FLEXArgumentInputFontView.h"
#import "FLEXArgumentInputColorView.h"

@implementation FLEXArgumentInputViewFactory

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding
{
    Class subclass = [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:nil];
    if (!subclass) {
        // Fall back to a FLEXArgumentInputNotSupportedView if we can't find a subclass that fits the type encoding.
        // The unsupported view shows "nil" and does not allow user input.
        subclass = [FLEXArgumentInputNotSupportedView class];
    }
    return [[subclass alloc] initWithArgumentTypeEncoding:typeEncoding];
}

+ (Class)argumentInputViewSubclassForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue
{
    Class argumentInputViewSubclass = nil;
    
    // Note that order is important here since multiple subclasses may support the same type.
    // An example is the number subclass and the bool subclass for the type @encode(BOOL).
    // Both work, but we'd prefer to use the bool subclass.
    if ([FLEXArgumentInputColorView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputColorView class];
    } else if ([FLEXArgumentInputFontView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputFontView class];
    } else if ([FLEXArgumentInputStringView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputStringView class];
    } else if ([FLEXArgumentInputStructView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputStructView class];
    } else if ([FLEXArgumentInputSwitchView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputSwitchView class];
    } else if ([FLEXArgumentInputNumberView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputNumberView class];
    } else if ([FLEXArgumentInputJSONObjectView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
        argumentInputViewSubclass = [FLEXArgumentInputJSONObjectView class];
    }
    
    return argumentInputViewSubclass;
}

+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue
{
    return [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue] != nil;
}

@end
