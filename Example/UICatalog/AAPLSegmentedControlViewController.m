/*
        File: AAPLSegmentedControlViewController.m
    Abstract: A view controller that demonstrates how to use UISegmentedControl.
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

#import "AAPLSegmentedControlViewController.h"

@interface AAPLSegmentedControlViewController()

@property (nonatomic, weak) IBOutlet UISegmentedControl *defaultSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *tintedSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *customSegmentsSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *customBackgroundSegmentedControl;

@end


#pragma mark -

@implementation AAPLSegmentedControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultSegmentedControl];
    [self configureTintedSegmentedControl];
    [self configureCustomSegmentsSegmentedControl];
    [self configureCustomBackgroundSegmentedControl];
}


#pragma mark - Configuration

- (void)configureDefaultSegmentedControl {
    self.defaultSegmentedControl.momentary = YES;

    [self.defaultSegmentedControl setEnabled:NO forSegmentAtIndex:0];

    [self.defaultSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedSegmentedControl {
    self.tintedSegmentedControl.tintColor = [UIColor aapl_applicationBlueColor];

    self.tintedSegmentedControl.selectedSegmentIndex = 1;

    [self.tintedSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomSegmentsSegmentedControl {
    NSDictionary *imageToAccesssibilityLabelMappings = @{
        @"checkmark_icon": NSLocalizedString(@"Done", nil),
        @"search_icon": NSLocalizedString(@"Search", nil),
        @"tools_icon": NSLocalizedString(@"Settings", nil)
    };
    
    // Guarantee that the segments show up in the same order.
    NSArray *sortedSegmentImageNames = [[imageToAccesssibilityLabelMappings allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    [sortedSegmentImageNames enumerateObjectsUsingBlock:^(NSString *segmentImageName, NSUInteger idx, BOOL *stop) {
        UIImage *image = [UIImage imageNamed:segmentImageName];
        
        image.accessibilityLabel = imageToAccesssibilityLabelMappings[segmentImageName];
        
        [self.customSegmentsSegmentedControl setImage:image forSegmentAtIndex:idx];
    }];
    
    self.customSegmentsSegmentedControl.selectedSegmentIndex = 0;
    
    [self.customSegmentsSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomBackgroundSegmentedControl {
    self.customBackgroundSegmentedControl.selectedSegmentIndex = 2;
    
    [self.customBackgroundSegmentedControl setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    [self.customBackgroundSegmentedControl setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background_disabled"] forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];

    [self.customBackgroundSegmentedControl setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background_highlighted"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    [self.customBackgroundSegmentedControl setDividerImage:[UIImage imageNamed:@"stepper_and_segment_segment_divider"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIFontDescriptor *captionFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
    UIFont *font = [UIFont fontWithDescriptor:captionFontDescriptor size:0];

    NSDictionary *normalTextAttributes = @{NSForegroundColorAttributeName:[UIColor aapl_applicationPurpleColor], NSFontAttributeName:font};
    [self.customBackgroundSegmentedControl setTitleTextAttributes:normalTextAttributes forState:UIControlStateNormal];

    NSDictionary *highlightedTextAttributes = @{NSForegroundColorAttributeName:[UIColor aapl_applicationGreenColor], NSFontAttributeName:font};
    [self.customBackgroundSegmentedControl setTitleTextAttributes:highlightedTextAttributes forState:UIControlStateHighlighted];
    
    [self.customBackgroundSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)selectedSegmentDidChange:(UISegmentedControl *)segmentedControl {
    NSLog(@"The selected segment changed for: %@.", segmentedControl);
}

@end
