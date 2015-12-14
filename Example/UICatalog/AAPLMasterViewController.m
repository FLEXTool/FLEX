/*
        File: AAPLMasterViewController.m
    Abstract: An iPad-only class that ensures that the root view controller of the application always has the bar button item displayed when in portrait. See AAPLSplitViewControllerDelegate for more information.
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

#import "AAPLMasterViewController.h"

#if DEBUG
// FLEX should only be compiled and used in debug builds.
#import <FLEX/FLEX.h>
#endif

@implementation AAPLMasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if DEBUG
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"FLEX" style:UIBarButtonItemStylePlain target:self action:@selector(flexButtonTapped:)];
#endif
}

- (void)flexButtonTapped:(id)sender
{
#if DEBUG
    [[FLEXManager sharedManager] showExplorer];
#endif
}

// When a segue from the AAPLMasterViewController's table view is triggered, we want to ensure that the current detail view controller's
// "More" bar button item is correctly transferred to the destination detail view controller's navigation item. We are only concerned about
// this change when the application is in portrait mode since this is the only time that the "More" bar button item will be visible.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
#pragma clang diagnostic pop
        UINavigationController *newDetailViewController = [segue destinationViewController];
        UINavigationController *oldDetailViewController = [self.splitViewController.viewControllers lastObject];
        
        // In order for a segue to occur when the view controller is in portrait, the "More" bar button item must be visible.
        // However, the "More" bar button item is only visible if the detail view controller's root view controller is
        // visible (otherwise there would be a "Back" bar button item). We can then query the old detail view controller's top view
        // controller for the current "More" bar button item.
        UIBarButtonItem *currentDetailBarButtonItem = oldDetailViewController.topViewController.navigationItem.leftBarButtonItem;

        // The new detail view controller's root view controller will be the top view controller when it's initially
        // pushed onto the detail navigation controller.
        newDetailViewController.topViewController.navigationItem.leftBarButtonItem = currentDetailBarButtonItem;
    }
}

@end
