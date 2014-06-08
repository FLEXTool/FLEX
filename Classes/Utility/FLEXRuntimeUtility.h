//
//  FLEXRuntimeUtility.h
//  Flipboard
//
//  Created by Ryan Olson on 6/8/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

extern const unsigned int kFLEXNumberOfImplicitArgs;

@interface FLEXRuntimeUtility : NSObject

// Property Helpers
+ (NSString *)prettyNameForProperty:(objc_property_t)property;
+ (NSString *)typeEncodingForProperty:(objc_property_t)property;
+ (BOOL)isReadonlyProperty:(objc_property_t)property;
+ (SEL)setterSelectorForProperty:(objc_property_t)property;
+ (NSString *)fullDescriptionForProperty:(objc_property_t)property;
+ (id)valueForProperty:(objc_property_t)property onObject:(id)object;
+ (NSString *)descriptionForIvarOrPropertyValue:(id)value;

// Ivar Helpers
+ (NSString *)prettyNameForIvar:(Ivar)ivar;
+ (id)valueForIvar:(Ivar)ivar onObject:(id)object;
+ (void)setIvar:(Ivar)ivar onObject:(id)object withInputString:(NSString *)inputString;

// Method Helpers
+ (NSString *)prettyNameForMethod:(Method)method isClassMethod:(BOOL)isClassMethod;
+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;

// Method Calling/Field Editing
+ (id)performSelector:(SEL)selector onObject:(id)object withArguments:(NSArray *)arguments error:(NSError * __autoreleasing *)error;
+ (NSString *)editiableDescriptionForObject:(id)object;
+ (id)objectValueFromEditableString:(NSString *)string;

@end
