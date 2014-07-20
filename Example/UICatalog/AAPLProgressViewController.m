/*
        File: AAPLProgressViewController.m
    Abstract: A view controller that demonstrates how to use UIProgressView.
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

#import "AAPLProgressViewController.h"

const NSUInteger kProgressViewControllerMaxProgress = 100;


@interface AAPLProgressViewController()

@property (nonatomic, weak) IBOutlet UIProgressView *defaultStyleProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *barStyleProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *tintedProgressView;

@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSUInteger completedProgress;

@end


#pragma mark -

@implementation AAPLProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // All progress views should initially have zero progress.
    self.completedProgress = 0;

    [self configureDefaultStyleProgressView];
    [self configureBarStyleProgressView];
    [self configureTintedProgressView];

    // As progress is received from another subsystem (i.e. NSProgress, NSURLSessionTaskDelegate, etc.), update the progressView's progress.
    [self simulateProgress];
}

// Overrides the "completedProgress" property's setter.
- (void)setCompletedProgress:(NSUInteger)completedProgress {
    if (_completedProgress != completedProgress) {
        float fractionalProgress = (float)completedProgress / (float)kProgressViewControllerMaxProgress;

        [self.defaultStyleProgressView setProgress:fractionalProgress animated:YES];

        [self.barStyleProgressView setProgress:fractionalProgress animated:YES];

        [self.tintedProgressView setProgress:fractionalProgress animated:YES];

        _completedProgress = completedProgress;
    }
}


#pragma mark - Configuration

- (void)configureDefaultStyleProgressView {
    self.defaultStyleProgressView.progressViewStyle = UIProgressViewStyleDefault;
}

- (void)configureBarStyleProgressView {
    self.barStyleProgressView.progressViewStyle = UIProgressViewStyleBar;
}

- (void)configureTintedProgressView {
    self.tintedProgressView.progressViewStyle = UIProgressViewStyleDefault;

    self.tintedProgressView.trackTintColor = [UIColor aapl_applicationBlueColor];
    self.tintedProgressView.progressTintColor = [UIColor aapl_applicationPurpleColor];
}


#pragma mark - Progress Simulation

- (void)simulateProgress {
    // In this example we will simulate progress with a "sleep operation".
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    for (NSUInteger count = 0; count < kProgressViewControllerMaxProgress; count++) {
        [self.operationQueue addOperationWithBlock:^{
            // Delay the system for a random number of seconds.
            // This code is _not_ intended for production purposes. The "sleep" call is meant to simulate work done in another subsystem.
            sleep(arc4random_uniform(10));
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.completedProgress++;
            }];
        }];
    }
}

@end
