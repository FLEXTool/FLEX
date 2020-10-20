//
//  FLEXArgumentInputStructView.m
//  Flipboard
//
//  Created by Ryan Olson on 6/16/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXArgumentInputStructView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXTypeEncodingParser.h"

@interface FLEXArgumentInputStructView ()

@property (nonatomic) NSArray<FLEXArgumentInputView *> *argumentInputViews;

@end

@implementation FLEXArgumentInputStructView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        NSMutableArray<FLEXArgumentInputView *> *inputViews = [NSMutableArray new];
        NSArray<NSString *> *customTitles = [[self class] customFieldTitlesForTypeEncoding:typeEncoding];
        [FLEXRuntimeUtility enumerateTypesInStructEncoding:typeEncoding usingBlock:^(NSString *structName,
                                                                                     const char *fieldTypeEncoding,
                                                                                     NSString *prettyTypeEncoding,
                                                                                     NSUInteger fieldIndex,
                                                                                     NSUInteger fieldOffset) {
            
            FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:fieldTypeEncoding];
            inputView.targetSize = FLEXArgumentInputViewSizeSmall;
            
            if (fieldIndex < customTitles.count) {
                inputView.title = customTitles[fieldIndex];
            } else {
                inputView.title = [NSString stringWithFormat:@"%@ field %lu (%@)",
                    structName, (unsigned long)fieldIndex, prettyTypeEncoding
                ];
            }

            [inputViews addObject:inputView];
            [self addSubview:inputView];
        }];
        self.argumentInputViews = inputViews;
    }
    return self;
}


#pragma mark - Superclass Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    for (FLEXArgumentInputView *inputView in self.argumentInputViews) {
        inputView.backgroundColor = backgroundColor;
    }
}

- (void)setInputValue:(id)inputValue {
    if ([inputValue isKindOfClass:[NSValue class]]) {
        const char *structTypeEncoding = [inputValue objCType];
        if (strcmp(self.typeEncoding.UTF8String, structTypeEncoding) == 0) {
            NSUInteger valueSize = 0;
            
            if (FLEXGetSizeAndAlignment(structTypeEncoding, &valueSize, NULL)) {
                void *unboxedValue = malloc(valueSize);
                [inputValue getValue:unboxedValue];
                [FLEXRuntimeUtility enumerateTypesInStructEncoding:structTypeEncoding usingBlock:^(NSString *structName,
                                                                                                   const char *fieldTypeEncoding,
                                                                                                   NSString *prettyTypeEncoding,
                                                                                                   NSUInteger fieldIndex,
                                                                                                   NSUInteger fieldOffset) {
                    
                    void *fieldPointer = unboxedValue + fieldOffset;
                    FLEXArgumentInputView *inputView = self.argumentInputViews[fieldIndex];
                    
                    if (fieldTypeEncoding[0] == FLEXTypeEncodingObjcObject || fieldTypeEncoding[0] == FLEXTypeEncodingObjcClass) {
                        inputView.inputValue = (__bridge id)fieldPointer;
                    } else {
                        NSValue *boxedField = [FLEXRuntimeUtility valueForPrimitivePointer:fieldPointer objCType:fieldTypeEncoding];
                        inputView.inputValue = boxedField;
                    }
                }];
                free(unboxedValue);
            }
        }
    }
}

- (id)inputValue {
    NSValue *boxedStruct = nil;
    const char *structTypeEncoding = self.typeEncoding.UTF8String;
    NSUInteger structSize = 0;
    
    if (FLEXGetSizeAndAlignment(structTypeEncoding, &structSize, NULL)) {
        void *unboxedStruct = malloc(structSize);
        [FLEXRuntimeUtility enumerateTypesInStructEncoding:structTypeEncoding usingBlock:^(NSString *structName,
                                                                                           const char *fieldTypeEncoding,
                                                                                           NSString *prettyTypeEncoding,
                                                                                           NSUInteger fieldIndex,
                                                                                           NSUInteger fieldOffset) {
            
            void *fieldPointer = unboxedStruct + fieldOffset;
            FLEXArgumentInputView *inputView = self.argumentInputViews[fieldIndex];
            
            if (fieldTypeEncoding[0] == FLEXTypeEncodingObjcObject || fieldTypeEncoding[0] == FLEXTypeEncodingObjcClass) {
                // Object fields
                memcpy(fieldPointer, (__bridge void *)inputView.inputValue, sizeof(id));
            } else {
                // Boxed primitive/struct fields
                id inputValue = inputView.inputValue;
                if ([inputValue isKindOfClass:[NSValue class]] && strcmp([inputValue objCType], fieldTypeEncoding) == 0) {
                    [inputValue getValue:fieldPointer];
                }
            }
        }];
        
        boxedStruct = [NSValue value:unboxedStruct withObjCType:structTypeEncoding];
        free(unboxedStruct);
    }
    
    return boxedStruct;
}

- (BOOL)inputViewIsFirstResponder {
    BOOL isFirstResponder = NO;
    for (FLEXArgumentInputView *inputView in self.argumentInputViews) {
        if ([inputView inputViewIsFirstResponder]) {
            isFirstResponder = YES;
            break;
        }
    }
    return isFirstResponder;
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat runningOriginY = self.topInputFieldVerticalLayoutGuide;
    
    for (FLEXArgumentInputView *inputView in self.argumentInputViews) {
        CGSize inputFitSize = [inputView sizeThatFits:self.bounds.size];
        inputView.frame = CGRectMake(0, runningOriginY, inputFitSize.width, inputFitSize.height);
        runningOriginY = CGRectGetMaxY(inputView.frame) + [[self class] verticalPaddingBetweenFields];
    }
}

+ (CGFloat)verticalPaddingBetweenFields {
    return 10.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    
    CGSize constrainSize = CGSizeMake(size.width, CGFLOAT_MAX);
    CGFloat height = fitSize.height;
    
    for (FLEXArgumentInputView *inputView in self.argumentInputViews) {
        height += [inputView sizeThatFits:constrainSize].height;
        height += [[self class] verticalPaddingBetweenFields];
    }
    
    return CGSizeMake(fitSize.width, height);
}


#pragma mark - Class Helpers

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    if (type[0] == FLEXTypeEncodingStructBegin) {
        return FLEXGetSizeAndAlignment(type, nil, nil);
    }

    return NO;
}

+ (NSArray<NSString *> *)customFieldTitlesForTypeEncoding:(const char *)typeEncoding {
    NSArray<NSString *> *customTitles = nil;
    if (strcmp(typeEncoding, @encode(CGRect)) == 0) {
        customTitles = @[@"CGPoint origin", @"CGSize size"];
    } else if (strcmp(typeEncoding, @encode(CGPoint)) == 0) {
        customTitles = @[@"CGFloat x", @"CGFloat y"];
    } else if (strcmp(typeEncoding, @encode(CGSize)) == 0) {
        customTitles = @[@"CGFloat width", @"CGFloat height"];
    } else if (strcmp(typeEncoding, @encode(CGVector)) == 0) {
        customTitles = @[@"CGFloat dx", @"CGFloat dy"];
    } else if (strcmp(typeEncoding, @encode(UIEdgeInsets)) == 0) {
        customTitles = @[@"CGFloat top", @"CGFloat left", @"CGFloat bottom", @"CGFloat right"];
    } else if (strcmp(typeEncoding, @encode(UIOffset)) == 0) {
        customTitles = @[@"CGFloat horizontal", @"CGFloat vertical"];
    } else if (strcmp(typeEncoding, @encode(NSRange)) == 0) {
        customTitles = @[@"NSUInteger location", @"NSUInteger length"];
    } else if (strcmp(typeEncoding, @encode(CATransform3D)) == 0) {
        customTitles = @[@"CGFloat m11", @"CGFloat m12", @"CGFloat m13", @"CGFloat m14",
                         @"CGFloat m21", @"CGFloat m22", @"CGFloat m23", @"CGFloat m24",
                         @"CGFloat m31", @"CGFloat m32", @"CGFloat m33", @"CGFloat m34",
                         @"CGFloat m41", @"CGFloat m42", @"CGFloat m43", @"CGFloat m44"];
    } else if (strcmp(typeEncoding, @encode(CGAffineTransform)) == 0) {
        customTitles = @[@"CGFloat a", @"CGFloat b",
                         @"CGFloat c", @"CGFloat d",
                         @"CGFloat tx", @"CGFloat ty"];
    } else {
        if (@available(iOS 11.0, *)) {
            if (strcmp(typeEncoding, @encode(NSDirectionalEdgeInsets)) == 0) {
                customTitles = @[@"CGFloat top", @"CGFloat leading",
                                 @"CGFloat bottom", @"CGFloat trailing"];
            }
        }
    }
    return customTitles;
}

@end
