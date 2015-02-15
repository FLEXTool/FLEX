//
//  FLEXNetworkHistoryTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXNetworkHistoryTableViewController.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXNetworkTransactionTableViewCell.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransactionDetailTableViewController.h"

@interface FLEXNetworkHistoryTableViewController () <UISearchDisplayDelegate>

/// Backing model
@property (nonatomic, copy) NSArray *networkTransactions;
@property (nonatomic, copy) NSArray *filteredNetworkTransactions;

@property (nonatomic, strong) UISearchDisplayController *searchController;

@end

@implementation FLEXNetworkHistoryTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewTransactionRecordedNotification:) name:kFLEXNetworkRecorderNewTransactionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTransactionUpdatedNotification:) name:kFLEXNetworkRecorderTransactionUpdatedNotification object:nil];
        self.title = @"📡  Network";
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[FLEXNetworkTransactionTableViewCell class] forCellReuseIdentifier:kFLEXNetworkTransactionCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = [FLEXNetworkTransactionTableViewCell preferredCellHeight];

    UISearchBar *searchBar = [[UISearchBar alloc] init];
    [searchBar sizeToFit];
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    [self.searchController.searchResultsTableView registerClass:[FLEXNetworkTransactionTableViewCell class] forCellReuseIdentifier:kFLEXNetworkTransactionCellIdentifier];
    self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchController.searchResultsTableView.rowHeight = [FLEXNetworkTransactionTableViewCell preferredCellHeight];
    self.tableView.tableHeaderView = self.searchController.searchBar;

    [self updateTransactions];
}

- (void)updateTransactions
{
    self.networkTransactions = [[FLEXNetworkRecorder defaultRecorder] networkTransactions];
}

- (void)handleNewTransactionRecordedNotification:(NSNotification *)notification
{
    NSInteger existingRowCount = [self.networkTransactions count];
    [self updateTransactions];
    NSInteger newRowCount = [self.networkTransactions count];
    NSInteger addedRowCount = newRowCount - existingRowCount;

    if (self.tableView.contentOffset.y <= 0.0 && addedRowCount > 0) {
        // Insert animation if we're at the top.
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        for (NSInteger row = 0; row < addedRowCount; row++) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        // Maintain the user's position if they've scrolled down.
        CGSize existingContentSize = self.tableView.contentSize;
        [self.tableView reloadData];
        CGFloat contentHeightChange = self.tableView.contentSize.height - existingContentSize.height;
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + contentHeightChange);
    }

    if (self.searchController.isActive) {
        [self updateSearchResultsWithSearchString:self.searchController.searchBar.text];
    }
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification
{
    FLEXNetworkTransaction *transaction = [notification.userInfo objectForKey:kFLEXNetworkRecorderUserInfoTransactionKey];
    UITableView *activeTableView = self.searchController.isActive ? self.searchController.searchResultsTableView : self.tableView;
    for (FLEXNetworkTransactionTableViewCell *cell in [activeTableView visibleCells]) {
        if ([cell.transaction isEqual:transaction]) {
            NSIndexPath *indexPath = [activeTableView indexPathForCell:cell];
            if (indexPath) {
                [activeTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (tableView == self.tableView) {
        numberOfRows = [self.networkTransactions count];
    } else if (tableView == self.searchController.searchResultsTableView) {
        numberOfRows = [self.filteredNetworkTransactions count];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkTransactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXNetworkTransactionCellIdentifier forIndexPath:indexPath];
    cell.transaction = [self transactionAtIndexPath:indexPath inTableView:tableView];

    // Since we insert from the top, assign background colors bottom up to keep them consistent for each transaction.
    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkTransactionDetailTableViewController *detailViewController = [[FLEXNetworkTransactionDetailTableViewController alloc] init];
    detailViewController.transaction = [self transactionAtIndexPath:indexPath inTableView:tableView];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (FLEXNetworkTransaction *)transactionAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    FLEXNetworkTransaction *transaction = nil;
    if (tableView == self.tableView) {
        transaction = [self.networkTransactions objectAtIndex:indexPath.row];
    } else if (tableView == self.searchController.searchResultsTableView) {
        transaction = [self.filteredNetworkTransactions objectAtIndex:indexPath.row];
    }
    return transaction;
}

#pragma mark - Search display delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self updateSearchResultsWithSearchString:searchString];

    // Reload done after the data is filtered asynchronously
    return NO;
}

- (void)updateSearchResultsWithSearchString:(NSString *)searchString
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *filteredNetworkTransactions = [self.networkTransactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXNetworkTransaction *transaction, NSDictionary *bindings) {
            return [[transaction.request.URL absoluteString] rangeOfString:searchString options:NSCaseInsensitiveSearch].length > 0;
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.searchDisplayController.searchBar.text isEqual:searchString]) {
                self.filteredNetworkTransactions = filteredNetworkTransactions;
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        });
    });
}

@end
