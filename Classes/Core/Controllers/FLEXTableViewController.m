//
//  FLEXTableViewController.m
//  FLEX
//
//  Created by Tanner on 7/5/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewController.h"
#import "FLEXExplorerViewController.h"
#import "FLEXBookmarksViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXScopeCarousel.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"
#import "UIBarButtonItem+FLEX.h"
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
@property (nonatomic) UITableViewStyle style;

@property (nonatomic) BOOL hasAppeared;
@property (nonatomic, readonly) UIView *tableHeaderViewContainer;

@property (nonatomic, readonly) BOOL manuallyDeactivateSearchOnDisappear;

@property (nonatomic) UIBarButtonItem *middleToolbarItem;
@property (nonatomic) UIBarButtonItem *middleLeftToolbarItem;
@property (nonatomic) UIBarButtonItem *leftmostToolbarItem;
@end

@implementation FLEXTableViewController
@dynamic tableView;
@synthesize showsShareToolbarItem = _showsShareToolbarItem;
@synthesize tableHeaderViewContainer = _tableHeaderViewContainer;
@synthesize automaticallyShowsSearchBarCancelButton = _automaticallyShowsSearchBarCancelButton;

#pragma mark - Initialization

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
        _style = style;
        _manuallyDeactivateSearchOnDisappear = ({
            NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11;
        });
        
        // We will be our own search delegate if we implement this method
        if ([self respondsToSelector:@selector(updateSearchResults:)]) {
            self.searchDelegate = (id)self;
        }
    }
    
    return self;
}


#pragma mark - Public

- (FLEXWindow *)window {
    return (id)self.view.window;
}

- (void)setShowsSearchBar:(BOOL)showsSearchBar {
    if (_showsSearchBar == showsSearchBar) return;
    _showsSearchBar = showsSearchBar;
    
    if (showsSearchBar) {
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
        
        [self addSearchController:self.searchController];
    } else {
        // Search already shown and just set to NO, so remove it
        [self removeSearchController:self.searchController];
    }
}

- (void)setShowsCarousel:(BOOL)showsCarousel {
    if (_showsCarousel == showsCarousel) return;
    _showsCarousel = showsCarousel;
    
    if (showsCarousel) {
        _carousel = ({
            __weak __typeof(self) weakSelf = self;

            FLEXScopeCarousel *carousel = [FLEXScopeCarousel new];
            carousel.selectedIndexChangedAction = ^(NSInteger idx) {
                __typeof(self) self = weakSelf;
                [self.searchDelegate updateSearchResults:self.searchText];
            };

            // UITableView won't update the header size unless you reset the header view
            [carousel registerBlockForDynamicTypeChanges:^(FLEXScopeCarousel *carousel) {
                __typeof(self) self = weakSelf;
                [self layoutTableHeaderIfNeeded];
            }];

            carousel;
        });
        [self addCarousel:_carousel];
    } else {
        // Carousel already shown and just set to NO, so remove it
        [self removeCarousel:_carousel];
    }
}

- (NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        return self.searchController.searchBar.selectedScopeButtonIndex;
    } else if (self.showsCarousel) {
        return self.carousel.selectedIndex;
    } else {
        return 0;
    }
}

- (void)setSelectedScope:(NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        self.searchController.searchBar.selectedScopeButtonIndex = selectedScope;
    } else if (self.showsCarousel) {
        self.carousel.selectedIndex = selectedScope;
    }

    [self.searchDelegate updateSearchResults:self.searchText];
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

- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *items = backgroundBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainBlock(items);
        });
    });
}

- (void)setsShowsShareToolbarItem:(BOOL)showsShareToolbarItem {
    _showsShareToolbarItem = showsShareToolbarItem;
    if (self.isViewLoaded) {
        [self setupToolbarItems];
    }
}

- (void)disableToolbar {
    self.navigationController.toolbarHidden = YES;
    self.navigationController.hidesBarsOnSwipe = NO;
    self.toolbarItems = nil;
}


#pragma mark - View Controller Lifecycle

- (void)loadView {
    self.view = [FLEXTableView style:self.style];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    _shareToolbarItem = FLEXBarButtonItemSystem(Action, self, @selector(shareButtonPressed:));
    _bookmarksToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.bookmarksIcon target:self action:@selector(showBookmarks)
    ];
    _openTabsToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.openTabsIcon target:self action:@selector(showTabSwitcher)
    ];
    
    self.leftmostToolbarItem = UIBarButtonItem.flex_fixedSpace;
    self.middleLeftToolbarItem = UIBarButtonItem.flex_fixedSpace;
    self.middleToolbarItem = UIBarButtonItem.flex_fixedSpace;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    // Toolbar
    self.navigationController.toolbarHidden = NO;
    self.navigationController.hidesBarsOnSwipe = YES;

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

    [self setupToolbarItems];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.manuallyDeactivateSearchOnDisappear && self.searchController.isActive) {
        self.searchController.active = NO;
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    // Reset this since we are re-appearing under a new
    // parent view controller and need to show it again
    self.didInitiallyRevealSearchBar = NO;
}


#pragma mark - Toolbar, Public

- (void)setupToolbarItems {
    if (!self.isViewLoaded) {
        return;
    }
    
    self.toolbarItems = @[
        self.leftmostToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.middleLeftToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.middleToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.bookmarksToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.openTabsToolbarItem,
    ];
    
    for (UIBarButtonItem *item in self.toolbarItems) {
        [item _setWidth:60];
        // This does not work for anything but fixed spaces for some reason
        // item.width = 60;
    }
    
    // Disable tabs entirely when not presented by FLEXExplorerViewController
    UIViewController *presenter = self.navigationController.presentingViewController;
    if (![presenter isKindOfClass:[FLEXExplorerViewController class]]) {
        self.openTabsToolbarItem.enabled = NO;
    }
}

- (void)addToolbarItems:(NSArray<UIBarButtonItem *> *)items {
    if (self.showsShareToolbarItem) {
        // Share button is in the middle, skip middle button
        if (items.count > 0) {
            self.middleLeftToolbarItem = items[0];
        }
        if (items.count > 1) {
            self.leftmostToolbarItem = items[1];
        }
    } else {
        // Add buttons right-to-left
        if (items.count > 0) {
            self.middleToolbarItem = items[0];
        }
        if (items.count > 1) {
            self.middleLeftToolbarItem = items[1];
        }
        if (items.count > 2) {
            self.leftmostToolbarItem = items[2];
        }
    }
    
    [self setupToolbarItems];
}

- (void)setShowsShareToolbarItem:(BOOL)showShare {
    if (_showsShareToolbarItem != showShare) {
        _showsShareToolbarItem = showShare;
        
        if (showShare) {
            // Push out leftmost item
            self.leftmostToolbarItem = self.middleLeftToolbarItem;
            self.middleLeftToolbarItem = self.middleToolbarItem;
            
            // Use share for middle
            self.middleToolbarItem = self.shareToolbarItem;
        } else {
            // Remove share, shift custom items rightward
            self.middleToolbarItem = self.middleLeftToolbarItem;
            self.middleLeftToolbarItem = self.leftmostToolbarItem;
            self.leftmostToolbarItem = UIBarButtonItem.flex_fixedSpace;
        }
    }
    
    [self setupToolbarItems];
}

- (void)shareButtonPressed:(UIBarButtonItem *)sender {

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

- (void)layoutTableHeaderIfNeeded {
    if (self.showsCarousel) {
        self.carousel.frame = FLEXRectSetHeight(
            self.carousel.frame, self.carousel.intrinsicContentSize.height
        );
    }
    
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
}

- (void)addCarousel:(FLEXScopeCarousel *)carousel {
    if (@available(iOS 11.0, *)) {
        self.tableView.tableHeaderView = carousel;
    } else {
        carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        CGRect frame = self.tableHeaderViewContainer.frame;
        CGRect subviewFrame = carousel.frame;
        subviewFrame.origin.y = 0;
        
        // Put the carousel below the search bar if it's already there
        if (self.showsSearchBar) {
            carousel.frame = subviewFrame = FLEXRectSetY(
                subviewFrame, self.searchController.searchBar.frame.size.height
            );
            frame.size.height += carousel.intrinsicContentSize.height;
        } else {
            frame.size.height = carousel.intrinsicContentSize.height;
        }
        
        self.tableHeaderViewContainer.frame = frame;
        [self.tableHeaderViewContainer addSubview:carousel];
    }
    
    [self layoutTableHeaderIfNeeded];
}

- (void)removeCarousel:(FLEXScopeCarousel *)carousel {
    [carousel removeFromSuperview];
    
    if (@available(iOS 11.0, *)) {
        self.tableView.tableHeaderView = nil;
    } else {
        if (self.showsSearchBar) {
            [self removeSearchController:self.searchController];
            [self addSearchController:self.searchController];
        } else {
            self.tableView.tableHeaderView = nil;
            _tableHeaderViewContainer = nil;
        }
    }
}

- (void)addSearchController:(UISearchController *)controller {
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = controller;
    } else {
        controller.searchBar.autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
        [self.tableHeaderViewContainer addSubview:controller.searchBar];
        CGRect subviewFrame = controller.searchBar.frame;
        CGRect frame = self.tableHeaderViewContainer.frame;
        frame.size.width = MAX(frame.size.width, subviewFrame.size.width);
        frame.size.height = subviewFrame.size.height;
        
        // Move the carousel down if it's already there
        if (self.showsCarousel) {
            self.carousel.frame = FLEXRectSetY(
                self.carousel.frame, subviewFrame.size.height
            );
            frame.size.height += self.carousel.frame.size.height;
        }
        
        self.tableHeaderViewContainer.frame = frame;
        [self layoutTableHeaderIfNeeded];
    }
}

- (void)removeSearchController:(UISearchController *)controller {
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = nil;
    } else {
        [controller.searchBar removeFromSuperview];
        
        if (self.showsCarousel) {
//            self.carousel.frame = FLEXRectRemake(CGPointZero, self.carousel.frame.size);
            [self removeCarousel:self.carousel];
            [self addCarousel:self.carousel];
        } else {
            self.tableView.tableHeaderView = nil;
            _tableHeaderViewContainer = nil;
        }
    }
}

- (UIView *)tableHeaderViewContainer {
    if (!_tableHeaderViewContainer) {
        _tableHeaderViewContainer = [UIView new];
        self.tableView.tableHeaderView = self.tableHeaderViewContainer;
    }
    
    return _tableHeaderViewContainer;
}

- (void)showBookmarks {
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[FLEXBookmarksViewController new]
    ];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showTabSwitcher {
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[FLEXTabsViewController new]
    ];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Search Bar

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self.debounceTimer invalidate];
    NSString *text = searchController.searchBar.text;
    
    void (^updateSearchResults)() = ^{
        if (self.searchResultsUpdater) {
            [self.searchResultsUpdater updateSearchResults:text];
        } else {
            [self.searchDelegate updateSearchResults:text];
        }
    };
    
    // Only debounce if we want to, and if we have a non-empty string
    // Empty string events are sent instantly
    if (text.length && self.searchBarDebounceInterval > kFLEXDebounceInstant) {
        [self debounce:updateSearchResults];
    } else {
        updateSearchResults();
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


#pragma mark Table View

/// Not having a title in the first section looks weird with a rounded-corner table view style
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (@available(iOS 13, *)) {
        if (self.style == UITableViewStyleInsetGrouped) {
            return @" ";
        }
    }

    return nil; // For plain/gropued style
}

@end
