//
//  FLEXObjectExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#ifndef _FLEXObjectExplorerViewController_h
#define _FLEXObjectExplorerViewController_h
#endif

#import "FLEXFilteringTableViewController.h"
#import "FLEXObjectExplorer.h"
@class FLEXTableViewSection;

NS_ASSUME_NONNULL_BEGIN

/// A class that displays information about an object or class.
///
/// The explorer view controller uses \c FLEXObjectExplorer to provide a description
/// of the object and list it's properties, ivars, methods, and it's superclasses.
/// Below the description and before properties, some shortcuts will be displayed
/// for certain classes like UIViews. At very bottom, there is an option to view
/// a list of other objects found to be referencing the object being explored.
@interface FLEXObjectExplorerViewController : FLEXFilteringTableViewController

/// Uses the default \c FLEXShortcutsSection for this object as a custom section.
+ (instancetype)exploringObject:(id)objectOrClass;
/// No custom section unless you provide one.
+ (instancetype)exploringObject:(id)objectOrClass customSection:(nullable FLEXTableViewSection *)customSection;
/// No custom sections unless you provide some.
+ (instancetype)exploringObject:(id)objectOrClass
                 customSections:(nullable NSArray<FLEXTableViewSection *> *)customSections;

/// The object being explored, which may be an instance of a class or a class itself.
@property (nonatomic, readonly) id object;
/// This object provides the object's metadata for the explorer view controller.
@property (nonatomic, readonly) FLEXObjectExplorer *explorer;

/// Called once to initialize the list of section objects.
///
/// Subclasses can override this to add, remove, or rearrange sections of the explorer.
- (NSArray<FLEXTableViewSection *> *)makeSections;

/// Whether to allow showing/drilling in to current values for ivars and properties. Default is YES.
@property (nonatomic, readonly) BOOL canHaveInstanceState;

/// Whether to allow drilling in to method calling interfaces for instance methods. Default is YES.
@property (nonatomic, readonly) BOOL canCallInstanceMethods;

/// If the custom section data makes the description redundant, subclasses can choose to hide it. Default is YES.
@property (nonatomic, readonly) BOOL shouldShowDescription;

@end

NS_ASSUME_NONNULL_END
