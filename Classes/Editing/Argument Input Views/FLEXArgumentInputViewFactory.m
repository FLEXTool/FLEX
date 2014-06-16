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

@implementation FLEXArgumentInputViewFactory

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding
{
    Class subclass = [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:nil];
    if (!subclass) {
        // Fall back to a generic FLEXArgumentInputView if we can't find a subclass that supports the type.
        // The generic input view does not actually allow input, but it still shows the title of the field.
        subclass = [FLEXArgumentInputView class];
    }
    return [[subclass alloc] initWithArgumentTypeEncoding:typeEncoding];
}

+ (Class)argumentInputViewSubclassForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue
{
    Class argumentInputViewSubclass = nil;
    
    // Note that order is important here since multiple subclasses may support the same type.
    // An example is the number subclass and the bool subclass for the type @encode(BOOL).
    // Both work, but we'd prefer to use the bool subclass.
    if ([FLEXArgumentInputNumberView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
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
