//
//  FLEXPropertyEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/20/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXPropertyEditorViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXFieldEditorView.h"
#import "FLEXArgumentInputView.h"

@interface FLEXPropertyEditorViewController ()

@property (nonatomic, assign) objc_property_t property;

@end

@implementation FLEXPropertyEditorViewController

- (id)initWithTarget:(id)target property:(objc_property_t)property
{
    self = [super initWithTarget:target];
    if (self) {
        self.property = property;
        self.title = @"Property";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = [FLEXRuntimeUtility fullDescriptionForProperty:self.property];
    id currentValue = [FLEXRuntimeUtility valueForProperty:self.property onObject:self.target];
    self.setterButton.enabled = [[self class] canEditProperty:self.property currentValue:currentValue];
    
    [self updateTextFieldString];
    
    // Use the numeric keyboard for primitives and the letter keyboard for strings
    NSString *typeEncoding = [FLEXRuntimeUtility typeEncodingForProperty:self.property];
    if ([typeEncoding isEqual:[[self class] stringTypeEncoding]]) {
        self.firstInputView.keyboardType = UIKeyboardTypeAlphabet;
    } else {
        self.firstInputView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
}

- (void)actionButtonPressed:(id)sender
{
    [super actionButtonPressed:sender];
    
    [self updatePropertyFromString:self.firstInputView.inputText];
    [self updateTextFieldString];
}

- (void)updateTextFieldString
{
    id propertyValue = [FLEXRuntimeUtility valueForProperty:self.property onObject:self.target];
    self.firstInputView.inputText = [FLEXRuntimeUtility editiableDescriptionForObject:propertyValue];
}

- (void)updatePropertyFromString:(NSString *)string
{
    SEL setterSelector = [FLEXRuntimeUtility setterSelectorForProperty:self.property];
    NSArray *arguments = string ? @[string] : nil;
    [FLEXRuntimeUtility performSelector:setterSelector onObject:self.target withArguments:arguments error:NULL];
}

+ (BOOL)canEditProperty:(objc_property_t)property currentValue:(id)value
{
    BOOL canEditType = [self canEditType:[FLEXRuntimeUtility typeEncodingForProperty:property] currentObjectValue:value];
    BOOL isReadonly = [FLEXRuntimeUtility isReadonlyProperty:property];
    return canEditType && !isReadonly;
}

@end
