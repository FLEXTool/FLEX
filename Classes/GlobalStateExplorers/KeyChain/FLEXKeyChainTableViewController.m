//
//  FLEXKeyChainTableViewController.m
//  FLEX
//
//  Created by ray on 2019/8/17.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXKeychain.h"
#import "FLEXKeychainQuery.h"
#import "FLEXKeyChainTableViewController.h"
#import "FLEXUtility.h"

@interface FLEXKeyChainTableViewController ()

@property (nonatomic) NSArray<NSDictionary *> *keyChainItems;

@end

@implementation FLEXKeyChainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearKeyChain)];

    
    _keyChainItems = [FLEXKeychain allAccounts];
    self.title = [NSString stringWithFormat:@"🔑 KeyChains (%lu)", (unsigned long)self.keyChainItems.count];
}

- (void)clearKeyChain
{
    
    for (id account in _keyChainItems) {

        FLEXKeychainQuery *query = [[FLEXKeychainQuery alloc] init];

        query.service = [account valueForKey:kSSKeychainWhereKey];
        query.account = [account valueForKey:kSSKeychainAccountKey];
        
        if(![query deleteItem:nil]) {
            NSLog(@"Delete Keychin Item Failed.");
        }
    }
    
    _keyChainItems = [FLEXKeychain allAccounts];
    [self.tableView reloadData];
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row
{
    return [NSString stringWithFormat:@"🔑  %@ KeyChain", [FLEXUtility applicationName]];
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row
{
    FLEXKeyChainTableViewController *keyChainViewController = [self new];
    
    return keyChainViewController;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

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
    cell.textLabel.text = item[kSSKeychainAccountKey];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.keyChainItems[indexPath.row];
    
    FLEXKeychainQuery *query = [[FLEXKeychainQuery alloc] init];
    query.service = [item valueForKey:kSSKeychainWhereKey];
    query.account = [item valueForKey:kSSKeychainAccountKey];
    [query fetch:nil];
    
    NSString *msg = nil;
    
    if ([query.password length])
    {
        msg = query.password;
    }
    
    else if ([query.passwordData length])
    {
        msg = [query.passwordData description];
    }
    
    else
    {
        msg = @"NO Data!";
    }
    
    UIAlertController *cv = [UIAlertController alertControllerWithTitle:@"Password" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [cv addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [cv dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [cv addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = msg;
    }]];
    
    [self presentViewController:cv animated:YES completion:nil];
}

@end
