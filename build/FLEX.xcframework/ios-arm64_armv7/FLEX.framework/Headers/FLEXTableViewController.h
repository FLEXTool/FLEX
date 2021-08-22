//
//  FLEXTableViewController.h
//  FLEX
//
//  Created by Tanner on 7/5/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXTableView.h"
@class FLEXScopeCarousel, FLEXWindow, FLEXTableViewSection;

typedef CGFloat FLEXDebounceInterval;
/// No delay, all events delivered
extern CGFloat const kFLEXDebounceInstant;
/// Small delay which makes UI seem smoother by avoiding rapid events
extern CGFloat const kFLEXDebounceFast;
/// Slower than Fast, faster than ExpensiveIO
extern CGFloat const kFLEXDebounceForAsyncSearch;
/// The least frequent, at just over once per second; for I/O or other expensive operations
extern CGFloat const kFLEXDebounceForExpensiveIO;

@protocol FLEXSearchResultsUpdating <NSObject>
/// A method to handle search query update events.
///
/// \c searchBarDebounceInterval is used to reduce the frequency at which this
/// method is called. This method is also called when the search bar becomes
/// the first responder, and when the selected search bar scope index changes.
- (void)updateSearchResults:(NSString *)newText;
@end

@interface FLEXTableViewController : UITableViewController <
    UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate
>

/// A grouped table view. Inset on iOS 13.
///
/// Simply calls into \c initWithStyle:
- (id)init;

/// Subclasses may override to configure the controller before \c viewDidLoad:
- (id)initWithStyle:(UITableViewStyle)style;

@property (nonatomic) FLEXTableView *tableView;

/// If your subclass conforms to \c FLEXSearchResultsUpdating
/// then this property is assigned to \c self automatically.
///
/// Setting \c filterDelegate will also set this property to that object.
@property (nonatomic, weak) id<FLEXSearchResultsUpdating> searchDelegate;

/// Defaults to NO.
///
/// Setting this to YES will initialize the carousel and the view.
@property (nonatomic) BOOL showsCarousel;
/// A horizontally scrolling list with functionality similar to
/// that of a search bar's scope bar. You'd want to use this when
/// you have potentially more than 4 scope options.
@property (nonatomic) FLEXScopeCarousel *carousel;

/// Defaults to NO.
///
/// Setting this to YES will initialize searchController and the view.
@property (nonatomic) BOOL showsSearchBar;
/// Defaults to NO.
///
/// Setting this to YES will make the search bar appear whenever the view appears.
/// Otherwise, iOS will only show the search bar when you scroll up.
@property (nonatomic) BOOL showSearchBarInitially;
/// Defaults to NO.
///
/// Setting this to YES will make the search bar activate whenever the view appears.
@property (nonatomic) BOOL activatesSearchBarAutomatically;

/// nil unless showsSearchBar is set to YES.
///
/// self is used as the default search results updater and delegate.
/// The search bar will not dim the background or hide the navigation bar by default.
/// On iOS 11 and up, the search bar will appear in the navigation bar below the title.
@property (nonatomic) UISearchController *searchController;
/// Used to initialize the search controller. Defaults to nil.
@property (nonatomic) UIViewController *searchResultsController;
/// Defaults to "Fast"
///
/// Determines how often search bar results will be "debounced."
/// Empty query events are always sent instantly. Query events will
/// be sent when the user has not changed the query for this interval.
@property (nonatomic) FLEXDebounceInterval searchBarDebounceInterval;
/// Whether the search bar stays at the top of the view while scrolling.
///
/// Calls into self.navigationItem.hidesSearchBarWhenScrolling.
/// Do not change self.navigationItem.hidesSearchBarWhenScrolling directly,
/// or it will not be respsected. Use this instead.
/// Defaults to NO.
@property (nonatomic) BOOL pinSearchBar;
/// By default, we will show the search bar's cancel button when
/// search becomes active and hide it when search is dismissed.
///
/// Do not set the showsCancelButton property on the searchController's
/// searchBar manually. Set this property after turning on showsSearchBar.
///
/// Does nothing pre-iOS 13, safe to call on any version.
@property (nonatomic) BOOL automaticallyShowsSearchBarCancelButton;

/// If using the scope bar, self.searchController.searchBar.selectedScopeButtonIndex.
/// Otherwise, this is the selected index of the carousel, or NSNotFound if using neither.
@property (nonatomic) NSInteger selectedScope;
/// self.searchController.searchBar.text
@property (nonatomic, readonly, copy) NSString *searchText;

/// A totally optional delegate to forward search results updater calls to.
/// If a delegate is set, updateSearchResults: is not called on this view controller.
@property (nonatomic, weak) id<FLEXSearchResultsUpdating> searchResultsUpdater;

/// self.view.window as a \c FLEXWindow
@property (nonatomic, readonly) FLEXWindow *window;

/// Convenient for doing some async processor-intensive searching
/// in the background before updating the UI back on the main queue.
- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock;

/// Adds up to 3 additional items to the toolbar in right-to-left order.
///
/// That is, the first item in the given array will be the rightmost item behind
/// any existing toolbar items. By default, buttons for bookmarks and tabs are shown.
///
/// If you wish to have more control over how the buttons are arranged or which
/// buttons are displayed, you can access the properties for the pre-existing
/// toolbar items directly and manually set \c self.toolbarItems by overriding
/// the \c setupToolbarItems method below.
- (void)addToolbarItems:(NSArray<UIBarButtonItem *> *)items;

/// Subclasses may override. You should not need to call this method directly.
- (void)setupToolbarItems;

@property (nonatomic, readonly) UIBarButtonItem *shareToolbarItem;
@property (nonatomic, readonly) UIBarButtonItem *bookmarksToolbarItem;
@property (nonatomic, readonly) UIBarButtonItem *openTabsToolbarItem;

/// Whether or not to display the "share" icon in the middle of the toolbar. NO by default.
///
/// Turning this on after you have added custom toolbar items will
/// push off the leftmost toolbar item and shift the others leftward.
@property (nonatomic) BOOL showsShareToolbarItem;
/// Called when the share button is pressed.
/// Default implementation does nothign. Subclasses may override.
- (void)shareButtonPressed:(UIBarButtonItem *)sender;

/// Subclasses may call this to opt-out of all toolbar related behavior.
/// This is necessary if you want to disable the gesture which reveals the toolbar.
- (void)disableToolbar;

@end
