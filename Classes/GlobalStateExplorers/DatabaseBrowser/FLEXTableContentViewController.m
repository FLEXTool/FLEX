//
//  PTTableContentViewController.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXTableContentViewController.h"
#import "FLEXMultiColumnTableView.h"
#import "FLEXWebViewController.h"


@interface FLEXTableContentViewController ()<FLEXMultiColumnTableViewDataSource, FLEXMultiColumnTableViewDelegate>

@property (nonatomic) FLEXMultiColumnTableView *multiColumnView;

@end

@implementation FLEXTableContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.view addSubview:self.multiColumnView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.multiColumnView reloadData];
}

#pragma mark -

#pragma mark init SubView
- (FLEXMultiColumnTableView *)multiColumnView {
    if (!_multiColumnView) {
        _multiColumnView = [[FLEXMultiColumnTableView alloc] initWithFrame:
                           CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        
        _multiColumnView.autoresizingMask          = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
        _multiColumnView.backgroundColor           = UIColor.whiteColor;
        _multiColumnView.dataSource                = self;
        _multiColumnView.delegate                  = self;
    }
    return _multiColumnView;
}
#pragma mark MultiColumnTableView DataSource

- (NSInteger)numberOfColumnsInTableView:(FLEXMultiColumnTableView *)tableView
{
    return self.columnsArray.count;
}
- (NSInteger)numberOfRowsInTableView:(FLEXMultiColumnTableView *)tableView
{
    return self.contentsArray.count;
}


- (NSString *)columnNameInColumn:(NSInteger)column
{
    return self.columnsArray[column];
}


- (NSString *)rowNameInRow:(NSInteger)row
{
    return [NSString stringWithFormat:@"%ld",(long)row];
}

- (NSString *)contentAtColumn:(NSInteger)column row:(NSInteger)row
{
    if (self.contentsArray.count > row) {
        NSDictionary<NSString *, id> *dic = self.contentsArray[row];
        if (self.contentsArray.count > column) {
            return [NSString stringWithFormat:@"%@",[dic objectForKey:self.columnsArray[column]]];
        }
    }
    return @"";
}

- (NSArray *)contentAtRow:(NSInteger)row
{
    NSMutableArray *result = [NSMutableArray array];
    if (self.contentsArray.count > row) {
        NSDictionary<NSString *, id> *dic = self.contentsArray[row];
        for (int i = 0; i < self.columnsArray.count; i ++) {
            [result addObject:dic[self.columnsArray[i]]];
        }
        return result;
    }
    return nil;
}

- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView
      heightForContentCellInRow:(NSInteger)row
{
    return 40;
}

- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView
    widthForContentCellInColumn:(NSInteger)column
{
    return 120;
}

- (CGFloat)heightForTopHeaderInTableView:(FLEXMultiColumnTableView *)tableView
{
    return 40;
}

- (CGFloat)widthForLeftHeaderInTableView:(FLEXMultiColumnTableView *)tableView
{
    NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)self.contentsArray.count];
    NSDictionary<NSString *, id> *attrs = @{@"NSFontAttributeName":[UIFont systemFontOfSize:17.0]};
    CGSize size =   [str boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attrs context:nil].size;
    return size.width + 20;
}

#pragma mark -
#pragma mark MultiColumnTableView Delegate


- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView didTapLabelWithText:(NSString *)text
{
    FLEXWebViewController * detailViewController = [[FLEXWebViewController alloc] initWithText:text];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView didTapHeaderWithText:(NSString *)text sortType:(FLEXTableColumnHeaderSortType)sortType
{
    
    NSArray<NSDictionary<NSString *, id> *> *sortContentData = [self.contentsArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary<NSString *, id> * obj1, NSDictionary<NSString *, id> * obj2) {
        
        if ([obj1 objectForKey:text] == [NSNull null]) {
            return NSOrderedAscending;
        }
        if ([obj2 objectForKey:text] == [NSNull null]) {
            return NSOrderedDescending;
        }
        
        if (![[obj1 objectForKey:text] respondsToSelector:@selector(compare:)] && ![[obj2 objectForKey:text] respondsToSelector:@selector(compare:)]) {
            return NSOrderedSame;
        }
        
        NSComparisonResult result =  [[obj1 objectForKey:text] compare:[obj2 objectForKey:text]];
        
        return result;
    }];
    if (sortType == FLEXTableColumnHeaderSortTypeDesc) {
        NSEnumerator *contentReverseEnumerator = sortContentData.reverseObjectEnumerator;
        sortContentData = [NSArray arrayWithArray:contentReverseEnumerator.allObjects];
    }
    
    self.contentsArray = sortContentData;
    [self.multiColumnView reloadData];
}

#pragma mark -
#pragma mark About Transition

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection
                 withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        if (newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            
            self->_multiColumnView.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 32);
        }
        else {
            self->_multiColumnView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
        }
        [self.view setNeedsLayout];
    } completion:nil];
}


@end
