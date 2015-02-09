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

@interface FLEXNetworkHistoryTableViewController ()

/// Backing model
@property (nonatomic, copy) NSArray *networkTransactions;

@end

@implementation FLEXNetworkHistoryTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewTransactionRecordedNotification:) name:kFLEXNetworkRecorderNewTransactionNotification object:nil];
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

    [self updateTransactions];
}

- (void)updateTransactions
{
    self.networkTransactions = [[FLEXNetworkRecorder defaultRecorder] networkTransactions];
}

- (void)handleNewTransactionRecordedNotification:(NSNotification *)notification
{
    // Note that these notifications may be posted from a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTransactions];
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.networkTransactions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkTransactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXNetworkTransactionCellIdentifier forIndexPath:indexPath];
    cell.transaction = [self.networkTransactions objectAtIndex:indexPath.row];

    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }

    return cell;
}

@end
