//
//  FLEXMacTableViewController.h
//  FLEX (macOS)
//
//  A searchable, sectioned table view controller; the AppKit
//  counterpart of FLEXTableViewController.
//

#import <AppKit/AppKit.h>
#import "FLEXMacTableModel.h"
#import "FLEXMacNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacTableViewController : NSViewController <FLEXMacNavigationItems>

/// Defaults to YES
@property (nonatomic) BOOL showsSearchBar;
@property (nonatomic, copy, nullable) NSString *searchPlaceholder;
@property (nonatomic, readonly) NSString *searchText;
/// Adds a refresh button to the navigation bar which calls -reloadData
@property (nonatomic) BOOL showsRefreshButton;

/// A view shown above the search field, such as a scope bar
@property (nonatomic, nullable) NSView *headerAccessoryView;
/// Text shown in place of the table when there are no rows
@property (nonatomic, copy, nullable) NSString *emptyText;

@property (nonatomic, readonly) NSTableView *tableView;

/// Setting this refilters and reloads the table
@property (nonatomic, copy) NSArray<FLEXMacSection *> *sections;

/// Subclasses override to build their sections. Called by -reloadData.
- (NSArray<FLEXMacSection *> *)makeSections;
/// Rebuilds sections with -makeSections and reloads the table
- (void)reloadData;
/// Re-applies the current search to the current sections
- (void)refilter;
/// Called when the search text changes; the default implementation calls -refilter
- (void)searchTextDidChange;

/// Extra navigation bar items for subclasses; included in -flex_navigationAccessoryViews
- (NSArray<NSView *> *)additionalNavigationAccessoryViews;

/// The row currently selected, if any
@property (nonatomic, readonly, nullable) FLEXMacRow *selectedRow;
- (void)activateRow:(FLEXMacRow *)row;

@end

NS_ASSUME_NONNULL_END
