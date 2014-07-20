/*
        File: AAPLActionSheetViewController.m
    Abstract: A view controller that demonstrates how to use UIActionSheet.
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

#import "AAPLActionSheetViewController.h"

// Corresponds to the row in the action sheet section.
typedef NS_ENUM(NSInteger, AAPLActionSheetsViewControllerTableRow) {
    AAPLAlertsViewControllerActionSheetRowOkayCancel = 0,
    AAPLAlertsViewControllerActionSheetRowOther
};


@interface AAPLActionSheetViewController() <UIActionSheetDelegate>
@end


#pragma mark -

@implementation AAPLActionSheetViewController

// Show a dialog with an "Okay" and "Cancel" button.
- (void)showOkayCancelActionSheet {
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveButtonTitle = NSLocalizedString(@"OK", nil);
    
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:nil];
    
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    
	[actionSheet showInView:self.view];
}

// Show a dialog with two custom buttons.
- (void)showOtherActionSheet {
    NSString *destructiveButtonTitle = NSLocalizedString(@"Destructive Choice", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"Safe Choice", nil);

	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitle, nil];
    
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    
	[actionSheet showInView:self.view];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.destructiveButtonIndex == buttonIndex) {
        NSLog(@"Action sheet clicked with the destructive button index.");
    }
    else if (actionSheet.cancelButtonIndex == buttonIndex) {
        NSLog(@"Action sheet clicked with the cancel button index.");
    }
    else {
        NSLog(@"Action sheet clicked with button at index %ld.", (long)buttonIndex);
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLActionSheetsViewControllerTableRow row = indexPath.row;

    switch (row) {
        case AAPLAlertsViewControllerActionSheetRowOkayCancel:
            [self showOkayCancelActionSheet];
            break;
        case AAPLAlertsViewControllerActionSheetRowOther:
            [self showOtherActionSheet];
            break;
        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
