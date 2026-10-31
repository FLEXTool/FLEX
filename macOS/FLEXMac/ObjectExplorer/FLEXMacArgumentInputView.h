//
//  FLEXMacArgumentInputView.h
//  FLEX (macOS)
//
//  An input control for a value of a given Objective-C type encoding.
//  The AppKit counterpart of FLEXArgumentInputView and its subclasses.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacArgumentInputView : NSStackView

/// @return whether a value of this type can be entered by the user
+ (BOOL)supportsTypeEncoding:(nullable const char *)typeEncoding;

/// A readable description of a boxed struct, such as "{x: 0, y: 0, width: 10, height: 20}",
/// or nil if \c value is not a struct of numbers
+ (nullable NSString *)descriptionForStructValue:(id)value;

- (instancetype)initWithTypeEncoding:(const char *)typeEncoding title:(nullable NSString *)title;

@property (nonatomic, readonly) NSString *typeEncoding;

/// Fills the input with an existing value: an object for object types,
/// or an NSValue/NSNumber for primitive types.
- (void)populateWithValue:(nullable id)value;

/// The entered value: an object (or nil) for object types,
/// or an NSValue boxed with exactly \c typeEncoding for primitives.
/// @param error set when the input cannot be parsed
- (nullable id)inputValueWithError:(NSError **)error;

@property (nonatomic, readonly) NSView *firstInputView;

@end

NS_ASSUME_NONNULL_END
