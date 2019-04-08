//
//  FLEXAddressInspectorViewController.m
//  FLEX
//
//  Created by Alexander Leontev on 08/04/2019.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXAddressInspectorViewController.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXAddressInspectorViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation FLEXAddressInspectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"Memory address";
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    
    self.title = @"Address Inspector";
    
    self.tableView.tableHeaderView = self.searchBar;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.tableView reloadData];
}

- (void)openInstanceInspectorForAddress:(NSString *)address {
    
    NSScanner *scanner = [NSScanner scannerWithString:address];
    
    unsigned long long objectPointerValue = 0;
    BOOL didParseAddress = [scanner scanHexLongLong:&objectPointerValue];
    
    const void *objectPointer = (const void *)objectPointerValue;
    
    if (didParseAddress) {
        id object = (__bridge id)objectPointer;
        
        FLEXObjectExplorerViewController *drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
        [self.navigationController pushViewController:drillInViewController animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        cell.textLabel.font = cellFont;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.font = cellFont;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = @"WARNING! Inspecting incorrect address will crash the application";
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Inspect %@", self.searchBar.text];
    
    return cell;
    
}

- (BOOL)isAddressValid {
    
    return [self.searchBar.text rangeOfString:@"^0[xX][0-9a-fA-F]+$" options:NSRegularExpressionSearch].location != NSNotFound;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 48.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self isAddressValid];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self openInstanceInspectorForAddress:self.searchBar.text];
}


@end
