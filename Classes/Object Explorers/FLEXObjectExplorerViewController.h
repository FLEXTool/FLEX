//
//  FLEXObjectExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

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

// If the custom section data makes the description redundant, subclasses can choose to hide it.
- (BOOL)shouldShowDescription;

@end
