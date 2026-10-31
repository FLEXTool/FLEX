//
//  FLEXMacKeychainViewController.m
//  FLEX (macOS)
//

#import "FLEXMacKeychainViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacUtility.h"
#import "FLEXKeychain.h"

@implementation FLEXMacKeychainViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Keychain";
        self.showsRefreshButton = YES;
        self.emptyText = @"No keychain items";
    }
    return self;
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    return @[FLEXMacBarButton(@"plus", @"Add", @"Add a generic password item", self, @selector(addItem:))];
}

- (void)addItem:(id)sender {
    [FLEXMacUtility promptWithTitle:@"Add Keychain Item" message:@"Enter service, account and password separated by newlines or '|'" defaultValue:@"service|account|password" completion:^(NSString *text) {
        NSArray<NSString *> *parts = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"|\n"]];
        if (parts.count != 3) {
            if (text) [FLEXMacUtility showAlertWithTitle:@"Invalid Input" message:@"Expected service|account|password"];
            return;
        }
        NSError *error = nil;
        if (![FLEXKeychain setPassword:parts[2] forService:parts[0] account:parts[1] error:&error]) {
            [FLEXMacUtility showError:error];
        }
        [self reloadData];
    }];
}

- (NSArray<FLEXMacSection *> *)makeSections {
    NSError *error = nil;
    NSArray<NSDictionary *> *accounts = [FLEXKeychain allAccounts:&error];
    if (error && error.code != errSecItemNotFound) {
        self.emptyText = error.localizedDescription;
    }

    NSMutableArray *rows = [NSMutableArray new];
    for (NSDictionary *item in accounts) {
        NSString *account = item[kFLEXKeychainAccountKey];
        NSString *service = item[kFLEXKeychainWhereKey];
        if (![account isKindOfClass:[NSString class]]) account = [account description];
        if (![service isKindOfClass:[NSString class]]) service = [service description];

        FLEXMacRow *row = [FLEXMacRow title:account.length ? account : @"(no account)" subtitle:service];
        row.action = ^(NSViewController *host) {
            NSError *readError = nil;
            NSString *password = [FLEXKeychain passwordForService:service account:account error:&readError];
            if (readError) {
                [FLEXMacUtility showError:readError];
            } else {
                [host flex_push:[FLEXMacTextViewController viewerWithText:password ?: @"" title:account]];
            }
        };
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[
                FLEXMacMenuItem(@"Copy Password", ^{
                    [FLEXMacUtility copyToPasteboard:[FLEXKeychain passwordForService:service account:account]];
                }),
                FLEXMacMenuItem(@"Explore Attributes", ^{
                    [host flex_push:[FLEXMacObjectExplorerViewController explorerForObject:item]];
                }),
                FLEXMacMenuItem(@"Delete…", ^{
                    [FLEXMacUtility confirmWithTitle:@"Delete Keychain Item?" message:[NSString stringWithFormat:@"%@ — %@", service, account] actionTitle:@"Delete" destructive:YES completion:^{
                        NSError *deleteError = nil;
                        if (![FLEXKeychain deletePasswordForService:service account:account error:&deleteError]) {
                            [FLEXMacUtility showError:deleteError];
                        }
                        [(FLEXMacTableViewController *)host reloadData];
                    }];
                }),
            ];
        };
        [rows addObject:row];
    }

    NSString *title = [NSString stringWithFormat:@"%lu items — double-click to reveal a password (macOS may ask for permission)", (unsigned long)rows.count];
    return @[[FLEXMacSection title:title rows:rows]];
}

@end
