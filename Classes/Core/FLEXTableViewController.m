//
//  FLEXTableViewController.m
//  FLEX
//
//  Created by Tanner on 7/5/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"

@interface Block : NSObject
- (void)invoke;
@end

CGFloat const kFLEXDebounceInstant = 0.f;
CGFloat const kFLEXDebounceFast = 0.05;
CGFloat const kFLEXDebounceForAsyncSearch = 0.15;
CGFloat const kFLEXDebounceForExpensiveIO = 0.5;

@interface FLEXTableViewController ()
@property (nonatomic) NSTimer *debounceTimer;
@end

@implementation FLEXTableViewController

#pragma mark - Public

- (id)init {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        self = [self initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [self initWithStyle:UITableViewStyleGrouped];
    }
#else
    self = [self initWithStyle:UITableViewStyleGrouped];
#endif
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    
    if (self) {
        self.searchBarDebounceInterval = kFLEXDebounceFast;
    }
    
    return self;
}

- (void)setShowsSearchBar:(BOOL)showsSearchBar {
    if (_showsSearchBar == showsSearchBar) return;
    _showsSearchBar = showsSearchBar;
    
    UIViewController *results = self.searchResultsController;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:results];
    self.searchController.searchBar.placeholder = @"Filter";
    self.searchController.searchResultsUpdater = (id)self;
    self.searchController.delegate = (id)self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    /// Not necessary in iOS 13; remove this when iOS 13 is the deployment target
    self.searchController.searchBar.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
}

- (NSInteger)selectedScope {
    return self.searchController.searchBar.selectedScopeButtonIndex;
}

- (NSString *)searchText {
    return self.searchController.searchBar.text;
}

- (void)setAutomaticallyShowsSearchBarCancelButton:(BOOL)autoShowCancel {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13, *)) {
        self.searchController.automaticallyShowsCancelButton = autoShowCancel;
    } else {
        _automaticallyShowsSearchBarCancelButton = autoShowCancel;
    }
#else
    _automaticallyShowsSearchBarCancelButton = autoShowCancel;
#endif
}

- (void)updateSearchResults:(NSString *)newText { }

- (void)onBackgroundQueue:(NSArray *(^)())backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *items = backgroundBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainBlock(items);
        });
    });
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Make the search bar re-appear instead of hiding
    if (@available(iOS 11.0, *)) {
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Allow scrolling to collapse the search bar,
    // only if we don't want it pinned
    if (@available(iOS 11.0, *)) {
        self.navigationItem.hidesSearchBarWhenScrolling = !self.pinSearchBar;
    }
}

#pragma mark - Private

- (void)debounce:(void(^)())block {
    [self.debounceTimer invalidate];
    
    self.debounceTimer = [NSTimer
        scheduledTimerWithTimeInterval:self.searchBarDebounceInterval
        target:block
        selector:@selector(invoke)
        userInfo:nil
        repeats:NO
    ];
}

#pragma mark - Search Bar

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self.debounceTimer invalidate];
    NSString *text = searchController.searchBar.text;
    
    // Only debounce if we want to, and if we have a non-empty string
    // Empty string events are sent instantly
    if (text.length && self.searchBarDebounceInterval > kFLEXDebounceInstant) {
        [self debounce:^{
            [self updateSearchResults:text];
        }];
    } else {
        [self updateSearchResults:text];
    }
}

#pragma mark UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    if (self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:YES animated:YES];
    }
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    if (self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:NO animated:YES];
    }
}

#pragma mark UISearchBarDelegate

/// Not necessary in iOS 13; remove this when iOS 13 is the deployment target
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}

@end
