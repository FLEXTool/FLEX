/*
        File: AAPLButtonViewController.m
    Abstract: A view controller that demonstrates how to use UIButton. The buttons are created using storyboards, but each of the system buttons can be created in code by using the +[UIButton buttonWithType:] initializer. See UIButton.h for a comprehensive list of the various UIButtonType values.
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

#import "AAPLButtonViewController.h"

@interface AAPLButtonViewController()

@property (nonatomic, weak) IBOutlet UIButton *systemTextButton;
@property (nonatomic, weak) IBOutlet UIButton *systemContactAddButton;
@property (nonatomic, weak) IBOutlet UIButton *systemDetailDisclosureButton;
@property (nonatomic, weak) IBOutlet UIButton *imageButton;
@property (nonatomic, weak) IBOutlet UIButton *attributedTextButton;

@end


#pragma mark -

@implementation AAPLButtonViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // All of the buttons are created in the storyboard, but configured below.
    [self configureSystemTextButton];
    [self configureSystemContactAddButton];
    [self configureSystemDetailDisclosureButton];
    [self configureImageButton];
    [self configureAttributedTextSystemButton];
}


#pragma mark - Configuration

- (void)configureSystemTextButton {
    [self.systemTextButton setTitle:NSLocalizedString(@"Button", nil) forState:UIControlStateNormal];
    
    [self.systemTextButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureSystemContactAddButton {
    self.systemContactAddButton.backgroundColor = [UIColor clearColor];
    
    [self.systemContactAddButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureSystemDetailDisclosureButton {
    self.systemDetailDisclosureButton.backgroundColor = [UIColor clearColor];
    
    [self.systemDetailDisclosureButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureImageButton {
    // To create this button in code you can use +[UIButton buttonWithType:] with a parameter value of UIButtonTypeCustom.
    
    // Remove the title text.
    [self.imageButton setTitle:@"" forState:UIControlStateNormal];

    self.imageButton.tintColor = [UIColor aapl_applicationPurpleColor];
    
    [self.imageButton setImage:[UIImage imageNamed:@"x_icon"] forState:UIControlStateNormal];

    // Add an accessibility label to the image.
    self.imageButton.accessibilityLabel = NSLocalizedString(@"X Button", nil);
    
    [self.imageButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureAttributedTextSystemButton {
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor aapl_applicationBlueColor], NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)};
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Button", nil) attributes:titleAttributes];
    [self.attributedTextButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];

    NSDictionary *highlightedTitleAttributes = @{NSForegroundColorAttributeName : [UIColor aapl_applicationGreenColor], NSStrikethroughStyleAttributeName: @(NSUnderlineStyleThick)};
    NSAttributedString *highlightedAttributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Button", nil) attributes:highlightedTitleAttributes];
    [self.attributedTextButton setAttributedTitle:highlightedAttributedTitle forState:UIControlStateHighlighted];

    [self.attributedTextButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - Actions

// Handler for all of AAPLButtonViewController's UIButton actions.
- (void)buttonClicked:(UIButton *)button {
    NSLog(@"A button was clicked: %@.", button);
}

@end
