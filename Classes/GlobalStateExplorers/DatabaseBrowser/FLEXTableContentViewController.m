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
#import "FLEXUtility.h"
#import "UIBarButtonItem+FLEX.h"

@interface FLEXTableContentViewController () <
    FLEXMultiColumnTableViewDataSource, FLEXMultiColumnTableViewDelegate
>
@property (nonatomic, readonly) NSArray<NSString *> *columns;
@property (nonatomic) NSMutableArray<NSArray *> *rows;
@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, nullable) NSMutableArray<NSString *> *rowIDs;
@property (nonatomic, readonly, nullable) id<FLEXDatabaseManager> databaseManager;

@property (nonatomic) FLEXMultiColumnTableView *multiColumnView;
@end

@implementation FLEXTableContentViewController

+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                   rows:(NSArray<NSArray<NSString *> *> *)rowData
                 rowIDs:(nullable NSArray<NSString *> *)rowIDs
              tableName:(NSString *)tableName
               database:(nullable id<FLEXDatabaseManager>)databaseManager {
    FLEXTableContentViewController *controller = [self new];
    controller->_columns = columnNames.copy;
    controller->_rows = rowData.mutableCopy;
    controller->_rowIDs = rowIDs.mutableCopy;
    controller->_tableName = tableName.copy;
    controller->_databaseManager = databaseManager;
    return controller;
}

- (void)loadView {
    [super loadView];
    
    [self.view addSubview:self.multiColumnView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.tableName;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.multiColumnView reloadData];
    [self setupToolbarItems];
}

- (FLEXMultiColumnTableView *)multiColumnView {
    if (!_multiColumnView) {
        _multiColumnView = [[FLEXMultiColumnTableView alloc]
            initWithFrame:FLEXRectSetSize(CGRectZero, self.view.frame.size)
        ];
        
        _multiColumnView.dataSource = self;
        _multiColumnView.delegate   = self;
    }
    
    return _multiColumnView;
}

#pragma mark MultiColumnTableView DataSource

- (NSInteger)numberOfColumnsInTableView:(FLEXMultiColumnTableView *)tableView {
    return self.columns.count;
}

- (NSInteger)numberOfRowsInTableView:(FLEXMultiColumnTableView *)tableView {
    return self.rows.count;
}

- (NSString *)columnTitle:(NSInteger)column {
    return self.columns[column];
}

- (NSString *)rowTitle:(NSInteger)row {
    return @(row).stringValue;
}

- (NSArray *)contentForRow:(NSInteger)row {
    return self.rows[row];
}

- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView
      heightForContentCellInRow:(NSInteger)row {
    return 40;
}

- (CGFloat)multiColumnTableView:(FLEXMultiColumnTableView *)tableView
    minWidthForContentCellInColumn:(NSInteger)column {
    return 100;
}

- (CGFloat)heightForTopHeaderInTableView:(FLEXMultiColumnTableView *)tableView {
    return 40;
}

- (CGFloat)widthForLeftHeaderInTableView:(FLEXMultiColumnTableView *)tableView {
    NSString *str = [NSString stringWithFormat:@"%lu",(unsigned long)self.rows.count];
    NSDictionary *attrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:17.0] };
    CGSize size = [str boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14)
        options:NSStringDrawingUsesLineFragmentOrigin
        attributes:attrs context:nil
    ].size;
    
    return size.width + 20;
}


#pragma mark MultiColumnTableView Delegate

- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView didSelectRow:(NSInteger)row {
    NSArray<NSString *> *fields = [self.rows[row] flex_mapped:^id(NSString *field, NSUInteger idx) {
        return [NSString stringWithFormat:@"%@:\n%@", self.columns[idx], field];
    }];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title([@"Row " stringByAppendingString:@(row).stringValue]);
        NSString *message = [fields componentsJoinedByString:@"\n\n"];
        make.message(message);
        make.button(@"Copy").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = message;
        });
        
        // Option to delete row
        BOOL hasRowID = self.rows.count && row < self.rows.count;
        if (hasRowID) {
            make.button(@"Delete").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
                NSString *deleteRow = [NSString stringWithFormat:
                    @"DELETE FROM %@ WHERE rowid = %@",
                    self.tableName, self.rowIDs[row]
                ];
                
                [self executeStatementAndShowResult:deleteRow completion:^(BOOL success) {
                    // Remove deleted row and reload view
                    if (success) {
                        [self.rowIDs removeObjectAtIndex:row];
                        [self.rows removeObjectAtIndex:row];
                        [self.multiColumnView reloadData];
                    }
                }];
            });
        }
        
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

- (void)multiColumnTableView:(FLEXMultiColumnTableView *)tableView
    didSelectHeaderForColumn:(NSInteger)column
                    sortType:(FLEXTableColumnHeaderSortType)sortType {
    
    NSArray<NSArray *> *sortContentData = [self.rows
        sortedArrayWithOptions:NSSortStable
        usingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
            id a = obj1[column], b = obj2[column];
            if (a == NSNull.null) {
                return NSOrderedAscending;
            }
            if (b == NSNull.null) {
                return NSOrderedDescending;
            }
        
            if ([a respondsToSelector:@selector(compare:options:)] &&
                [b respondsToSelector:@selector(compare:options:)]) {
                return [a compare:b options:NSNumericSearch];
            }
            
            if ([a respondsToSelector:@selector(compare:)] && [b respondsToSelector:@selector(compare:)]) {
                return [a compare:b];
            }
            
            return NSOrderedSame;
        }
    ];
    
    if (sortType == FLEXTableColumnHeaderSortTypeDesc) {
        sortContentData = sortContentData.reverseObjectEnumerator.allObjects.copy;
    }
    
    self.rows = sortContentData.mutableCopy;
    [self.multiColumnView reloadData];
}

#pragma mark - About Transition

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        if (newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            self.multiColumnView.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 32);
        }
        else {
            self.multiColumnView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
        }
        
        [self.view setNeedsLayout];
    } completion:nil];
}

#pragma mark - Toolbar

- (void)setupToolbarItems {
    // We do not support modifying realm databases
    if (![self.databaseManager respondsToSelector:@selector(executeStatement:)]) {
        return;
    }
    
    UIBarButtonItem *trashButton = [FLEXBarButtonItemSystem(Trash, self, @selector(trashPressed))
        flex_withTintColor:UIColor.redColor
    ];
    trashButton.enabled = self.databaseManager && self.rows.count;
    self.toolbarItems = @[UIBarButtonItem.flex_flexibleSpace, trashButton];
}

- (void)trashPressed {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Delete All Rows");
        make.message(@"All rows in this table will be permanently deleted.\nDo you want to proceed?");
        
        make.button(@"Yes, I'm sure").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            NSString *deleteAll = [NSString stringWithFormat:@"DELETE FROM %@", self.tableName];
            [self executeStatementAndShowResult:deleteAll completion:^(BOOL success) {
                // Only dismiss on success
                if (success) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}

#pragma mark - Helpers

- (void)executeStatementAndShowResult:(NSString *)statement completion:(void (^_Nullable)(BOOL success))completion {
    FLEXSQLResult *result = [self.databaseManager executeStatement:statement];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        if (result.isError) {
            make.title(@"Error");
        }
        
        make.message(result.message ?: @"<no output>");
        make.button(@"Dismiss").cancelStyle().handler(^(NSArray<NSString *> *_) {
            if (completion) {
                completion(!result.isError);
            }
        });
    } showFrom:self];
}


@end
