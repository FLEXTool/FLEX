//
//  FLEXMutableFieldEditorViewController.m
//  FLEX
//
//  Created by Tanner on 11/22/18.
//  Copyright © 2018 Flipboard. All rights reserved.
//

#import "FLEXMutableFieldEditorViewController.h"
#import "FLEXFieldEditorView.h"

@interface FLEXMutableFieldEditorViewController ()

@property (nonatomic, readwrite) UIBarButtonItem *getterButton;

@end

@implementation FLEXMutableFieldEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.getterButton = [[UIBarButtonItem alloc] initWithTitle:[self titleForGetterButton] style:UIBarButtonItemStyleDone target:self action:@selector(getterButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[self.setterButton, self.getterButton];
}

- (void)getterButtonPressed:(id)sender {
    // Subclasses can override
    [self.fieldEditorView endEditing:YES];
}

- (NSString *)titleForGetterButton {
    return @"Get";
}

@end
