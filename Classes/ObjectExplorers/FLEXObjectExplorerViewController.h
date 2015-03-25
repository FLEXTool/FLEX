//
//  FLEXObjectExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLEXObjectExplorerSection) {
    FLEXObjectExplorerSectionDescription,
    FLEXObjectExplorerSectionCustom,
    FLEXObjectExplorerSectionProperties,
    FLEXObjectExplorerSectionIvars,
    FLEXObjectExplorerSectionMethods,
    FLEXObjectExplorerSectionClassMethods,
    FLEXObjectExplorerSectionSuperclasses,
    FLEXObjectExplorerSectionReferencingInstances
};

@interface FLEXObjectExplorerViewController : UITableViewController

@property (nonatomic, strong) id object;

// Sublasses can override the methods below to provide data in a custom section.
// The subclass should provide an array of "row cookies" to allow retreival of individual row data later on.
// The objects in the rowCookies array will be used to call the row title, subtitle, etc methods to consturct the rows.
// The cookies approach is used here because we may filter the visible rows based on the search text entered by the user.
- (NSString *)customSectionTitle;
- (NSArray *)customSectionRowCookies;
- (NSString *)customSectionTitleForRowCookie:(id)rowCookie;
- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie;
- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie;
- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie;

// More subclass configuration hooks.

/// Whether to allow showing/drilling in to current values for ivars and properties. Defalut is YES.
- (BOOL)canHaveInstanceState;

/// Whether to allow drilling in to method calling interfaces for instance methods. Default is YES.
- (BOOL)canCallInstanceMethods;

/// If the custom section data makes the description redundant, subclasses can choose to hide it. Default is YES.
- (BOOL)shouldShowDescription;

/// Subclasses can reorder/change which sections can display directly by overriding this method.
- (NSArray *)possibleExplorerSections;

@end
