/*
        File: AAPLTextFieldViewController.m
    Abstract: A view controller that demonstrates how to use UITextField.
     Version: 2.12
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    
*/

#import "AAPLTextFieldViewController.h"

@interface AAPLTextFieldViewController()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITextField *tintedTextField;
@property (nonatomic, weak) IBOutlet UITextField *secureTextField;
@property (nonatomic, weak) IBOutlet UITextField *specificKeyboardTextField;
@property (nonatomic, weak) IBOutlet UITextField *customTextField;

@end


#pragma mark -

@implementation AAPLTextFieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTextField];
    [self configureTintedTextField];
    [self configureSecureTextField];
    [self configureSpecificKeyboardTextField];
    [self configureCustomTextField];
}


#pragma mark - Configuration

- (void)configureTextField {
    self.textField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.textField.autocorrectionType = UITextAutocorrectionTypeYes;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
}

- (void)configureTintedTextField {
    self.tintedTextField.tintColor = [UIColor aapl_applicationBlueColor];
    self.tintedTextField.textColor = [UIColor aapl_applicationGreenColor];

    self.tintedTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.tintedTextField.returnKeyType = UIReturnKeyDone;
    self.tintedTextField.clearButtonMode = UITextFieldViewModeNever;
}

- (void)configureSecureTextField {
    self.secureTextField.secureTextEntry = YES;

    self.secureTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.secureTextField.returnKeyType = UIReturnKeyDone;
    self.secureTextField.clearButtonMode = UITextFieldViewModeAlways;
}

/// There are many different types of keyboards that you may choose to use.
/// The different types of keyboards are defined in UITextInputTraits.h.
/// This example shows how to display a keyboard to help enter email addresses.
- (void)configureSpecificKeyboardTextField {
    self.specificKeyboardTextField.keyboardType = UIKeyboardTypeEmailAddress;

    self.specificKeyboardTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.specificKeyboardTextField.returnKeyType = UIReturnKeyDone;
}

- (void)configureCustomTextField {
    // Text fields with custom image backgrounds must have no border.
    self.customTextField.borderStyle = UITextBorderStyleNone;
    
    self.customTextField.background = [UIImage imageNamed:@"text_field_background"];
    
    // Create purple button that, when selected, turns the custom text field's text color to purple.
    UIImage *purpleImage = [UIImage imageNamed:@"text_field_purple_right_view"];
    UIButton *purpleImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    purpleImageButton.bounds = CGRectMake(0, 0, purpleImage.size.width, purpleImage.size.height);
    purpleImageButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
    [purpleImageButton setImage:purpleImage forState:UIControlStateNormal];
    [purpleImageButton addTarget:self action:@selector(customTextFieldPurpleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.customTextField.rightView = purpleImageButton;
    self.customTextField.rightViewMode = UITextFieldViewModeAlways;

    // Add an empty view as the left view to ensure inset between the text and the bounding rectangle.
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    leftPaddingView.backgroundColor = [UIColor clearColor];
    self.customTextField.leftView = leftPaddingView;
    self.customTextField.leftViewMode = UITextFieldViewModeAlways;

    self.customTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.customTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.customTextField.returnKeyType = UIReturnKeyDone;
}


#pragma mark - UITextFieldDelegate (set in Interface Builder)

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Actions

- (void)customTextFieldPurpleButtonClicked {
    self.customTextField.textColor = [UIColor aapl_applicationPurpleColor];

    NSLog(@"The custom text field's purple right view button was clicked.");
}

@end
