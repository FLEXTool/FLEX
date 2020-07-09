//
//  FLEXMutableListSection.h
//  FLEX
//
//  Created by Tanner on 3/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXCollectionContentSection.h"

typedef void (^FLEXMutableListCellForElement)(__kindof UITableViewCell *cell, id element, NSInteger row);

/// A section aimed at meeting the needs of table views with one section
/// (or, a section that shouldn't warrant the code duplication that comes
/// with creating a new section just for some specific table view)
///
/// Use this section if you want to display a growing list of rows,
/// or even if you want to display a static list of rows.
///
/// To support editing or inserting, implement the appropriate
/// table view delegate methods in your table view delegate class
/// and call \c mutate: (or \c setList: ) before updating the table view.
///
/// By default, no section title is shown. Assign one to \c customTitle
///
/// By default, \c kFLEXDetailCell is the reuse identifier used. If you need
/// to support multiple reuse identifiers in a single section, implement the
/// \c cellForRowAtIndexPath: method, dequeue the cell yourself and call
/// \c -configureCell: on the appropriate section object, passing in the cell
@interface FLEXMutableListSection<__covariant ObjectType> : FLEXCollectionContentSection

/// Initializes a section with an empty list.
+ (instancetype)list:(NSArray<ObjectType> *)list
   cellConfiguration:(FLEXMutableListCellForElement)configurationBlock
       filterMatcher:(BOOL(^)(NSString *filterText, id element))filterBlock;

/// By default, rows are not selectable. If you want rows
/// to be selectable, provide a selection handler here.
@property (nonatomic, copy) void (^selectionHandler)(__kindof UIViewController *host, ObjectType element);

/// The objects representing all possible rows in the section.
@property (nonatomic) NSArray<ObjectType> *list;
/// The objects representing the currently unfiltered rows in the section.
@property (nonatomic, readonly) NSArray<ObjectType> *filteredList;

/// A readwrite version of the same property in \c FLEXTableViewSection.h
///
/// This property expects one entry. An exception is thrown if more than one
/// entry is supplied. If you need more than one reuse identifier within a single
/// section, your view probably has more complexity than this class can handle.
@property (nonatomic, readwrite) NSDictionary<NSString *, Class> *cellRegistrationMapping;

/// Call this method to mutate the full, unfiltered list.
/// This ensures that \c filteredList is updated after any mutations.
- (void)mutate:(void(^)(NSMutableArray *list))block;

@end

