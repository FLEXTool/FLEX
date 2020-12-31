//
//  FLEXArgumentInputJSONObjectView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/15/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXArgumentInputObjectView.h"
#import "FLEXRuntimeUtility.h"

static const CGFloat kSegmentInputMargin = 10;

typedef NS_ENUM(NSUInteger, FLEXArgInputObjectType) {
    FLEXArgInputObjectTypeJSON,
    FLEXArgInputObjectTypeAddress
};

@interface FLEXArgumentInputObjectView ()

@property (nonatomic) UISegmentedControl *objectTypeSegmentControl;
@property (nonatomic) FLEXArgInputObjectType inputType;

@end

@implementation FLEXArgumentInputObjectView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        // Start with the numbers and punctuation keyboard since quotes, curly braces, or
        // square brackets are likely to be the first characters type for the JSON.
        self.inputTextView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.targetSize = FLEXArgumentInputViewSizeLarge;

        self.objectTypeSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Value", @"Address"]];
        [self.objectTypeSegmentControl addTarget:self action:@selector(didChangeType) forControlEvents:UIControlEventValueChanged];
        self.objectTypeSegmentControl.selectedSegmentIndex = 0;
        [self addSubview:self.objectTypeSegmentControl];

        self.inputType = [[self class] preferredDefaultTypeForObjCType:typeEncoding withCurrentValue:nil];
        self.objectTypeSegmentControl.selectedSegmentIndex = self.inputType;
    }

    return self;
}

- (void)didChangeType {
    self.inputType = self.objectTypeSegmentControl.selectedSegmentIndex;

    if (super.inputValue) {
        // Trigger an update to the text field to show
        // the address of the stored object we were given,
        // or to show a JSON representation of the object
        [self populateTextAreaFromValue:super.inputValue];
    } else {
        // Clear the text field
        [self populateTextAreaFromValue:nil];
    }
}

- (void)setInputType:(FLEXArgInputObjectType)inputType {
    if (_inputType == inputType) return;

    _inputType = inputType;

    // Resize input view
    switch (inputType) {
        case FLEXArgInputObjectTypeJSON:
            self.targetSize = FLEXArgumentInputViewSizeLarge;
            break;
        case FLEXArgInputObjectTypeAddress:
            self.targetSize = FLEXArgumentInputViewSizeSmall;
            break;
    }

    // Change placeholder
    switch (inputType) {
        case FLEXArgInputObjectTypeJSON:
            self.inputPlaceholderText =
            @"You can put any valid JSON here, such as a string, number, array, or dictionary:"
            "\n\"This is a string\""
            "\n1234"
            "\n{ \"name\": \"Bob\", \"age\": 47 }"
            "\n["
            "\n   1, 2, 3"
            "\n]";
            break;
        case FLEXArgInputObjectTypeAddress:
            self.inputPlaceholderText = @"0x0000deadb33f";
            break;
    }

    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

- (void)setInputValue:(id)inputValue {
    super.inputValue = inputValue;
    [self populateTextAreaFromValue:inputValue];
}

- (id)inputValue {
    switch (self.inputType) {
        case FLEXArgInputObjectTypeJSON:
            return [FLEXRuntimeUtility objectValueFromEditableJSONString:self.inputTextView.text];
        case FLEXArgInputObjectTypeAddress: {
            NSScanner *scanner = [NSScanner scannerWithString:self.inputTextView.text];

            unsigned long long objectPointerValue;
            if ([scanner scanHexLongLong:&objectPointerValue]) {
                return (__bridge id)(void *)objectPointerValue;
            }

            return nil;
        }
    }
}

- (void)populateTextAreaFromValue:(id)value {
    if (!value) {
        self.inputTextView.text = nil;
    } else {
        if (self.inputType == FLEXArgInputObjectTypeJSON) {
            self.inputTextView.text = [FLEXRuntimeUtility editableJSONStringForObject:value];
        } else if (self.inputType == FLEXArgInputObjectTypeAddress) {
            self.inputTextView.text = [NSString stringWithFormat:@"%p", value];
        }
    }

    // Delegate methods are not called for programmatic changes
    [self textViewDidChange:self.inputTextView];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height += [self.objectTypeSegmentControl sizeThatFits:size].height + kSegmentInputMargin;

    return fitSize;
}

- (void)layoutSubviews {
    CGFloat segmentHeight = [self.objectTypeSegmentControl sizeThatFits:self.frame.size].height;
    self.objectTypeSegmentControl.frame = CGRectMake(
        0.0,
        // Our segmented control is taking the position
        // of the text view, as far as super is concerned,
        // and we override this property to be different
        super.topInputFieldVerticalLayoutGuide,
        self.frame.size.width,
        segmentHeight
    );

    [super layoutSubviews];
}

- (CGFloat)topInputFieldVerticalLayoutGuide {
    // Our text view is offset from the segmented control
    CGFloat segmentHeight = [self.objectTypeSegmentControl sizeThatFits:self.frame.size].height;
    return segmentHeight + super.topInputFieldVerticalLayoutGuide + kSegmentInputMargin;
}

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    // Must be object type
    return type[0] == FLEXTypeEncodingObjcObject || type[0] == FLEXTypeEncodingObjcClass;
}

+ (FLEXArgInputObjectType)preferredDefaultTypeForObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type[0] == FLEXTypeEncodingObjcObject || type[0] == FLEXTypeEncodingObjcClass);

    if (value) {
        // If there's a current value, it must be serializable to JSON
        // to display the JSON editor. Otherwise display the address field.
        if ([FLEXRuntimeUtility editableJSONStringForObject:value]) {
            return FLEXArgInputObjectTypeJSON;
        } else {
            return FLEXArgInputObjectTypeAddress;
        }
    } else {
        // Otherwise, see if we have more type information than just 'id'.
        // If we do, make sure the encoding is something serializable to JSON.
        // Properties and ivars keep more detailed type encoding information than method arguments.
        if (strcmp(type, @encode(id)) != 0) {
            BOOL isJSONSerializableType = NO;

            // Parse class name out of the string,
            // which is in the form `@"ClassName"`
            Class cls = NSClassFromString(({
                NSString *className = nil;
                NSScanner *scan = [NSScanner scannerWithString:@(type)];
                NSCharacterSet *allowed = [NSCharacterSet
                    characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$"
                ];

                // Skip over the @" then scan the name
                if ([scan scanString:@"@\"" intoString:nil]) {
                    [scan scanCharactersFromSet:allowed intoString:&className];
                }

                className;
            }));

            // Note: we can't use @encode(NSString) here because that drops
            // the class information and just goes to @encode(id).
            NSArray<Class> *jsonTypes = @[
                [NSString class],
                [NSNumber class],
                [NSArray class],
                [NSDictionary class],
            ];

            // Look for matching types
            for (Class jsonClass in jsonTypes) {
                if ([cls isSubclassOfClass:jsonClass]) {
                    isJSONSerializableType = YES;
                    break;
                }
            }

            if (isJSONSerializableType) {
                return FLEXArgInputObjectTypeJSON;
            } else {
                return FLEXArgInputObjectTypeAddress;
            }
        } else {
            return FLEXArgInputObjectTypeAddress;
        }
    }
}

@end
