//
//  FLEXArgumentInputViewFactory.h
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import <Foundation/Foundation.h>

@class FLEXArgumentInputView;

@interface FLEXArgumentInputViewFactory : NSObject

/// The main factory method for making argument input view subclasses that are the best fit for the type.
+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding;

/// A way to check if we should try editing a filed given its type encoding and value.
/// Useful when deciding whether to edit or explore a property, ivar, or NSUserDefaults value.
+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue;

@end
