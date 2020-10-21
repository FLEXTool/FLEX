//
//  FLEXTableViewSection.h
//  FLEX
//
//  Created by Tanner on 1/29/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXMacros.h"
#import "NSArray+FLEX.h"
@class FLEXTableView;

NS_ASSUME_NONNULL_BEGIN

#pragma mark FLEXTableViewSection

/// An abstract base class for table view sections.
///
/// Many properties or methods here return nil or some logical equivalent by default.
/// Even so, most of the methods with defaults are intended to be overriden by subclasses.
/// Some methods are not implemented at all and MUST be implemented by a subclass.
@interface FLEXTableViewSection : NSObject {
    @protected
    /// Unused by default, use if you want
    NSString *_title;
    
    @private
    __weak UITableView *_tableView;
    NSInteger _sectionIndex;
}

#pragma mark - Data

/// A title to be displayed for the custom section.
/// Subclasses may override or use the \c _title ivar.
@property (nonatomic, readonly, nullable, copy) NSString *title;
/// The number of rows in this section. Subclasses must override.
/// This should not change until \c filterText is changed or \c reloadData is called.
@property (nonatomic, readonly) NSInteger numberOfRows;
/// A map of reuse identifiers to \c UITableViewCell (sub)class objects.
/// Subclasses \e may override this as necessary, but are not required to.
/// See \c FLEXTableView.h for more information.
/// @return nil by default.
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, Class> *cellRegistrationMapping;

/// The section should filter itself based on the contents of this property
/// as it is set. If it is set to nil or an empty string, it should not filter.
/// Subclasses should override or observe this property and react to changes.
///
/// It is common practice to use two arrays for the underlying model:
/// One to hold all rows, and one to hold unfiltered rows. When \c setFilterText:
/// is called, call \c super to store the new value, and re-filter your model accordingly.
@property (nonatomic, nullable) NSString *filterText;

/// Provides an avenue for the section to refresh data or change the number of rows.
///
/// This is called before reloading the table view itself. If your section pulls data
/// from an external data source, this is a good place to refresh that data entirely.
/// If your section does not, then it might be simpler for you to just override
/// \c setFilterText: to call \c super and call \c reloadData.
- (void)reloadData;

/// Like \c reloadData, but optionally reloads the table view section
/// associated with this section object, if any. Do not override.
/// Do not call outside of the main thread.
- (void)reloadData:(BOOL)updateTable;

/// Provide a table view and section index to allow the section to efficiently reload
/// its own section of the table when something changes it. The table reference is
/// held weakly, and subclasses cannot access it or the index. Call this method again
/// if the section numbers have changed since you last called it.
- (void)setTable:(UITableView *)tableView section:(NSInteger)index;

#pragma mark - Row Selection

/// Whether the given row should be selectable, such as if tapping the cell
/// should take the user to a new screen or trigger an action.
/// Subclasses \e may override this as necessary, but are not required to.
/// @return \c NO by default
- (BOOL)canSelectRow:(NSInteger)row;

/// An action "future" to be triggered when the row is selected, if the row
/// supports being selected as indicated by \c canSelectRow:. Subclasses
/// must implement this in accordance with how they implement \c canSelectRow:
/// if they do not implement \c viewControllerToPushForRow:
/// @return This returns \c nil if no view controller is provided by
/// \c viewControllerToPushForRow: — otherwise it pushes that view controller
/// onto \c host.navigationController
- (nullable void(^)(__kindof UIViewController *host))didSelectRowAction:(NSInteger)row;

/// A view controller to display when the row is selected, if the row
/// supports being selected as indicated by \c canSelectRow:. Subclasses
/// must implement this in accordance with how they implement \c canSelectRow:
/// if they do not implement \c didSelectRowAction:
/// @return \c nil by default
- (nullable UIViewController *)viewControllerToPushForRow:(NSInteger)row;

/// Called when the accessory view's detail button is pressed.
/// @return \c nil by default.
- (nullable void(^)(__kindof UIViewController *host))didPressInfoButtonAction:(NSInteger)row;

#pragma mark - Context Menus
#if FLEX_AT_LEAST_IOS13_SDK

/// By default, this is the title of the row.
/// @return The title of the context menu, if any.
- (nullable NSString *)menuTitleForRow:(NSInteger)row API_AVAILABLE(ios(13.0));
/// Protected, not intended for public use. \c menuTitleForRow:
/// already includes the value returned from this method.
/// 
/// By default, this returns \c @"". Subclasses may override to
/// provide a detailed description of the target of the context menu.
- (NSString *)menuSubtitleForRow:(NSInteger)row API_AVAILABLE(ios(13.0));
/// The context menu items, if any. Subclasses may override.
/// By default, only inludes items for \c copyMenuItemsForRow:.
- (nullable NSArray<UIMenuElement *> *)menuItemsForRow:(NSInteger)row sender:(UIViewController *)sender API_AVAILABLE(ios(13.0));
/// Subclasses may override to return a list of copiable items.
///
/// Every two elements in the list compose a key-value pair, where the key
/// should be a description of what will be copied, and the values should be
/// the strings to copy. Return an empty string as a value to show a disabled action.
- (nullable NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row API_AVAILABLE(ios(13.0));
#endif

#pragma mark - Cell Configuration

/// Provide a reuse identifier for the given row. Subclasses should override.
///
/// Custom reuse identifiers should be specified in \c cellRegistrationMapping.
/// You may return any of the identifiers in \c FLEXTableView.h
/// without including them in the \c cellRegistrationMapping.
/// @return \c kFLEXDefaultCell by default.
- (NSString *)reuseIdentifierForRow:(NSInteger)row;
/// Configure a cell for the given row. Subclasses must override.
- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row;

#pragma mark - External Convenience

/// For use by whatever view controller uses your section. Not required.
/// @return An optional title.
- (nullable NSString *)titleForRow:(NSInteger)row;
/// For use by whatever view controller uses your section. Not required.
/// @return An optional subtitle.
- (nullable NSString *)subtitleForRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
