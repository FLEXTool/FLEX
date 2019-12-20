//
//  FLEXTableView.h
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark Reuse identifiers

typedef NSString * FLEXTableViewCellReuseIdentifier;

/// A regular \c UITableViewCell initialized with \c UITableViewCellStyleDefault
extern FLEXTableViewCellReuseIdentifier const kFLEXDefaultCell;
/// A \c FLEXSubtitleTableViewCell initialized with \c UITableViewCellStyleSubtitle
extern FLEXTableViewCellReuseIdentifier const kFLEXDetailCell;
/// A \c FLEXMultilineTableViewCell initialized with \c UITableViewCellStyleDefault
extern FLEXTableViewCellReuseIdentifier const kFLEXMultilineCell;
/// A \c FLEXMultilineTableViewCell initialized with \c UITableViewCellStyleSubtitle
extern FLEXTableViewCellReuseIdentifier const kFLEXMultilineDetailCell;

#pragma mark - FLEXTableView
@interface FLEXTableView : UITableView

+ (instancetype)flexDefaultTableView;
+ (instancetype)groupedTableView;
+ (instancetype)plainTableView;

/// You do not need to register classes for any of the default reuse identifiers above
/// (annotated as \c FLEXTableViewCellReuseIdentifier types) unless you wish to provide
/// a custom cell for any of those reuse identifiers. By default, \c FLEXTableViewCell,
/// \c FLEXSubtitleTableViewCell, and \c FLEXMultilineTableViewCell are used, respectively.
///
/// @param registrationMapping A map of reuse identifiers to \c UITableViewCell (sub)class objects.
- (void)registerCells:(NSDictionary<NSString *, Class> *)registrationMapping;

@end
