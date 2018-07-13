//
//  FLEXSystemLogTableViewController.m
//  UICatalog
//
//  Created by Ryan Olson on 1/19/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXSystemLogTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXSystemLogMessage.h"
#import "FLEXSystemLogTableViewCell.h"
#import <asl.h>

@interface FLEXSystemLogTableViewController () <UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, readonly) NSMutableArray<FLEXSystemLogMessage *> *logMessages;
@property (nonatomic, copy) NSArray<FLEXSystemLogMessage *> *filteredLogMessages;
@property (nonatomic, strong) NSTimer *logUpdateTimer;
@property (nonatomic, readonly) NSMutableIndexSet *logMessageIdentifiers;

@end

@implementation FLEXSystemLogTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _logMessages = [NSMutableArray array];
    _logMessageIdentifiers = [NSMutableIndexSet indexSet];

    [self.tableView registerClass:[FLEXSystemLogTableViewCell class] forCellReuseIdentifier:kFLEXSystemLogTableViewCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"Loading...";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" ⬇︎ " style:UIBarButtonItemStylePlain target:self action:@selector(scrollToLastRow)];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;

    [self updateLogMessages];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSTimeInterval updateInterval = 1.0;

#if TARGET_IPHONE_SIMULATOR
    // Querrying the ASL is much slower in the simulator. We need a longer polling interval to keep things repsonsive.
    updateInterval = 5.0;
#endif

    self.logUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(updateLogMessages) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.logUpdateTimer invalidate];
}

- (void)updateLogMessages
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<FLEXSystemLogMessage *> *newMessages = [self newLogMessagesForCurrentProcess];
        if (!newMessages.count) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = @"System Log";

            [self.logMessages addObjectsFromArray:newMessages];
            for (FLEXSystemLogMessage *message in newMessages) {
                [self.logMessageIdentifiers addIndex:(NSUInteger)message.messageID];
            }

            // "Follow" the log as new messages stream in if we were previously near the bottom.
            BOOL wasNearBottom = self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.size.height - 100.0;
            [self.tableView reloadData];
            if (wasNearBottom) {
                [self scrollToLastRow];
            }
        });
    });
}

- (void)scrollToLastRow
{
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? [self.filteredLogMessages count] : [self.logMessages count];
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
        FLEXSystemLogMessage *logMessage = [self logMessageAtIndexPath:indexPath];
        NSString *stringToCopy = [FLEXSystemLogTableViewCell displayedTextForLogMessage:logMessage] ?: @"";
        [[UIPasteboard generalPasteboard] setString:stringToCopy];
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

#pragma mark - Log Message Fetching

- (NSArray<FLEXSystemLogMessage *> *)newLogMessagesForCurrentProcess
{
    if (!self.logMessages.count) {
        return [[self class] allLogMessagesForCurrentProcess];
    }

    aslresponse response = [FLEXSystemLogTableViewController ASLMessageListForCurrentProcess];
    aslmsg aslMessage = NULL;

    NSMutableArray<FLEXSystemLogMessage *> *newMessages = [NSMutableArray array];

    while ((aslMessage = asl_next(response))) {
        NSUInteger messageID = (NSUInteger)atoll(asl_get(aslMessage, ASL_KEY_MSG_ID));
        if (![self.logMessageIdentifiers containsIndex:messageID]) {
            [newMessages addObject:[FLEXSystemLogMessage logMessageFromASLMessage:aslMessage]];
        }
    }

    asl_release(response);
    return newMessages;
}

+ (aslresponse)ASLMessageListForCurrentProcess
{
    static NSString *pidString = nil;
    if (!pidString) {
        pidString = @([[NSProcessInfo processInfo] processIdentifier]).stringValue;
    }

    // Create system log query object.
    asl_object_t query = asl_new(ASL_TYPE_QUERY);

    // Filter for messages from the current process.
    // Note that this appears to happen by default on device, but is required in the simulator.
    asl_set_query(query, ASL_KEY_PID, pidString.UTF8String, ASL_QUERY_OP_EQUAL);

    return asl_search(NULL, query);
}

+ (NSArray<FLEXSystemLogMessage *> *)allLogMessagesForCurrentProcess
{
    aslresponse response = [self ASLMessageListForCurrentProcess];
    aslmsg aslMessage = NULL;

    NSMutableArray<FLEXSystemLogMessage *> *logMessages = [NSMutableArray array];
    while ((aslMessage = asl_next(response))) {
        [logMessages addObject:[FLEXSystemLogMessage logMessageFromASLMessage:aslMessage]];
    }
    asl_release(response);

    return logMessages;
}

@end
