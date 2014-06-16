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
#import "FLEXArgumentInputViewFactory.h"

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
    
    const char *typeEncoding = [[FLEXRuntimeUtility typeEncodingForProperty:self.property] UTF8String];
    FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:typeEncoding];
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.targetSize = FLEXArgumentInputViewSizeLarge;
    inputView.inputOutput = [FLEXRuntimeUtility valueForProperty:self.property onObject:self.target];
    self.fieldEditorView.argumentInputViews = @[inputView];
}

- (void)actionButtonPressed:(id)sender
{
    [super actionButtonPressed:sender];
    
    id userInputObject = self.firstInputView.inputOutput;
    NSArray *arguments = userInputObject ? @[userInputObject] : nil;
    SEL setterSelector = [FLEXRuntimeUtility setterSelectorForProperty:self.property];
    [FLEXRuntimeUtility performSelector:setterSelector onObject:self.target withArguments:arguments error:NULL];
    
    self.firstInputView.inputOutput = [FLEXRuntimeUtility valueForProperty:self.property onObject:self.target];
}

+ (BOOL)canEditProperty:(objc_property_t)property currentValue:(id)value
{
    const char *typeEncoding = [[FLEXRuntimeUtility typeEncodingForProperty:property] UTF8String];
    BOOL canEditType = [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:value];
    BOOL isReadonly = [FLEXRuntimeUtility isReadonlyProperty:property];
    return canEditType && !isReadonly;
}

@end
