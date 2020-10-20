//
//  FLEXAddressExplorerCoordinator.m
//  FLEX
//
//  Created by Tanner Bennett on 7/10/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"

@interface UITableViewController (FLEXAddressExploration)
- (void)deselectSelectedRow;
- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely;
@end

@implementation FLEXAddressExplorerCoordinator

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"🔎  Address Explorer";
}

+ (FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row {
    return ^(UITableViewController *host) {

        NSString *title = @"Explore Object at Address";
        NSString *message = @"Paste a hexadecimal address below, starting with '0x'. "
        "Use the unsafe option if you need to bypass pointer validation, "
        "but know that it may crash the app if the address is invalid.";

        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(title).message(message);
            make.configuredTextField(^(UITextField *textField) {
                NSString *copied = UIPasteboard.generalPasteboard.string;
                textField.placeholder = @"0x00000070deadbeef";
                // Go ahead and paste our clipboard if we have an address copied
                if ([copied hasPrefix:@"0x"]) {
                    textField.text = copied;
                    [textField selectAll:nil];
                }
            });
            make.button(@"Explore").handler(^(NSArray<NSString *> *strings) {
                [host tryExploreAddress:strings.firstObject safely:YES];
            });
            make.button(@"Unsafe Explore").destructiveStyle().handler(^(NSArray *strings) {
                [host tryExploreAddress:strings.firstObject safely:NO];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:host];

    };
}

@end

@implementation UITableViewController (FLEXAddressExploration)

- (void)deselectSelectedRow {
    NSIndexPath *selected = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:selected animated:YES];
}

- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely {
    NSScanner *scanner = [NSScanner scannerWithString:addressString];
    unsigned long long hexValue = 0;
    BOOL didParseAddress = [scanner scanHexLongLong:&hexValue];
    const void *pointerValue = (void *)hexValue;

    NSString *error = nil;

    if (didParseAddress) {
        if (safely && ![FLEXRuntimeUtility pointerIsValidObjcObject:pointerValue]) {
            error = @"The given address is unlikely to be a valid object.";
        }
    } else {
        error = @"Malformed address. Make sure it's not too long and starts with '0x'.";
    }

    if (!error) {
        id object = (__bridge id)pointerValue;
        FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
        [self.navigationController pushViewController:explorer animated:YES];
    } else {
        [FLEXAlert showAlert:@"Uh-oh" message:error from:self];
        [self deselectSelectedRow];
    }
}

@end
