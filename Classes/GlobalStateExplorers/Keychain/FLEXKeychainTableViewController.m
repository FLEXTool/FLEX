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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearKeychain)];
    
    self.keyChainItems = [FLEXKeychain allAccounts];
    self.title = [NSString stringWithFormat:@"🔑 Keychain Items (%lu)", (unsigned long)self.keyChainItems.count];
}

- (void)clearKeychain
{
    
    for (id account in self.keyChainItems) {
        FLEXKeychainQuery *query = [FLEXKeychainQuery new];
        query.service = account[kFLEXKeychainWhereKey];
        query.account = account[kFLEXKeychainAccountKey];
        
        if (![query deleteItem:nil]) {
            NSLog(@"Delete Keychin Item Failed.");
        }
    }
    
    self.keyChainItems = [FLEXKeychain allAccounts];
    [self.tableView reloadData];
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
    query.service = [item valueForKey:kFLEXKeychainWhereKey];
    query.account = [item valueForKey:kFLEXKeychainAccountKey];
    [query fetch:nil];
    
    NSString *msg = nil;
    
    if (query.password.length) {
        msg = query.password;
    } else if (query.passwordData.length) {
        msg = query.passwordData.description;
    } else {
        msg = @"No data";
    }
    
    UIAlertController *cv = [UIAlertController alertControllerWithTitle:@"Password" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [cv addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [cv dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [cv addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = msg;
    }]];
    
    [self presentViewController:cv animated:YES completion:nil];
}

@end
