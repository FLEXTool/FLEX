//
//  FLEXTableViewController.h
//  FLEX
//
//  Created by Tanner on 7/5/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FLEXScopeCarousel;

typedef CGFloat FLEXDebounceInterval;
/// No delay, all events delivered
extern CGFloat const kFLEXDebounceInstant;
/// Small delay which makes UI seem smoother by avoiding rapid events
extern CGFloat const kFLEXDebounceFast;
/// Slower than Fast, faster than ExpensiveIO
extern CGFloat const kFLEXDebounceForAsyncSearch;
/// The least frequent, at just over once per second; for I/O or other expensive operations
extern CGFloat const kFLEXDebounceForExpensiveIO;

@interface FLEXTableViewController : UITableViewController <UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

/// A grouped table view. Inset on iOS 13.
/// 
/// Simply calls into initWithStyle:
- (id)init;

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

/// nil unless showsSearchBar is set to YES.
/// 
/// self is used as the default search results updater and delegate.
/// Make sure your subclass conforms to UISearchControllerDelegate.
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
@property (nonatomic, readonly) NSInteger selectedScope;
/// self.searchController.searchBar.text
@property (nonatomic, readonly) NSString *searchText;

/// Subclasses should override to handle search query update events.
/// 
/// searchBarDebounceInterval is used to reduce the frequency at which this method is called.
/// This method is also called when the search bar becomes the first responder,
/// and when the selected search bar scope index changes.
- (void)updateSearchResults:(NSString *)newText;

/// Convenient for doing some async processor-intensive searching
/// in the background before updating the UI back on the main queue.
- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock;

@end
