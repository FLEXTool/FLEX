//
//  FLEXSystemLogTableViewController.m
//  FLEX
//
//  Created by Ryan Olson on 1/19/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXSystemLogTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXASLLogController.h"
#import "FLEXOSLogController.h"
#import "FLEXSystemLogTableViewCell.h"

@interface FLEXSystemLogTableViewController () <UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, readonly) id<FLEXLogController> logController;
@property (nonatomic, readonly) NSMutableArray<FLEXSystemLogMessage *> *logMessages;
@property (nonatomic, copy) NSArray<FLEXSystemLogMessage *> *filteredLogMessages;

@end

@implementation FLEXSystemLogTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    id logHandler = ^(NSArray<FLEXSystemLogMessage *> *newMessages) {
        self.title = @"System Log";

        [self.logMessages addObjectsFromArray:newMessages];

        // "Follow" the log as new messages stream in if we were previously near the bottom.
        BOOL wasNearBottom = self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.size.height - 100.0;
        [self.tableView reloadData];
        if (wasNearBottom) {
            [self scrollToLastRow];
        }
    };

    _logMessages = [NSMutableArray array];
    if ([NSProcessInfo processInfo].operatingSystemVersion.majorVersion <= 9) {
        _logController = [FLEXASLLogController withUpdateHandler:logHandler];
    } else {
        _logController = [FLEXOSLogController withUpdateHandler:logHandler];
    }

    [self.tableView registerClass:[FLEXSystemLogTableViewCell class] forCellReuseIdentifier:kFLEXSystemLogTableViewCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"Loading...";
    
    UIBarButtonItem *scrollDown = [[UIBarButtonItem alloc] initWithTitle:@" ⬇︎ "
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(scrollToLastRow)];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(showLogSettings)];
    if (FLEXOSLogAvailable()) {
        self.navigationItem.rightBarButtonItems = @[scrollDown, settings];
    } else {
        self.navigationItem.rightBarButtonItem = scrollDown;
    }
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.logController startMonitoring];
}

- (void)scrollToLastRow
{
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)showLogSettings
{
    FLEXOSLogController *logController = (FLEXOSLogController *)self.logController;
    BOOL persistent = [[NSUserDefaults standardUserDefaults] boolForKey:kFLEXiOSPersistentOSLogKey];
    NSString *toggle = persistent ? @"Disable" : @"Enable";
    NSString *title = [@"Persistent logging: " stringByAppendingString:persistent ? @"ON" : @"OFF"];
    NSString *body = @"In iOS 10 and up, ASL is gone. The OS Log API is much more limited. "
    "To get as close to the old behavior as possible, logs must be collected manually at launch and stored.\n\n"
    "Turn this feature on only when you need it.";
    
    UIAlertController *settings = [UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];
    [settings addAction:[UIAlertAction actionWithTitle:toggle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] setBool:!persistent forKey:kFLEXiOSPersistentOSLogKey];
        logController.persistent = !persistent;
        [logController.messages addObjectsFromArray:self.logMessages];
    }]];
    [settings addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:settings animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? self.filteredLogMessages.count : self.logMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    FLEXSystemLogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXSystemLogTableViewCellIdentifier forIndexPath:indexPath];
    cell.logMessage = [self logMessageAtIndexPath:indexPath];
    cell.highlightedText = self.searchController.searchBar.text;
    
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXSystemLogMessage *logMessage = [self logMessageAtIndexPath:indexPath];
    return [FLEXSystemLogTableViewCell preferredHeightForLogMessage:logMessage inWidth:self.tableView.bounds.size.width];
}

#pragma mark - Copy on long press

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
        // We usually only want to copy the log message itself, not any metadata associated with it.
        [UIPasteboard generalPasteboard].string = [self logMessageAtIndexPath:indexPath].messageText;
    }
}

- (FLEXSystemLogMessage *)logMessageAtIndexPath:(NSIndexPath *)indexPath
{
    return self.searchController.isActive ? self.filteredLogMessages[indexPath.row] : self.logMessages[indexPath.row];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<FLEXSystemLogMessage *> *filteredLogMessages = [self.logMessages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXSystemLogMessage *logMessage, NSDictionary<NSString *, id> *bindings) {
            NSString *displayedText = [FLEXSystemLogTableViewCell displayedTextForLogMessage:logMessage];
            return [displayedText rangeOfString:searchString options:NSCaseInsensitiveSearch].length > 0;
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([searchController.searchBar.text isEqual:searchString]) {
                self.filteredLogMessages = filteredLogMessages;
                [self.tableView reloadData];
            }
        });
    });
}

@end
