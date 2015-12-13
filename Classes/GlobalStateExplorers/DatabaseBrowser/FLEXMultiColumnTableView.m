//
//  PTMultiColumnTableView.m
//  PTMultiColumnTableViewDemo
//
//  Created by Peng Tao on 15/11/16.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXMultiColumnTableView.h"
#import "FLEXTableContentCell.h"
#import "FLEXTableLeftCell.h"

@interface FLEXMultiColumnTableView ()
<UITableViewDataSource, UITableViewDelegate,UIScrollViewDelegate, FLEXTableContentCellDelegate>

@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UIScrollView *headerScrollView;
@property (nonatomic, strong) UITableView  *leftTableView;
@property (nonatomic, strong) UITableView  *contentTableView;
@property (nonatomic, strong) UIView       *leftHeader;

@property (nonatomic, strong) NSDictionary *sortStatusDict;
@property (nonatomic, strong) NSArray *rowData;
@end

static const CGFloat kColumnMargin = 1;

@implementation FLEXMultiColumnTableView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadUI];
    }
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self reloadData];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width  = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat topheaderHeight = [self topHeaderHeight];
    CGFloat leftHeaderWidth = [self leftHeaderWidth];
    
    CGFloat contentWidth = 0.0;
    NSInteger rowsCount = [self numberOfColumns];
    for (int i = 0; i < rowsCount; i++) {
        contentWidth += [self contentWidthForColumn:i];
    }
    
    self.leftTableView.frame           = CGRectMake(0, topheaderHeight, leftHeaderWidth, height - topheaderHeight);
    self.headerScrollView.frame        = CGRectMake(leftHeaderWidth, 0, width - leftHeaderWidth, topheaderHeight);
    self.headerScrollView.contentSize  = CGSizeMake( self.contentTableView.frame.size.width, self.headerScrollView.frame.size.height);
    self.contentTableView.frame        = CGRectMake(0, 0, contentWidth + [self numberOfColumns] * [self columnMargin] , height - topheaderHeight);
    self.contentScrollView.frame       = CGRectMake(leftHeaderWidth, topheaderHeight, width - leftHeaderWidth, height - topheaderHeight);
    self.contentScrollView.contentSize = self.contentTableView.frame.size;
    self.leftHeader.frame              = CGRectMake(0, 0, [self leftHeaderWidth], [self topHeaderHeight]);
}


- (void)loadUI
{
    [self loadHeaderScrollView];
    [self loadContentScrollView];
    [self loadLeftView];
}

- (void)reloadData
{
    [self loadLeftViewData];
    [self loadContentData];
    [self loadHeaderData];
}

#pragma mark - UI

- (void)loadHeaderScrollView
{
    UIScrollView *headerScrollView = [[UIScrollView alloc] init];
    headerScrollView.delegate      = self;
    self.headerScrollView          = headerScrollView;
    self.headerScrollView.backgroundColor =  [UIColor colorWithWhite:0.803 alpha:0.850];
    
    [self addSubview:headerScrollView];
}

- (void)loadContentScrollView
{
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.bounces       = NO;
    scrollView.delegate      = self;
    
    UITableView *tableView   = [[UITableView alloc] init];
    tableView.delegate       = self;
    tableView.dataSource     = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self addSubview:scrollView];
    [scrollView addSubview:tableView];
    
    self.contentScrollView = scrollView;
    self.contentTableView    = tableView;
    
}

- (void)loadLeftView
{
    UITableView *leftTableView = [[UITableView alloc] init];
    leftTableView.delegate       = self;
    leftTableView.dataSource     = self;
    leftTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.leftTableView           = leftTableView;
    [self addSubview:leftTableView];
    
    UIView *leftHeader = [[UIView alloc] init];
    leftHeader.backgroundColor = [UIColor colorWithWhite:0.950 alpha:0.668];
    self.leftHeader            = leftHeader;
    [self addSubview:leftHeader];
    
}


#pragma mark - Data

- (void)loadHeaderData
{
    NSArray *subviews = self.headerScrollView.subviews;
    
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }
    CGFloat x = 0.0;
    CGFloat w = 0.0;
    for (int i = 0; i < [self numberOfColumns] ; i++) {
        w = [self contentWidthForColumn:i] + [self columnMargin];
        
        FLEXTableColumnHeader *cell = [[FLEXTableColumnHeader alloc] initWithFrame:CGRectMake(x, 0, w, [self topHeaderHeight] - 1)];
        cell.label.text = [self columnTitleForColumn:i];
        [self.headerScrollView addSubview:cell];
        
        FLEXTableColumnHeaderSortType type = [self.sortStatusDict[[self columnTitleForColumn:i]] integerValue];
        [cell changeSortStatusWithType:type];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(contentHeaderTap:)];
        [cell addGestureRecognizer:gesture];
        cell.userInteractionEnabled = YES;
        
        x = x + w;
    }
}

- (void)contentHeaderTap:(UIGestureRecognizer *)gesture
{
    FLEXTableColumnHeader *header = (FLEXTableColumnHeader *)gesture.view;
    NSString *string = header.label.text;
    FLEXTableColumnHeaderSortType currentType = [self.sortStatusDict[string] integerValue];
    FLEXTableColumnHeaderSortType newType ;
    
    switch (currentType) {
        case FLEXTableColumnHeaderSortTypeNone:
            newType = FLEXTableColumnHeaderSortTypeAsc;
            break;
        case FLEXTableColumnHeaderSortTypeAsc:
            newType = FLEXTableColumnHeaderSortTypeDesc;
            break;
        case FLEXTableColumnHeaderSortTypeDesc:
            newType = FLEXTableColumnHeaderSortTypeAsc;
            break;
    }
    
    self.sortStatusDict = @{header.label.text : @(newType)};
    [header changeSortStatusWithType:newType];
    [self.delegate multiColumnTableView:self didTapHeaderWithText:string sortType:newType];
    
}

- (void)loadContentData
{
    [self.contentTableView reloadData];
}

- (void)loadLeftViewData
{
    [self.leftTableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *backgroundColor = [UIColor whiteColor];
    if (indexPath.row % 2 != 0) {
        backgroundColor = [UIColor colorWithWhite:0.950 alpha:0.750];
    }
    
    if (tableView != self.leftTableView) {
        self.rowData = [self.dataSource contentAtRow:indexPath.row];
        FLEXTableContentCell *cell = [FLEXTableContentCell cellWithTableView:tableView
                                                                columnNumber:[self numberOfColumns]];
        cell.contentView.backgroundColor = backgroundColor;
        cell.delegate = self;
        
        for (int i = 0 ; i < cell.labels.count; i++) {
            
            UILabel *label  = cell.labels[i];
            label.textColor = [UIColor blackColor];
            
            NSString *content = [NSString stringWithFormat:@"%@",self.rowData[i]];
            if ([content isEqualToString:@"<null>"]) {
                label.textColor = [UIColor lightGrayColor];
                content = @"NULL";
            }
            label.text            = content;
            label.backgroundColor = backgroundColor;
        }
        return cell;
    }
    else {
        FLEXTableLeftCell *cell          = [FLEXTableLeftCell cellWithTableView:tableView];
        cell.contentView.backgroundColor = backgroundColor;
        cell.titlelabel.text             = [self rowTitleForRow:indexPath.row];
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfRowsInTableView:self];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataSource multiColumnTableView:self heightForContentCellInRow:indexPath.row];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.contentScrollView) {
        self.headerScrollView.contentOffset = scrollView.contentOffset;
    }
    else if (scrollView == self.headerScrollView) {
        self.contentScrollView.contentOffset = scrollView.contentOffset;
    }
    else if (scrollView == self.leftTableView) {
        self.contentTableView.contentOffset = scrollView.contentOffset;
    }
    else if (scrollView == self.contentTableView) {
        self.leftTableView.contentOffset = scrollView.contentOffset;
    }
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.leftTableView) {
        [self.contentTableView selectRowAtIndexPath:indexPath
                                           animated:NO
                                     scrollPosition:UITableViewScrollPositionNone];
    }
    else if (tableView == self.contentTableView) {
        [self.leftTableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark -
#pragma mark DataSource Accessor

- (NSInteger)numberOfrows
{
    return [self.dataSource numberOfRowsInTableView:self];
}

- (NSInteger)numberOfColumns
{
    return [self.dataSource numberOfColumnsInTableView:self];
}

- (NSString *)columnTitleForColumn:(NSInteger)column
{
    return [self.dataSource columnNameInColumn:column];
}

- (NSString *)rowTitleForRow:(NSInteger)row
{
    return [self.dataSource rowNameInRow:row];
}

- (NSString *)contentAtColumn:(NSInteger)column row:(NSInteger)row;
{
    return [self.dataSource contentAtColumn:column row:row];
}

- (CGFloat)contentWidthForColumn:(NSInteger)column
{
    return [self.dataSource multiColumnTableView:self widthForContentCellInColumn:column];
}

- (CGFloat)contentHeightForRow:(NSInteger)row
{
    return [self.dataSource multiColumnTableView:self heightForContentCellInRow:row];
}

- (CGFloat)topHeaderHeight
{
    return [self.dataSource heightForTopHeaderInTableView:self];
}

- (CGFloat)leftHeaderWidth
{
    return [self.dataSource widthForLeftHeaderInTableView:self];
}

- (CGFloat)columnMargin
{
    return kColumnMargin;
}


- (void)tableContentCell:(FLEXTableContentCell *)tableView labelDidTapWithText:(NSString *)text
{
    [self.delegate multiColumnTableView:self didTapLabelWithText:text];
}

@end
