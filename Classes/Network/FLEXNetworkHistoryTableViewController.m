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

@interface FLEXNetworkHistoryTableViewController () <UISearchResultsUpdating, UISearchControllerDelegate>

/// Backing model
@property (nonatomic, copy) NSArray *networkTransactions;
@property (nonatomic, assign) long long bytesReceived;
@property (nonatomic, copy) NSArray *filteredNetworkTransactions;
@property (nonatomic, assign) long long filteredBytesReceived;

@property (nonatomic, assign) BOOL rowInsertInProgress;
@property (nonatomic, assign) BOOL isPresentingSearch;

@property (nonatomic, strong) UISearchController *searchController;

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

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
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
    [self updateFirstSectionHeader];
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
    [self updateFirstSectionHeader];
}

- (void)updateFirstSectionHeader
{
    UIView *view = [self.tableView headerViewForSection:0];
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.text = [self headerText];
        [headerView setNeedsLayout];
    }
}

- (NSString *)headerText
{
    NSString *headerText = nil;
    if ([FLEXNetworkObserver isEnabled]) {
        long long bytesReceived = 0;
        NSInteger totalRequests = 0;
        if (self.searchController.isActive) {
            bytesReceived = self.filteredBytesReceived;
            totalRequests = [self.filteredNetworkTransactions count];
        } else {
            bytesReceived = self.bytesReceived;
            totalRequests = [self.networkTransactions count];
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
    
    if (self.searchController.isActive) {
        [self updateTransactions];
        [self updateSearchResults];
        return;
    }

    NSInteger existingRowCount = [self.networkTransactions count];
    [self updateTransactions];
    NSInteger newRowCount = [self.networkTransactions count];
    NSInteger addedRowCount = newRowCount - existingRowCount;

    if (addedRowCount != 0 && !self.isPresentingSearch) {
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
    }
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification
{
    [self updateBytesReceived];
    [self updateFilteredBytesReceived];

    FLEXNetworkTransaction *transaction = notification.userInfo[kFLEXNetworkRecorderUserInfoTransactionKey];

    // Update both the main table view and search table view if needed.
    for (FLEXNetworkTransactionTableViewCell *cell in [self.tableView visibleCells]) {
        if ([cell.transaction isEqual:transaction]) {
            // Using -[UITableView reloadRowsAtIndexPaths:withRowAnimation:] is overkill here and kicks off a lot of
            // work that can make the table view somewhat unresponseive when lots of updates are streaming in.
            // We just need to tell the cell that it needs to re-layout.
            [cell setNeedsLayout];
            break;
        }
    }
    [self updateFirstSectionHeader];
}

- (void)handleTransactionsClearedNotification:(NSNotification *)notification
{
    [self updateTransactions];
    [self.tableView reloadData];
}

- (void)handleNetworkObserverEnabledStateChangedNotification:(NSNotification *)notification
{
    // Update the header, which displays a warning when network debugging is disabled
    [self updateFirstSectionHeader];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? [self.filteredNetworkTransactions count] : [self.networkTransactions count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self headerText];
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
    return self.searchController.isActive ? self.filteredNetworkTransactions[indexPath.row] : self.networkTransactions[indexPath.row];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self updateSearchResults];
}

- (void)updateSearchResults
{
    NSString *searchString = self.searchController.searchBar.text;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *filteredNetworkTransactions = [self.networkTransactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXNetworkTransaction *transaction, NSDictionary *bindings) {
            return [[transaction.request.URL absoluteString] rangeOfString:searchString options:NSCaseInsensitiveSearch].length > 0;
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.searchController.searchBar.text isEqual:searchString]) {
                self.filteredNetworkTransactions = filteredNetworkTransactions;
                [self.tableView reloadData];
            }
        });
    });
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.isPresentingSearch = YES;
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    self.isPresentingSearch = NO;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    [self.tableView reloadData];
}

@end
