//
//  FLEXTableViewController.m
//  FLEX
//
//  Created by Tanner on 7/5/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"
#import "FLEXScopeCarousel.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>

@interface Block : NSObject
- (void)invoke;
@end

CGFloat const kFLEXDebounceInstant = 0.f;
CGFloat const kFLEXDebounceFast = 0.05;
CGFloat const kFLEXDebounceForAsyncSearch = 0.15;
CGFloat const kFLEXDebounceForExpensiveIO = 0.5;

@interface FLEXTableViewController ()
@property (nonatomic) NSTimer *debounceTimer;
@property (nonatomic) BOOL didInitiallyRevealSearchBar;
@end

@implementation FLEXTableViewController
@synthesize automaticallyShowsSearchBarCancelButton = _automaticallyShowsSearchBarCancelButton;

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
        _searchBarDebounceInterval = kFLEXDebounceFast;
        _showSearchBarInitially = YES;
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
    /// Not necessary in iOS 13; remove this when iOS 13 is the minimum deployment target
    self.searchController.searchBar.delegate = self;

    self.automaticallyShowsSearchBarCancelButton = YES;

#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13, *)) {
        self.searchController.automaticallyShowsScopeBar = NO;
    }
#endif
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
}

- (void)setShowsCarousel:(BOOL)showsCarousel {
    if (_showsCarousel == showsCarousel) return;
    _showsCarousel = showsCarousel;

    _carousel = ({
        __weak __typeof(self) weakSelf = self;

        FLEXScopeCarousel *carousel = [FLEXScopeCarousel new];
        carousel.selectedIndexChangedAction = ^(NSInteger idx) {
            __typeof(self) self = weakSelf;
            [self updateSearchResults:self.searchText];
        };

        self.tableView.tableHeaderView = carousel;
        [self.tableView layoutIfNeeded];
        // UITableView won't update the header size unless you reset the header view
        [carousel registerBlockForDynamicTypeChanges:^(FLEXScopeCarousel *carousel) {
            __typeof(self) self = weakSelf;
            self.tableView.tableHeaderView = carousel;
            [self.tableView layoutIfNeeded];
        }];

        carousel;
    });
}

- (NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        return self.searchController.searchBar.selectedScopeButtonIndex;
    } else if (self.showsCarousel) {
        return self.carousel.selectedIndex;
    } else {
        return NSNotFound;
    }
}

- (NSString *)searchText {
    return self.searchController.searchBar.text;
}

- (BOOL)automaticallyShowsSearchBarCancelButton {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13, *)) {
        return self.searchController.automaticallyShowsCancelButton;
    }
#endif

    return _automaticallyShowsSearchBarCancelButton;
}

- (void)setAutomaticallyShowsSearchBarCancelButton:(BOOL)value {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13, *)) {
        self.searchController.automaticallyShowsCancelButton = value;
    }
#endif

    _automaticallyShowsSearchBarCancelButton = value;
}

- (void)updateSearchResults:(NSString *)newText { }

- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
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

    // On iOS 13, the root view controller shows it's search bar no matter what.
    // Turning this off avoids some weird flash the navigation bar does when we
    // toggle navigationItem.hidesSearchBarWhenScrolling on and off. The flash
    // will still happen on subsequent view controllers, but we can at least
    // avoid it for the root view controller
    if (@available(iOS 13, *)) {
        if (self.navigationController.viewControllers.firstObject == self) {
            _showSearchBarInitially = NO;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // When going back, make the search bar reappear instead of hiding
    if (@available(iOS 11.0, *)) {
        if ((self.pinSearchBar || self.showSearchBarInitially) && !self.didInitiallyRevealSearchBar) {
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Allow scrolling to collapse the search bar, only if we don't want it pinned
    if (@available(iOS 11.0, *)) {
        if (self.showSearchBarInitially && !self.pinSearchBar && !self.didInitiallyRevealSearchBar) {
            // All this mumbo jumbo is necessary to work around a bug in iOS 13 up to 13.2
            // wherein quickly toggling navigationItem.hidesSearchBarWhenScrolling to make
            // the search bar appear initially results in a bugged search bar that
            // becomes transparent and floats over the screen as you scroll
            [UIView animateWithDuration:0.2 animations:^{
                self.navigationItem.hidesSearchBarWhenScrolling = YES;
                [self.navigationController.view setNeedsLayout];
                [self.navigationController.view layoutIfNeeded];
            }];
        }
    }

    // We only want to reveal the search bar when the view controller first appears.
    self.didInitiallyRevealSearchBar = YES;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    // Reset this since we are re-appearing under a new
    // parent view controller and need to show it again
    self.didInitiallyRevealSearchBar = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.searchController.active) {
        self.searchController.active = NO;
    }
}

#pragma mark - Private

- (void)debounce:(void(^)(void))block {
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
    // Manually show cancel button for < iOS 13
    if (!@available(iOS 13, *) && self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:YES animated:YES];
    }
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    // Manually hide cancel button for < iOS 13
    if (!@available(iOS 13, *) && self.automaticallyShowsSearchBarCancelButton) {
        [searchController.searchBar setShowsCancelButton:NO animated:YES];
    }
}

#pragma mark UISearchBarDelegate

/// Not necessary in iOS 13; remove this when iOS 13 is the deployment target
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark Table view

/// Not having a title in the first section looks weird with a rounded-corner table view style
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (@available(iOS 13, *)) {
        return @" "; // For inset grouped style
    }

    return nil; // For plain/gropued style
}

@end
