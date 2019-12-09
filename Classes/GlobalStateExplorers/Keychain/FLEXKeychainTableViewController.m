//
//  FLEXKeychainTableViewController.m
//  FLEX
//
//  Created by ray on 2019/8/17.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXKeychain.h"
#import "FLEXKeychainQuery.h"
#import "FLEXKeychainTableViewController.h"
#import "FLEXUtility.h"
#import "UIPasteboard+FLEX.h"

@interface FLEXKeychainTableViewController ()

@property (nonatomic) NSMutableArray<NSDictionary *> *keychainItems;
@property (nonatomic) NSString *headerTitle;

@end

@implementation FLEXKeychainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashPressed)
        ],
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)
        ],
    ];

    [self refreshkeychainItems];
    [self updateHeaderTitle];
}

- (void)refreshkeychainItems
{
    self.keychainItems = [FLEXKeychain allAccounts].mutableCopy;
}

- (void)updateHeaderTitle
{
    self.headerTitle = [NSString stringWithFormat:@"%@ items", @(self.keychainItems.count)];
}

- (FLEXKeychainQuery *)queryForItemAtIndex:(NSInteger)idx
{
    NSDictionary *item = self.keychainItems[idx];

    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = item[kFLEXKeychainWhereKey];
    query.account = item[kFLEXKeychainAccountKey];
    [query fetch:nil];

    return query;
}

- (void)deleteItem:(NSDictionary *)item
{
    NSError *error = nil;
    BOOL success = [FLEXKeychain
        deletePasswordForService:item[kFLEXKeychainWhereKey]
        account:item[kFLEXKeychainAccountKey]
        error:&error
    ];

    if (!success) {
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(@"Error Deleting Item");
            make.message(error.localizedDescription);
        } showFrom:self];
    }
}


#pragma mark Buttons

- (void)trashPressed
{
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.title(@"Clear Keychain");
        make.message(@"This will remove all keychain items for this app.\n");
        make.message(@"This action cannot be undone. Are you sure?");
        make.button(@"Yes, clear the keychain").destructiveStyle().handler(^(NSArray *strings) {
            for (id account in self.keychainItems) {
                [self deleteItem:account];
            }

            [self refreshkeychainItems];
            [self.tableView reloadData];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}

- (void)addPressed
{
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Add Keychain Item");
        make.textField(@"Service name, i.e. Instagram");
        make.textField(@"Account, i.e. username@example.com");
        make.textField(@"Password");
        make.button(@"Cancel").cancelStyle();
        make.button(@"Save").handler(^(NSArray<NSString *> *strings) {
            // Display errors
            NSError *error = nil;
            if (![FLEXKeychain setPassword:strings[2] forService:strings[0] account:strings[1] error:&error]) {
                [FLEXAlert showAlert:@"Error" message:error.localizedDescription from:self];
            }

            [self refreshkeychainItems];
            [self.tableView reloadData];
        });
    } showFrom:self];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row
{
    return @"🔑  Keychain";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    FLEXKeychainTableViewController *viewController = [self new];
    viewController.title = [self globalsEntryTitle:row];

    return viewController;
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.keychainItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
    }
    
    NSDictionary *item = self.keychainItems[indexPath.row];
    id account = item[kFLEXKeychainAccountKey];
    if ([account isKindOfClass:[NSString class]]) {
        cell.textLabel.text = account;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:
            @"[%@]\n\n%@",
            NSStringFromClass([account class]),
            [account description]
        ];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.headerTitle;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style == UITableViewCellEditingStyleDelete) {
        [self deleteItem:self.keychainItems[ip.row]];
        [self.keychainItems removeObjectAtIndex:ip.row];
        [tv deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXKeychainQuery *query = [self queryForItemAtIndex:indexPath.row];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(query.service);
        make.message(@"Service: ").message(query.service);
        make.message(@"\nAccount: ").message(query.account);
        make.message(@"\nPassword: ").message(query.password);

        make.button(@"Copy Service").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.service];
        });
        make.button(@"Copy Account").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.account];
        });
        make.button(@"Copy Password").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.password];
        });
        make.button(@"Dismiss").cancelStyle();
        
    } showFrom:self];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
