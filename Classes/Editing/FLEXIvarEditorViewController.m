//
//  FLEXIvarEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXIvarEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputView.h"

@interface FLEXIvarEditorViewController ()

@property (nonatomic, assign) Ivar ivar;

@end

@implementation FLEXIvarEditorViewController

- (id)initWithTarget:(id)target ivar:(Ivar)ivar
{
    self = [super initWithTarget:target];
    if (self) {
        self.ivar = ivar;
        self.title = @"Instance Variable";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = [FLEXRuntimeUtility prettyNameForIvar:self.ivar];
    
    [self updateTextFieldString];
    
    // Use the numeric keyboard for primitives and the letter keyboard for strings
    NSString *typeEncoding = @(ivar_getTypeEncoding(self.ivar));
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
    id ivarValue = [FLEXRuntimeUtility valueForIvar:self.ivar onObject:self.target];
    self.firstInputView.inputText = [FLEXRuntimeUtility editiableDescriptionForObject:ivarValue];
}

- (void)updatePropertyFromString:(NSString *)string
{
    [FLEXRuntimeUtility setIvar:self.ivar onObject:self.target withInputString:self.firstInputView.inputText];
}

+ (BOOL)canEditIvar:(Ivar)ivar currentValue:(id)value
{
    return [self canEditType:@(ivar_getTypeEncoding(ivar)) currentObjectValue:value];
}

@end
