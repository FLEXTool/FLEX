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

@property (nonatomic, strong)FLEXMultiColumnTableView *multiColumView;

@end

@implementation FLEXTableContentViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        CGRect rectStatus = [UIApplication sharedApplication].statusBarFrame;
        CGFloat y = 64;
        if (rectStatus.size.height == 0) {
            y = 32;
        }
        _multiColumView = [[FLEXMultiColumnTableView alloc] initWithFrame:
                           CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.height - y)];
        
        _multiColumView.autoresizingMask          = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _multiColumView.backgroundColor           = [UIColor whiteColor];
        _multiColumView.dataSource                = self;
        _multiColumView.delegate                  = self;
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        
        [self.view addSubview:_multiColumView];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.multiColumView reloadData];
    
}

#pragma mark -
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
        NSDictionary *dic = self.contentsArray[row];
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
        NSDictionary *dic = self.contentsArray[row];
        for (int i = 0; i < self.columnsArray.count; i ++) {
            [result addObject:dic[self.columnsArray[i]]];
        }
        return  result;
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
    NSDictionary *attrs = @{@"NSFontAttributeName":[UIFont systemFontOfSize:17.0]};
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
    
    NSArray *sortContentData = [self.contentsArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        if ([obj1 objectForKey:text] == [NSNull null]) {
            return NSOrderedAscending;
        }
        if ([obj2 objectForKey:text] == [NSNull null]) {
            return NSOrderedDescending;
        }
        NSComparisonResult result =  [[obj1 objectForKey:text] compare:[obj2 objectForKey:text]];
        
        return result;
    }];
    if (sortType == FLEXTableColumnHeaderSortTypeDesc) {
        NSEnumerator *contentReverseEvumerator = [sortContentData reverseObjectEnumerator];
        sortContentData = [NSArray arrayWithArray:[contentReverseEvumerator allObjects]];
    }
    
    self.contentsArray = sortContentData;
    [self.multiColumView reloadData];
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
            
            _multiColumView.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 32);
        }
        else {
            _multiColumView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
        }
        [self.view setNeedsLayout];
    } completion:nil];
}


@end
