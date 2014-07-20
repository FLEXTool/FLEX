/*
        File: AAPLStepperViewController.m
    Abstract: A view controller that demonstrates how to use UIStepper.
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

#import "AAPLStepperViewController.h"

@interface AAPLStepperViewController ()

@property (nonatomic, weak) IBOutlet UIStepper *defaultStepper;
@property (nonatomic, weak) IBOutlet UIStepper *tintedStepper;
@property (nonatomic, weak) IBOutlet UIStepper *customStepper;

@property (nonatomic, weak) IBOutlet UILabel *defaultStepperLabel;
@property (nonatomic, weak) IBOutlet UILabel *tintedStepperLabel;
@property (nonatomic, weak) IBOutlet UILabel *customStepperLabel;

@end


#pragma mark -

@implementation AAPLStepperViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultStepper];
    [self configureTintedStepper];
    [self configureCustomStepper];
}


#pragma mark - Configuration

- (void)configureDefaultStepper {
    self.defaultStepper.value = 0;
    self.defaultStepper.minimumValue = 0;
    self.defaultStepper.maximumValue = 10;
    self.defaultStepper.stepValue = 1;

    self.defaultStepperLabel.text = [NSString stringWithFormat:@"%ld", (long)self.defaultStepper.value];
    [self.defaultStepper addTarget:self action:@selector(stepperValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedStepper {
    self.tintedStepper.tintColor = [UIColor aapl_applicationBlueColor];

    self.tintedStepperLabel.text = [NSString stringWithFormat:@"%ld", (long)self.tintedStepper.value];
    [self.tintedStepper addTarget:self action:@selector(stepperValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomStepper {
    // Set the background image states.
    [self.customStepper setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background"] forState:UIControlStateNormal];
    [self.customStepper setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background_highlighted"] forState:UIControlStateHighlighted];
    [self.customStepper setBackgroundImage:[UIImage imageNamed:@"stepper_and_segment_background_disabled"] forState:UIControlStateDisabled];
    
    // Set the image which will be painted in between the two stepper segments (depends on the states of both segments).
    [self.customStepper setDividerImage:[UIImage imageNamed:@"stepper_and_segment_divider"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal];
    
    // Set the image for the + button.
    [self.customStepper setIncrementImage:[UIImage imageNamed:@"stepper_increment"] forState:UIControlStateNormal];
    
    // Set the image for the - button.
    [self.customStepper setDecrementImage:[UIImage imageNamed:@"stepper_decrement"] forState:UIControlStateNormal];

    self.customStepperLabel.text = [NSString stringWithFormat:@"%ld", (long)self.customStepper.value];
    [self.customStepper addTarget:self action:@selector(stepperValueDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)stepperValueDidChange:(UIStepper *)stepper {
    NSLog(@"A stepper changed its value: %@.", stepper);

    // Figure out which stepper was selected and update its associated label.
    UILabel *stepperLabel;
    if (self.defaultStepper == stepper) {
        stepperLabel = self.defaultStepperLabel;
    }
    else if (self.tintedStepper == stepper) {
        stepperLabel = self.tintedStepperLabel;
    }
    else if (self.customStepper == stepper) {
        stepperLabel = self.customStepperLabel;
    }

    stepperLabel.text = [NSString stringWithFormat:@"%ld", (long)stepper.value];
}

@end
