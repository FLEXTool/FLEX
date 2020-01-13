//
//  FLEXKeyPathSearchController.h
//  FLEX
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TBKeyPathToolbar.h"
#import "FLEXMethod.h"

@protocol TBKeyPathSearchControllerDelegate <UITableViewDataSource>

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UISearchController *searchController;

/// For loaded images which don't have an NSBundle
- (void)didSelectImagePath:(NSString *)message shortName:(NSString *)shortName;
- (void)didSelectBundle:(NSBundle *)bundle;
- (void)didSelectClass:(Class)cls;

@end


@interface TBKeyPathSearchController : NSObject <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

+ (instancetype)delegate:(id<TBKeyPathSearchControllerDelegate>)delegate;

@property (nonatomic) TBKeyPathToolbar *toolbar;

- (void)didSelectKeyPathOption:(NSString *)text;
- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar;

@end
