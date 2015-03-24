//
//  FLEXFileBrowserFileOperationController.m
//  Flipboard
//
//  Created by Daniel Rodriguez Troitino on 2/13/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXFileBrowserFileOperationController.h"
#import <UIKit/UIKit.h>

@interface FLEXFileBrowserFileDeleteOperationController () <UIAlertViewDelegate>

@property (nonatomic, copy, readonly) NSString *path;

@end

@implementation FLEXFileBrowserFileDeleteOperationController

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }

    return self;
}

- (void)show
{
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];

    if (stillExists) {
        UIAlertView *deleteWarning = [[UIAlertView alloc]
                                      initWithTitle:[NSString stringWithFormat:@"Delete %@?", self.path.lastPathComponent]
                                      message:[NSString stringWithFormat:@"The %@ will be deleted. This operation cannot be undone", isDirectory ? @"directory" : @"file"]
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Delete", nil];
        [deleteWarning show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        // Nothing, just cancel
    } else if (buttonIndex == alertView.firstOtherButtonIndex) {
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:NULL];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.delegate fileOperationControllerDidDismiss:self];
}

@end

@interface FLEXFileBrowserFileRenameOperationController () <UIAlertViewDelegate>

@property (nonatomic, copy, readonly) NSString *path;

@end

@implementation FLEXFileBrowserFileRenameOperationController

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }

    return self;
}

- (void)show
{
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];

    if (stillExists) {
        UIAlertView *renameDialog = [[UIAlertView alloc]
                                     initWithTitle:[NSString stringWithFormat:@"Rename %@?", self.path.lastPathComponent]
                                     message:nil
                                     delegate:self
                                     cancelButtonTitle:@"Cancel"
                                     otherButtonTitles:@"Rename", nil];
        renameDialog.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [renameDialog textFieldAtIndex:0];
        textField.placeholder = @"New file name";
        textField.text = self.path.lastPathComponent;
        [renameDialog show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        // Nothing, just cancel
    } else if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *newFileName = [alertView textFieldAtIndex:0].text;
        NSString *newPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:newPath error:NULL];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.delegate fileOperationControllerDidDismiss:self];
}

@end
