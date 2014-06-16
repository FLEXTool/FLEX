//
//  FLEXFieldEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXFieldEditorView;
@class FLEXArgumentInputView;

@interface FLEXFieldEditorViewController : UIViewController

- (id)initWithTarget:(id)target;

// Convenience accessor since many subclasses only use one input view
@property (nonatomic, readonly) FLEXArgumentInputView *firstInputView;

// For subclass use only.
@property (nonatomic, strong, readonly) id target;
@property (nonatomic, strong, readonly) FLEXFieldEditorView *fieldEditorView;
@property (nonatomic, strong, readonly) UIBarButtonItem *setterButton;
- (void)actionButtonPressed:(id)sender;
- (NSString *)titleForActionButton;

@end
