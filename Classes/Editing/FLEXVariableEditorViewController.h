//
//  FLEXVariableEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXFieldEditorView;
@class FLEXArgumentInputView;

/// Provides a screen for editing or configuring one or more variables.
@interface FLEXVariableEditorViewController : UIViewController

+ (instancetype)target:(id)target;
- (id)initWithTarget:(id)target;

// Convenience accessor since many subclasses only use one input view
@property (nonatomic, readonly) FLEXArgumentInputView *firstInputView;

// For subclass use only.
@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) FLEXFieldEditorView *fieldEditorView;
/// Subclasses can change the button title via the button's \c title property
@property (nonatomic, readonly) UIBarButtonItem *actionButton;

- (void)actionButtonPressed:(id)sender;

/// Pushes an explorer view controller for the given object
/// or pops the current view controller.
- (void)exploreObjectOrPopViewController:(id)objectOrNil;

@end
