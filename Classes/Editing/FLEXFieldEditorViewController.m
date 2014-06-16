//
//  FLEXFieldEditorViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXFieldEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"

@interface FLEXFieldEditorViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong, readwrite) id target;
@property (nonatomic, strong, readwrite) FLEXFieldEditorView *fieldEditorView;
@property (nonatomic, strong, readwrite) UIBarButtonItem *setterButton;

@end

@implementation FLEXFieldEditorViewController

- (id)initWithTarget:(id)target
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.target = target;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [FLEXUtility scrollViewGrayColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    self.fieldEditorView = [[FLEXFieldEditorView alloc] init];
    self.fieldEditorView.backgroundColor = self.view.backgroundColor;
    self.fieldEditorView.targetDescription = [NSString stringWithFormat:@"%@ %p", [self.target class], self.target];
    [self.scrollView addSubview:self.fieldEditorView];
    
    // One argument input view by default. Subclasses can configure the field editor view with more/different argument input views if needed.
    FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:NULL];
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.targetSize = FLEXArgumentInputViewSizeLarge;
    self.fieldEditorView.argumentInputViews = @[inputView];
    
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
    return [[self.fieldEditorView argumentInputViews] firstObject];
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

+ (BOOL)canEditType:(NSString *)typeEncoding currentObjectValue:(id)value
{
    // Many primitive types can always be edited (numbers and supported structs).
    static NSArray *primitiveTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        primitiveTypes = @[@(@encode(char)),
                           @(@encode(int)),
                           @(@encode(short)),
                           @(@encode(long)),
                           @(@encode(long long)),
                           @(@encode(unsigned char)),
                           @(@encode(unsigned int)),
                           @(@encode(unsigned short)),
                           @(@encode(unsigned long)),
                           @(@encode(unsigned long long)),
                           @(@encode(float)),
                           @(@encode(double)),
                           @(@encode(CGRect)),
                           @(@encode(CGSize)),
                           @(@encode(CGPoint)),
                           @(@encode(CGAffineTransform)),
                           @(@encode(NSRange)),
                           @(@encode(UIEdgeInsets)),
                           @(@encode(UIOffset))];
    });
    
    BOOL canEdit = [primitiveTypes containsObject:typeEncoding];
    
    // Object types may be
    if (!canEdit) {
        if (value) {
            // If the current value is non-nil and we can represent it with an editable string, then we can suppor editing.
            canEdit = canEdit || [FLEXRuntimeUtility editiableDescriptionForObject:value] != nil;
        } else {
            // Also always edit types that are explicitly typed NSString, NSNumber, NSArray, or NSDictionary and are nil.
            // This kind of type encoding is only kept by ivars and properties. Method agruments and return types drop the class from the type encoding.
            // The editor supports populating these types through NSJSONSerilization parsing of the input string.
            canEdit = canEdit || [typeEncoding isEqual:[self stringTypeEncoding]];
            canEdit = canEdit || [typeEncoding isEqual:[self numberTypeEncoding]];
            canEdit = canEdit || [typeEncoding isEqual:[self arrayTypeEncoding]];
            canEdit = canEdit || [typeEncoding isEqual:[self dictionaryTypeEncoding]];
        }
    }
    
    return canEdit;
}

+ (NSString *)stringTypeEncoding
{
    return @"@\"NSString\"";
}

+ (NSString *)numberTypeEncoding
{
    return @"@\"NSNumber\"";
}

+ (NSString *)arrayTypeEncoding
{
    return @"@\"NSArray\"";
}

+ (NSString *)dictionaryTypeEncoding
{
    return @"@\"NSDictionary\"";
}

@end
