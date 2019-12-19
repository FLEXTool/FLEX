//
//  FLEXExplorerSection.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FLEXTableView;

#pragma mark FLEXExplorerSection

/// An abstract base class for custom object explorer sections.
@interface FLEXExplorerSection : NSObject

#pragma mark - Data

/// A title to be displayed for the custom section. Subclasses must override.
@property (nonatomic, readonly) NSString *title;
/// The number of rows in this section.
/// This should not change until \c filterText is changed or \c reloadData is called.
@property (nonatomic, readonly) NSInteger numberOfRows;
/// A map of reuse identifiers to \c UITableViewCell (sub)class objects.
/// Subclasses \e may override this as necessary, but are not required to.
/// See \c FLEXTableView.h for more information.
/// @return nil by default.
@property (nonatomic, readonly) NSDictionary<NSString *, Class> *cellRegistrationMapping;

/// The section should filter itself based on the contents of this property
/// as it is set. If it is set to nil or an empty string, it should not filter.
/// Subclasses should override or observe this property and react to changes.
@property (nonatomic) NSString *filterText;

/// Provides an avenue for the section to change the number of rows.
/// This is called before reloading the table view itself.
- (void)reloadData;

#pragma mark - Row selection

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
- (void(^)(UIViewController *host))didSelectRowAction:(NSInteger)row;

/// A view controller to display when the row is selected, if the row
/// supports being selected as indicated by \c canSelectRow:. Subclasses
/// must implement this in accordance with how they implement \c canSelectRow:
/// if they do not implement \c didSelectRowAction:
/// @return \c nil by default
- (UIViewController *)viewControllerToPushForRow:(NSInteger)row;

/// Called when the accessory view's detail button is pressed.
/// @return \c nil by default.
- (void(^)(UIViewController *host))didPressInfoButtonAction:(NSInteger)row;

#pragma mark - Cell configuration

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
- (NSString *)titleForRow:(NSInteger)row;
/// For use by whatever view controller uses your section. Not required.
/// @return An optional subtitle.
- (NSString *)subtitleForRow:(NSInteger)row;

@end


#pragma mark - FLEXObjectInfoSection

/// \c FLEXExplorerSection itself doesn't need to know about the object being explored.
/// Subclasses might need this info to provide useful information about the object. Instead
/// of adding an abstract class to the class hierarchy, subclasses can conform to this protocol
/// to indicate that the only info they need to be initialized is the object being explored.
@protocol FLEXObjectInfoSection <NSObject>

+ (instancetype)forObject:(id)object;

@end
