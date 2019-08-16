//
//  FLEXFieldEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXObjectExplorerViewController.h"

@interface FLEXFieldEditorViewController () <UIScrollViewDelegate>

@property (nonatomic) UIScrollView *scrollView;

@property (nonatomic, readwrite) id target;
@property (nonatomic, readwrite) FLEXFieldEditorView *fieldEditorView;
@property (nonatomic, readwrite) UIBarButtonItem *setterButton;

@end

@implementation FLEXFieldEditorViewController

- (id)initWithTarget:(id)target
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.target = target;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardRectInWindow = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize keyboardSize = [self.view convertRect:keyboardRectInWindow fromView:nil].size;
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = keyboardSize.height;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
    
    // Find the active input view and scroll to make sure it's visible.
    for (FLEXArgumentInputView *argumentInputView in self.fieldEditorView.argumentInputViews) {
        if (argumentInputView.inputViewIsFirstResponder) {
            CGRect scrollToVisibleRect = [self.scrollView convertRect:argumentInputView.bounds fromView:argumentInputView];
            [self.scrollView scrollRectToVisible:scrollToVisibleRect animated:YES];
            break;
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = 0.0;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [FLEXColor scrollViewBackgroundColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    self.fieldEditorView = [FLEXFieldEditorView new];
    self.fieldEditorView.backgroundColor = self.view.backgroundColor;
    self.fieldEditorView.targetDescription = [NSString stringWithFormat:@"%@ %p", [self.target class], self.target];
    [self.scrollView addSubview:self.fieldEditorView];
    
    self.setterButton = [[UIBarButtonItem alloc] initWithTitle:[self titleForActionButton] style:UIBarButtonItemStyleDone target:self action:@selector(actionButtonPressed:)];
    self.navigationItem.rightBarButtonItem = self.setterButton;
}

- (void)viewWillLayoutSubviews
{
    CGSize constrainSize = CGSizeMake(self.scrollView.bounds.size.width, CGFLOAT_MAX);
    CGSize fieldEditorSize = [self.fieldEditorView sizeThatFits:constrainSize];
    self.fieldEditorView.frame = CGRectMake(0, 0, fieldEditorSize.width, fieldEditorSize.height);
    self.scrollView.contentSize = fieldEditorSize;
}

- (FLEXArgumentInputView *)firstInputView
{
    return [self.fieldEditorView argumentInputViews].firstObject;
}

- (void)actionButtonPressed:(id)sender
{
    // Subclasses can override
    [self.fieldEditorView endEditing:YES];
}

- (NSString *)titleForActionButton
{
    // Subclasses can override.
    return @"Set";
}

- (void)exploreObjectOrPopViewController:(id)objectOrNil {
    if (objectOrNil) {
        // For non-nil (or void) return types, push an explorer view controller to display the object
        FLEXObjectExplorerViewController *explorerViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:objectOrNil];
        [self.navigationController pushViewController:explorerViewController animated:YES];
    } else {
        // If we didn't get a returned object but the method call succeeded,
        // pop this view controller off the stack to indicate that the call went through.
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
