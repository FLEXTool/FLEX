//
//  TBKeyPathSearchController.h
//  TBTweakViewController
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TBKeyPathToolbar.h"
#import "FLEXMethod.h"


@protocol TBKeyPathSearchControllerDelegate <NSObject>
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic, readonly) UINavigationController *navigationController;

@property (nonatomic, readonly) NSString *longPressItemSELPrefix;

- (void)didSelectMethod:(FLEXMethod *)method;

@end

@interface TBKeyPathSearchController : NSObject <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

+ (instancetype)delegate:(id<TBKeyPathSearchControllerDelegate>)delegate;

@property (nonatomic) TBKeyPathToolbar *toolbar;

- (void)longPressedRect:(CGRect)rect at:(NSIndexPath *)indexPath;
- (void)didSelectKeyPathOption:(NSString *)text;
- (void)didSelectSuperclass:(NSString *)name;
- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar;

@end
