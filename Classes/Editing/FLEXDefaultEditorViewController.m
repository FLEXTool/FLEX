//
//  FLEXDefaultEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXDefaultEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"

@interface FLEXDefaultEditorViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic, readonly) NSString *key;

@end

@implementation FLEXDefaultEditorViewController

+ (instancetype)target:(NSUserDefaults *)defaults key:(NSString *)key commitHandler:(void(^_Nullable)())onCommit {
    FLEXDefaultEditorViewController *editor = [self target:defaults data:key commitHandler:onCommit];
    editor.title = @"Edit Default";
    return editor;
}

- (NSUserDefaults *)defaults {
    return [_target isKindOfClass:[NSUserDefaults class]] ? _target : nil;
}

- (NSString *)key {
    return _data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = self.key;

    id currentValue = [self.defaults objectForKey:self.key];
    FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory
        argumentInputViewForTypeEncoding:FLEXEncodeObject(currentValue)
        currentValue:currentValue
    ];
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.inputValue = currentValue;
    self.fieldEditorView.argumentInputViews = @[inputView];
}

- (void)actionButtonPressed:(id)sender {
    id value = self.firstInputView.inputValue;
    if (value) {
        [self.defaults setObject:value forKey:self.key];
    } else {
        [self.defaults removeObjectForKey:self.key];
    }
    [self.defaults synchronize];
    
    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];
    
    // Go back after setting, but not for switches.
    if (sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        self.firstInputView.inputValue = [self.defaults objectForKey:self.key];
    }
}

+ (BOOL)canEditDefaultWithValue:(id)currentValue {
    return [FLEXArgumentInputViewFactory
        canEditFieldWithTypeEncoding:FLEXEncodeObject(currentValue)
        currentValue:currentValue
    ];
}

@end
