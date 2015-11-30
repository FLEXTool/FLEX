//
//  PTMultiColumnTableView.h
//  PTMultiColumnTableViewDemo
//
//  Created by Peng Tao on 15/11/16.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXTableColumnHeader.h"

@class FLEXMultiColumnTableView;

@protocol FLEXMultiColumnTableViewDelegate <NSObject>

@optional
- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView labelDidTapWithText:(NSString *)text;
- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView headerTapWithText:(NSString *)text sortType:(FLEXTableColumnHeaderSortType)type;

@end
@protocol FLEXMultiColumnTableViewDataSource <NSObject>

@required

- (NSInteger)numberOfColumnsInTableView:(FLEXMultiColumnTableView *)tableView;
- (NSInteger)numberOfRowsInTableView:(FLEXMultiColumnTableView *)tableView;
- (NSString *)columnNameInColumn:(NSInteger)column;
- (NSString *)rowNameInRow:(NSInteger)row;
- (NSString *)contentAtColumn:(NSInteger)column row:(NSInteger)row;
- (NSArray *)contentAtRow:(NSInteger)row;

- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView widthForContentCellInColumn:(NSInteger)column;
- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView heightForContentCellInRow:(NSInteger)row;
- (CGFloat)heightForTopHeaderInTableView:(FLEXMultiColumnTableView *)tableView;
- (CGFloat)WidthForLeftHeaderInTableView:(FLEXMultiColumnTableView *)tableView;

@end


@interface FLEXMultiColumnTableView : UIView

@property (nonatomic, weak) id<FLEXMultiColumnTableViewDataSource>dataSource;
@property (nonatomic, weak) id<FLEXMultiColumnTableViewDelegate>delegate;

- (void)reloadData;

@end
