//
//  FLEXNetworkHistoryTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXUtility.h"
#import "FLEXNetworkHistoryTableViewController.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXNetworkTransactionTableViewCell.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransactionDetailTableViewController.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkSettingsTableViewController.h"

@interface FLEXNetworkHistoryTableViewController ()

/// Backing model
@property (nonatomic, copy) NSArray<FLEXNetworkTransaction *> *networkTransactions;
@property (nonatomic) long long bytesReceived;
@property (nonatomic, copy) NSArray<FLEXNetworkTransaction *> *filteredNetworkTransactions;
@property (nonatomic) long long filteredBytesReceived;

@property (nonatomic) BOOL rowInsertInProgress;
@property (nonatomic) BOOL isPresentingSearch;

@end

@implementation FLEXNetworkHistoryTableViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleNewTransactionRecordedNotification:) name:kFLEXNetworkRecorderNewTransactionNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleTransactionUpdatedNotification:) name:kFLEXNetworkRecorderTransactionUpdatedNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleTransactionsClearedNotification:) name:kFLEXNetworkRecorderTransactionsClearedNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleNetworkObserverEnabledStateChangedNotification:) name:kFLEXNetworkObserverEnabledStateChangedNotification object:nil];
        self.title = @"📡  Network";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonTapped:)];

        // Needed to avoid search bar showing over detail pages pushed on the nav stack
        // see https://asciiwwdc.com/2014/sessions/228
        self.definesPresentationContext = YES;
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.showsSearchBar = YES;

    [self.tableView registerClass:[FLEXNetworkTransactionTableViewCell class] forCellReuseIdentifier:kFLEXNetworkTransactionCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = [FLEXNetworkTransactionTableViewCell preferredCellHeight];

    [self updateTransactions];
}

- (void)settingsButtonTapped:(id)sender
{
    FLEXNetworkSettingsTableViewController *settingsViewController = [FLEXNetworkSettingsTableViewController new];
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

- (void)setNetworkTransactions:(NSArray<FLEXNetworkTransaction *> *)networkTransactions
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

- (void)setFilteredNetworkTransactions:(NSArray<FLEXNetworkTransaction *> *)filteredNetworkTransactions
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
            totalRequests = self.filteredNetworkTransactions.count;
        } else {
            bytesReceived = self.bytesReceived;
            totalRequests = self.networkTransactions.count;
        }
        NSString *byteCountText = [NSByteCountFormatter stringFromByteCount:bytesReceived countStyle:NSByteCountFormatterCountStyleBinary];
        NSString *requestsText = totalRequests == 1 ? @"Request" : @"Requests";
        headerText = [NSString stringWithFormat:@"%ld %@ (%@ received)", (long)totalRequests, requestsText, byteCountText];
    } else {
        headerText = @"⚠️  Debugging Disabled (Enable in Settings)";
    }
    return headerText;
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"📡  Network History";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
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
        [self updateSearchResults:nil];
        return;
    }

    NSInteger existingRowCount = self.networkTransactions.count;
    [self updateTransactions];
    NSInteger newRowCount = self.networkTransactions.count;
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

            NSMutableArray<NSIndexPath *> *indexPathsToReload = [NSMutableArray array];
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
            // work that can make the table view somewhat unresponsive when lots of updates are streaming in.
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? self.filteredNetworkTransactions.count : self.networkTransactions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self headerText];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkTransactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXNetworkTransactionCellIdentifier forIndexPath:indexPath];
    cell.transaction = [self transactionAtIndexPath:indexPath];

    // Since we insert from the top, assign background colors bottom up to keep them consistent for each transaction.
    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [FLEXColor secondaryBackgroundColor];
    } else {
        cell.backgroundColor = [FLEXColor primaryBackgroundColor];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkTransactionDetailTableViewController *detailViewController = [FLEXNetworkTransactionDetailTableViewController new];
    detailViewController.transaction = [self transactionAtIndexPath:indexPath];
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
        NSURLRequest *request = [self transactionAtIndexPath:indexPath].request;
        UIPasteboard.generalPasteboard.string = request.URL.absoluteString ?: @"";
    }
}

#if FLEX_AT_LEAST_IOS13_SDK

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0)
{
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
        previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction
                actionWithTitle:@"Copy"
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    NSURLRequest *request = [self transactionAtIndexPath:indexPath].request;
                    UIPasteboard.generalPasteboard.string = request.URL.absoluteString ?: @"";
                }
            ];
            return [UIMenu
                menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline
                children:@[copy]
            ];
        }
    ];
}

#endif

- (FLEXNetworkTransaction *)transactionAtIndexPath:(NSIndexPath *)indexPath
{
    return self.searchController.isActive ? self.filteredNetworkTransactions[indexPath.row] : self.networkTransactions[indexPath.row];
}

#pragma mark - Search Bar

- (void)updateSearchResults:(NSString *)searchString
{
    [self onBackgroundQueue:^NSArray *{
        return [self.networkTransactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXNetworkTransaction *transaction, NSDictionary<NSString *, id> *bindings) {
            return [[transaction.request.URL absoluteString] rangeOfString:searchString options:NSCaseInsensitiveSearch].length > 0;
        }]];
    } thenOnMainQueue:^(NSArray *filteredNetworkTransactions) {
        if ([self.searchText isEqual:searchString]) {
            self.filteredNetworkTransactions = filteredNetworkTransactions;
            [self.tableView reloadData];
        }
    }];
}

#pragma mark UISearchControllerDelegate

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
