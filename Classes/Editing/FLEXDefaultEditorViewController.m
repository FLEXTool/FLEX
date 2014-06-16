//
//  FLEXDefaultEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXDefaultEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputView.h"

@interface FLEXDefaultEditorViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic, strong) NSString *key;

@end

@implementation FLEXDefaultEditorViewController

- (id)initWithDefaults:(NSUserDefaults *)defaults key:(NSString *)key
{
    self = [super initWithTarget:defaults];
    if (self) {
        self.key = key;
        self.title = @"Edit Default";
    }
    return self;
}

- (NSUserDefaults *)defaults
{
    return [self.target isKindOfClass:[NSUserDefaults class]] ? self.target : nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = self.key;
    
    [self updateTextFieldString];
}

- (void)actionButtonPressed:(id)sender
{
    [super actionButtonPressed:sender];
    
    id value = [FLEXRuntimeUtility objectValueFromEditableString:self.firstInputView.inputOutput];
    if (value) {
        [self.defaults setObject:value forKey:self.key];
    } else {
        [self.defaults removeObjectForKey:self.key];
    }
    [self.defaults synchronize];
    [self updateTextFieldString];
}

- (void)updateTextFieldString
{
    id defaultsValue = [self.defaults objectForKey:self.key];
    self.firstInputView.inputOutput = [FLEXRuntimeUtility editiableDescriptionForObject:defaultsValue];
}

+ (BOOL)canEditDefaultWithValue:(id)currentValue
{
    return !currentValue || [FLEXRuntimeUtility editiableDescriptionForObject:currentValue] != nil;
}

@end
