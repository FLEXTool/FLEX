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

@property (nonatomic, strong) NSArray *cookies;

@end

@implementation FLEXCookiesTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    
    if (self) {
        self.title = @"Cookies";

        NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        _cookies =[[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies sortedArrayUsingDescriptors:@[nameSortDescriptor]];
    }
    
    return self;
}

- (NSHTTPCookie *)cookieForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cookies[indexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSHTTPCookie *cookie = [self cookieForRowAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", cookie.name, cookie.value];
    cell.detailTextLabel.text = cookie.domain;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSHTTPCookie *cookie = [self cookieForRowAtIndexPath:indexPath];
    UIViewController *cookieViewController = (UIViewController *)[FLEXObjectExplorerFactory explorerViewControllerForObject:cookie];
    
    [self.navigationController pushViewController:cookieViewController animated:YES];
}

@end
