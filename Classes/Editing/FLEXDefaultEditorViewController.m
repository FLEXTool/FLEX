//
//  FLEXDefaultEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2020 Flipboard. All rights reserved.
//

#import "FLEXDefaultEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"

@interface FLEXDefaultEditorViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic) NSString *key;

@end

@implementation FLEXDefaultEditorViewController

- (id)initWithDefaults:(NSUserDefaults *)defaults key:(NSString *)key {
    self = [super initWithTarget:defaults];
    if (self) {
        self.key = key;
        self.title = @"Edit Default";
    }
    return self;
}

- (NSUserDefaults *)defaults {
    return [self.target isKindOfClass:[NSUserDefaults class]] ? self.target : nil;
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
    [super actionButtonPressed:sender];
    
    id value = self.firstInputView.inputValue;
    if (value) {
        [self.defaults setObject:value forKey:self.key];
    } else {
        [self.defaults removeObjectForKey:self.key];
    }
    [self.defaults synchronize];

    self.firstInputView.inputValue = [self.defaults objectForKey:self.key];
}

- (void)getterButtonPressed:(id)sender {
    [super getterButtonPressed:sender];
    id returnedObject = [self.defaults objectForKey:self.key];
    [self exploreObjectOrPopViewController:returnedObject];
}

+ (BOOL)canEditDefaultWithValue:(id)currentValue {
    return [FLEXArgumentInputViewFactory
        canEditFieldWithTypeEncoding:FLEXEncodeObject(currentValue)
        currentValue:currentValue
    ];
}

@end
