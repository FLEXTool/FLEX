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
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkSettingsTableViewController.h"

@interface FLEXNetworkHistoryTableViewController () <UISearchDisplayDelegate>

/// Backing model
@property (nonatomic, copy) NSArray *networkTransactions;
@property (nonatomic, assign) long long bytesReceived;
@property (nonatomic, copy) NSArray *filteredNetworkTransactions;
@property (nonatomic, assign) long long filteredBytesReceived;

@property (nonatomic, assign) BOOL rowInsertInProgress;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UISearchDisplayController *searchController;
#pragma clang diagnostic pop

@end

@implementation FLEXNetworkHistoryTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewTransactionRecordedNotification:) name:kFLEXNetworkRecorderNewTransactionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTransactionUpdatedNotification:) name:kFLEXNetworkRecorderTransactionUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTransactionsClearedNotification:) name:kFLEXNetworkRecorderTransactionsClearedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkObserverEnabledStateChangedNotification:) name:kFLEXNetworkObserverEnabledStateChangedNotification object:nil];
        self.title = @"📡  Network";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonTapped:)];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
#pragma clang diagnostic pop
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    [self.searchController.searchResultsTableView registerClass:[FLEXNetworkTransactionTableViewCell class] forCellReuseIdentifier:kFLEXNetworkTransactionCellIdentifier];
    self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchController.searchResultsTableView.rowHeight = [FLEXNetworkTransactionTableViewCell preferredCellHeight];
    self.tableView.tableHeaderView = self.searchController.searchBar;

    [self updateTransactions];
}

- (void)settingsButtonTapped:(id)sender
{
    FLEXNetworkSettingsTableViewController *settingsViewController = [[FLEXNetworkSettingsTableViewController alloc] init];
    settingsViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(settingsViewControllerDoneTapped:)];
    settingsViewController.title = @"Network Debugging Settings";
    UINavigationController *wrapperNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [self presentViewController:wrapperNavigationController animated:YES completion:nil];
}

- (void)settingsViewControllerDoneTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateTransactions
{
    self.networkTransactions = [[FLEXNetworkRecorder defaultRecorder] networkTransactions];
}

- (void)setNetworkTransactions:(NSArray *)networkTransactions
{
    if (![_networkTransactions isEqual:networkTransactions]) {
        _networkTransactions = networkTransactions;
        [self updateBytesReceived];
        [self updateFilteredBytesReceived];
    }
}

- (void)updateBytesReceived
{
    long long bytesReceived = 0;
    for (FLEXNetworkTransaction *transaction in self.networkTransactions) {
        bytesReceived += transaction.receivedDataLength;
    }
    self.bytesReceived = bytesReceived;
    [self updateFirstSectionHeaderInTableView:self.tableView];
}

- (void)setFilteredNetworkTransactions:(NSArray *)filteredNetworkTransactions
{
    if (![_filteredNetworkTransactions isEqual:filteredNetworkTransactions]) {
        _filteredNetworkTransactions = filteredNetworkTransactions;
        [self updateFilteredBytesReceived];
    }
}

- (void)updateFilteredBytesReceived
{
    long long filteredBytesReceived = 0;
    for (FLEXNetworkTransaction *transaction in self.filteredNetworkTransactions) {
        filteredBytesReceived += transaction.receivedDataLength;
    }
    self.filteredBytesReceived = filteredBytesReceived;
    [self updateFirstSectionHeaderInTableView:self.searchController.searchResultsTableView];
}

- (void)updateFirstSectionHeaderInTableView:(UITableView *)tableView
{
    UIView *view = [tableView headerViewForSection:0];
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.text = [self headerTextForTableView:tableView];
        [headerView setNeedsLayout];
    }
}

- (NSString *)headerTextForTableView:(UITableView *)tableView
{
    NSString *headerText = nil;
    if ([FLEXNetworkObserver isEnabled]) {
        long long bytesReceived = 0;
        NSInteger totalRequests = 0;
        if (tableView == self.tableView) {
            bytesReceived = self.bytesReceived;
            totalRequests = [self.networkTransactions count];
        } else if (tableView == self.searchController.searchResultsTableView) {
            bytesReceived = self.filteredBytesReceived;
            totalRequests = [self.filteredNetworkTransactions count];
        }
        NSString *byteCountText = [NSByteCountFormatter stringFromByteCount:bytesReceived countStyle:NSByteCountFormatterCountStyleBinary];
        NSString *requestsText = totalRequests == 1 ? @"Request" : @"Requests";
        headerText = [NSString stringWithFormat:@"%ld %@ (%@ received)", (long)totalRequests, requestsText, byteCountText];
    } else {
        headerText = @"⚠️  Debugging Disabled (Enable in Settings)";
    }
    return headerText;
}

#pragma mark - Notification Handlers

- (void)handleNewTransactionRecordedNotification:(NSNotification *)notification
{
    [self tryUpdateTransactions];
}

- (void)tryUpdateTransactions
{
    // Let the previous row insert animation finish before starting a new one to avoid stomping.
    // We'll try calling the method again when the insertion completes, and we properly no-op if there haven't been changes.
    if (self.rowInsertInProgress) {
        return;
    }

    NSInteger existingRowCount = [self.networkTransactions count];
    [self updateTransactions];
    NSInteger newRowCount = [self.networkTransactions count];
    NSInteger addedRowCount = newRowCount - existingRowCount;

    if (addedRowCount != 0) {
        // Insert animation if we're at the top.
        if (self.tableView.contentOffset.y <= 0.0 && addedRowCount > 0) {
            [CATransaction begin];
            
            self.rowInsertInProgress = YES;
            [CATransaction setCompletionBlock:^{
                self.rowInsertInProgress = NO;
                [self tryUpdateTransactions];
            }];

            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            for (NSInteger row = 0; row < addedRowCount; row++) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            [self.tableView insertRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];

            [CATransaction commit];
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
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification
{
    [self updateBytesReceived];
    [self updateFilteredBytesReceived];

    FLEXNetworkTransaction *transaction = [notification.userInfo objectForKey:kFLEXNetworkRecorderUserInfoTransactionKey];
    NSArray *tableViews = @[self.tableView];
    if (self.searchController.searchResultsTableView) {
        tableViews = [tableViews arrayByAddingObject:self.searchController.searchResultsTableView];
    }

    // Update both the main table view and search table view if needed.
    for (UITableView *tableView in tableViews) {
        for (FLEXNetworkTransactionTableViewCell *cell in [tableView visibleCells]) {
            if ([cell.transaction isEqual:transaction]) {
                // Using -[UITableView reloadRowsAtIndexPaths:withRowAnimation:] is overkill here and kicks off a lot of
                // work that can make the table view somewhat unresponseive when lots of updates are streaming in.
                // We just need to tell the cell that it needs to re-layout.
                [cell setNeedsLayout];
                break;
            }
        }
        [self updateFirstSectionHeaderInTableView:tableView];
    }
}

- (void)handleTransactionsClearedNotification:(NSNotification *)notification
{
    [self updateTransactions];
    [self.tableView reloadData];
    [self.searchController.searchResultsTableView reloadData];
}

- (void)handleNetworkObserverEnabledStateChangedNotification:(NSNotification *)notification
{
    // Update the header, which displays a warning when network debugging is disabled
    [self updateFirstSectionHeaderInTableView:self.tableView];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self headerTextForTableView:tableView];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0];
        headerView.textLabel.textColor = [UIColor whiteColor];
        headerView.contentView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    }
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

#pragma mark - Menu Actions

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        FLEXNetworkTransaction *transaction = [self transactionAtIndexPath:indexPath inTableView:tableView];
        NSString *requestURLString = transaction.request.URL.absoluteString ?: @"";
        [[UIPasteboard generalPasteboard] setString:requestURLString];
    }
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
            if ([self.searchController.searchBar.text isEqual:searchString]) {
                self.filteredNetworkTransactions = filteredNetworkTransactions;
                [self.searchController.searchResultsTableView reloadData];
            }
        });
    });
}

@end
