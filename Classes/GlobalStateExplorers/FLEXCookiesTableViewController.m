//
//  FLEXCookiesTableViewController.m
//  FLEX
//
//  Created by Rich Robinson on 19/10/2015.
//  Copyright © 2015 Flipboard. All rights reserved.
//

#import "FLEXCookiesTableViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXUtility.h"

@interface FLEXCookiesTableViewController ()
@property (nonatomic, readonly) NSArray<NSHTTPCookie *> *cookies;
@property (nonatomic) NSString *headerTitle;
@end

@implementation FLEXCookiesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc]
        initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)
    ];
    _cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies
        sortedArrayUsingDescriptors:@[nameSortDescriptor]
    ];

    self.title = @"Cookies";
    [self updateHeaderTitle];
}

- (void)updateHeaderTitle {
    self.headerTitle = [NSString stringWithFormat:@"%@ cookies", @(self.cookies.count)];
    // TODO update header title here when we can search cookies
}

- (NSHTTPCookie *)cookieForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cookies[indexPath.row];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cookies.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.textColor = UIColor.grayColor;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSHTTPCookie *cookie = [self cookieForRowAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", cookie.name, cookie.value];
    cell.detailTextLabel.text = cookie.domain;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.headerTitle;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSHTTPCookie *cookie = [self cookieForRowAtIndexPath:indexPath];
    UIViewController *cookieViewController = (UIViewController *)[FLEXObjectExplorerFactory explorerViewControllerForObject:cookie];
    
    [self.navigationController pushViewController:cookieViewController animated:YES];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"🍪  Cookies";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}

@end
