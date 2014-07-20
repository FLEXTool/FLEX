/*
        File: AAPLAlertViewController.m
    Abstract: The view controller that demonstrates how to use UIAlertView.
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

#import "AAPLAlertViewController.h"

// Corresponds to the row in the alert view section.
typedef NS_ENUM(NSInteger, AAPLAlertsViewControllerTableRow) {
    AAPLAlertsViewControllerAlertViewRowSimple = 0,
    AAPLAlertsViewControllerAlertViewRowOkayCancel,
    AAPLAlertsViewControllerAlertViewRowOther,
    AAPLAlertsViewControllerAlertViewRowTextEntry,
    AAPLAlertsViewControllerActionSheetRowTextEntrySecure
};


@interface AAPLAlertViewController() <UIAlertViewDelegate>
@end


#pragma mark -

@implementation AAPLAlertViewController

// Show an alert with an "Okay" button.
- (void)showSimpleAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"OK", nil);

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];

	[alert show];
}

// Show an alert with an "Okay" and "Cancel" button.
- (void)showOkayCancelAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];

	[alert show];
}

// Show an alert with two custom buttons.
- (void)showOtherAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitleOne = NSLocalizedString(@"Choice One", nil);
    NSString *otherButtonTitleTwo = NSLocalizedString(@"Choice Two", nil);

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitleOne, otherButtonTitleTwo, nil];

	[alert show];
}

// Show a text entry alert with two custom buttons.
- (void)showTextEntryAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert show];
}

// Show a secure text entry alert with two custom buttons.
- (void)showSecureTextEntryAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];

	alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    
    [alert show];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex == buttonIndex) {
        NSLog(@"Alert view clicked with the cancel button index.");
    }
    else {
        NSLog(@"Alert view clicked with button at index %ld.", (long)buttonIndex);
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    // Enforce a minimum length of >= 5 characters for secure text alert views.
    if (alertView.alertViewStyle == UIAlertViewStyleSecureTextInput) {
        return [[alertView textFieldAtIndex:0].text length] >= 5;
    }

    return YES;
}


#pragma mark - UITableViewDelegate

// Determine the action to perform based on the selected cell.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLAlertsViewControllerTableRow row = indexPath.row;

    switch (row) {
        case AAPLAlertsViewControllerAlertViewRowSimple:
            [self showSimpleAlert];
            break;
        case AAPLAlertsViewControllerAlertViewRowOkayCancel:
            [self showOkayCancelAlert];
            break;
        case AAPLAlertsViewControllerAlertViewRowOther:
            [self showOtherAlert];
            break;
        case AAPLAlertsViewControllerAlertViewRowTextEntry:
            [self showTextEntryAlert];
            break;
        case AAPLAlertsViewControllerActionSheetRowTextEntrySecure:
            [self showSecureTextEntryAlert];
            break;
        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
