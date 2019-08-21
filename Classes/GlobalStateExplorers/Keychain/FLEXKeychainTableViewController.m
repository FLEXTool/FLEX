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

@interface FLEXKeychainTableViewController ()

@property (nonatomic) NSArray<NSDictionary *> *keyChainItems;

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

    [self refreshKeychainItems];
}

- (void)refreshKeychainItems
{
    self.keyChainItems = [FLEXKeychain allAccounts];
    self.title = [NSString stringWithFormat:@"🔑 Keychain Items (%lu)", (unsigned long)self.keyChainItems.count];
}

#pragma mark Buttons

- (void)trashPressed
{
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.title(@"Clear Keychain");
        make.message(@"This will remove all keychain items for this app.\n");
        make.message(@"This action cannot be undone. Are you sure?");
        make.button(@"Yes, clear the keychain").destructiveStyle().handler(^(NSArray *strings) {
            for (id account in self.keyChainItems) {
                FLEXKeychainQuery *query = [FLEXKeychainQuery new];
                query.service = account[kFLEXKeychainWhereKey];
                query.account = account[kFLEXKeychainAccountKey];

                // Delete item or display error
                NSError *error = nil;
                if (![query deleteItem:&error]) {
                    [FLEXAlert makeAlert:^(FLEXAlert *make) {
                        make.title(@"Error Deleting Item");
                        make.message(error.localizedDescription);
                    } showFrom:self];
                }
            }

            [self refreshKeychainItems];
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

            [self refreshKeychainItems];
            [self.tableView reloadData];
        });
    } showFrom:self];
}



#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row
{
    return @"🔑  Keychain";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row
{
    return [self new];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.keyChainItems.count;
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
    
    NSDictionary *item = self.keyChainItems[indexPath.row];
    cell.textLabel.text = item[kFLEXKeychainAccountKey];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.keyChainItems[indexPath.row];
    
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = item[kFLEXKeychainWhereKey];
    query.account = item[kFLEXKeychainAccountKey];
    [query fetch:nil];

    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(query.service);
        make.message(@"Service: ").message(query.service);
        make.message(@"\nAccount: ").message(query.account);
        make.message(@"\nPassword: ").message(query.password);

        make.button(@"Copy Service").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.service;
        });
        make.button(@"Copy Account").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.account;
        });
        make.button(@"Copy Password").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.password;
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

@end
