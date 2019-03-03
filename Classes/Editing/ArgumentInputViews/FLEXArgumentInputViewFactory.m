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
#import "FLEXArgumentInputDateView.h"

@implementation FLEXArgumentInputViewFactory

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding
{
    return [self argumentInputViewForTypeEncoding:typeEncoding currentValue:nil];
}

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue
{
    Class subclass = [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue];
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
    NSArray<Class> *inputViewClasses = @[[FLEXArgumentInputColorView class],
                                         [FLEXArgumentInputFontView class],
                                         [FLEXArgumentInputStringView class],
                                         [FLEXArgumentInputStructView class],
                                         [FLEXArgumentInputSwitchView class],
                                         [FLEXArgumentInputDateView class],
                                         [FLEXArgumentInputNumberView class],
                                         [FLEXArgumentInputJSONObjectView class]];
    
    // Note that order is important here since multiple subclasses may support the same type.
    // An example is the number subclass and the bool subclass for the type @encode(BOOL).
    // Both work, but we'd prefer to use the bool subclass.
    for (Class inputView in inputViewClasses) {
        if ([inputView supportsObjCType:typeEncoding withCurrentValue:currentValue]) {
            argumentInputViewSubclass = inputView;
            break;
        }
    }
    
    return argumentInputViewSubclass;
}

+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue
{
    return [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue] != nil;
}

@end
