/*
        File: AAPLSliderViewController.m
    Abstract: A view controller that demonstrates how to use UISlider.
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

#import "AAPLSliderViewController.h"

@interface AAPLSliderViewController ()

@property (nonatomic, weak) IBOutlet UISlider *defaultSlider;
@property (nonatomic, weak) IBOutlet UISlider *tintedSlider;
@property (nonatomic, weak) IBOutlet UISlider *customSlider;

@end


#pragma mark -

@implementation AAPLSliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultSlider];
    [self configureTintedSlider];
    [self configureCustomSlider];
}


#pragma mark - Configuration

- (void)configureDefaultSlider {
    self.defaultSlider.minimumValue = 0;
    self.defaultSlider.maximumValue = 100;
    self.defaultSlider.value = 42;
    self.defaultSlider.continuous = YES;
    
    [self.defaultSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedSlider {
    self.tintedSlider.minimumTrackTintColor = [UIColor aapl_applicationBlueColor];
    self.tintedSlider.maximumTrackTintColor = [UIColor aapl_applicationPurpleColor];

    [self.tintedSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomSlider {
    UIImage *leftTrackImage = [UIImage imageNamed:@"slider_blue_track"];
    [self.customSlider setMinimumTrackImage:leftTrackImage forState:UIControlStateNormal];
    
    UIImage *rightTrackImage = [UIImage imageNamed:@"slider_green_track"];
    [self.customSlider setMaximumTrackImage:rightTrackImage forState:UIControlStateNormal];
    
    UIImage *thumbImage = [UIImage imageNamed:@"slider_thumb"];
    [self.customSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    
    self.customSlider.minimumValue = 0;
    self.customSlider.maximumValue = 100;
    self.customSlider.continuous = NO;
    self.customSlider.value = 84;

    [self.customSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)sliderValueDidChange:(UISlider *)slider {
    NSLog(@"A slider changed its value: %@", slider);
}

@end
