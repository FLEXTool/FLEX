//
//  PTTableListViewController.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXTableListViewController.h"
#import "FLEXDatabaseManager.h"
#import "FLEXSQLiteDatabaseManager.h"
#import "FLEXRealmDatabaseManager.h"
#import "FLEXTableContentViewController.h"
#import "FLEXMutableListSection.h"
#import "FLEXDBPinnedTablesRepository.h"
#import "NSUserDefaults+FLEXDBPinnedTablesRepository.h"
#import "NSArray+FLEX.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface FLEXTableListViewController ()
@property (nonatomic, readonly) id<FLEXDatabaseManager> dbm;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, readonly) FLEXMutableListSection<NSString *> *tables;
@property (nonatomic, readonly) FLEXMutableListSection<NSString *> *pinnedTables;
@property (nonatomic, readonly) id<FLEXDBPinnedTablesRepository> pinnedTablesRepo;

+ (NSArray<NSString *> *)supportedSQLiteExtensions;
+ (NSArray<NSString *> *)supportedRealmExtensions;

@end

@implementation FLEXTableListViewController

- (instancetype)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _path = path.copy;
        _dbm = [self databaseManagerForFileAtPath:path];
        _pinnedTablesRepo = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
    
    // Compose query button //

    UIBarButtonItem *composeQuery = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self
        action:@selector(queryButtonPressed)
    ];
    // Cannot run custom queries on realm databases
    composeQuery.enabled = [self.dbm
        respondsToSelector:@selector(executeStatement:)
    ];
    
    [self addToolbarItems:@[composeQuery]];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.tableView addGestureRecognizer:longPressGesture];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    NSArray<NSString *> *allTables = [self.dbm queryAllTables];
    NSArray<NSString *> *pinnedTables = [self.pinnedTablesRepo pinnedTables];
    NSArray<NSString *> *unpinnedTables = [allTables flex_filtered:^BOOL(NSString *tableName, NSUInteger idx) {
        return ![pinnedTables containsObject:tableName];
    }];
    
    _tables = [FLEXMutableListSection list:unpinnedTables
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    _pinnedTables = [FLEXMutableListSection list:pinnedTables
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    self.tables.selectionHandler = ^(FLEXTableListViewController *host, NSString *tableName) {
        NSArray *rows = [host.dbm queryAllDataInTable:tableName];
        NSArray *columns = [host.dbm queryAllColumnsOfTable:tableName];
        NSArray *rowIDs = nil;
        if ([host.dbm respondsToSelector:@selector(queryRowIDsInTable:)]) {        
            rowIDs = [host.dbm queryRowIDsInTable:tableName];
        }
        UIViewController *resultsScreen = [FLEXTableContentViewController
            columns:columns rows:rows rowIDs:rowIDs tableName:tableName database:host.dbm
        ];
        [host.navigationController pushViewController:resultsScreen animated:YES];
    };
    
    self.pinnedTables.selectionHandler = ^(FLEXTableListViewController *host, NSString *tableName) {
        NSArray *rows = [host.dbm queryAllDataInTable:tableName];
        NSArray *columns = [host.dbm queryAllColumnsOfTable:tableName];
        NSArray *rowIDs = nil;
        if ([host.dbm respondsToSelector:@selector(queryRowIDsInTable:)]) {
            rowIDs = [host.dbm queryRowIDsInTable:tableName];
        }
        UIViewController *resultsScreen = [FLEXTableContentViewController
            columns:columns rows:rows rowIDs:rowIDs tableName:tableName database:host.dbm
        ];
        [host.navigationController pushViewController:resultsScreen animated:YES];
    };
    
    return @[self.pinnedTables, self.tables];
}

- (void)reloadData {
    self.tables.customTitle = [NSString
        stringWithFormat:@"Tables (%@) - Long press to pin/unpin", @(self.tables.filteredList.count)
    ];
    self.pinnedTables.customTitle = [NSString
        stringWithFormat:@"Pinned Tables (%@) - Long press to pin/unpin", @(self.pinnedTables.filteredList.count)
    ];
    
    [super reloadData];
}
    
- (void)queryButtonPressed {
    FLEXSQLiteDatabaseManager *database = self.dbm;
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Execute an SQL query");
        make.textField(nil);
        make.button(@"Run").handler(^(NSArray<NSString *> *strings) {
            FLEXSQLResult *result = [database executeStatement:strings[0]];
            
            if (result.message) {
                [FLEXAlert showAlert:@"Message" message:result.message from:self];
            } else {
                UIViewController *resultsScreen = [FLEXTableContentViewController
                    columns:result.columns rows:result.rows rowIDs:nil tableName:@"" database:nil
                ];
                
                [self.navigationController pushViewController:resultsScreen animated:YES];
            }
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}
    
- (id<FLEXDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path {
    NSString *pathExtension = path.pathExtension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = FLEXTableListViewController.supportedSQLiteExtensions;
    if ([sqliteExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXSQLiteDatabaseManager managerForDatabase:path];
    }
    
    NSArray<NSString *> *realmExtensions = FLEXTableListViewController.supportedRealmExtensions;
    if (realmExtensions != nil && [realmExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXRealmDatabaseManager managerForDatabase:path];
    }
    
    return nil;
}


#pragma mark - FLEXTableListViewController

+ (BOOL)supportsExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = FLEXTableListViewController.supportedSQLiteExtensions;
    if (sqliteExtensions.count > 0 && [sqliteExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }
    
    NSArray<NSString *> *realmExtensions = FLEXTableListViewController.supportedRealmExtensions;
    if (realmExtensions.count > 0 && [realmExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }
    
    return NO;
}

+ (NSArray<NSString *> *)supportedSQLiteExtensions {
    return @[@"db", @"sqlite", @"sqlite3"];
}

+ (NSArray<NSString *> *)supportedRealmExtensions {
    if (NSClassFromString(@"RLMRealm") == nil) {
        return nil;
    }
    
    return @[@"realm"];
}

#pragma MARK - User Actions -

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        if (indexPath) {
            FLEXMutableListSection *section = (FLEXMutableListSection *) self.sections[indexPath.section];
            NSString *longPressedTable = section.list[indexPath.row];
            BOOL isPinnedTable = section == self.pinnedTables;
            [self showPinTableActionSheet:longPressedTable toPin:!isPinnedTable source: [self.tableView cellForRowAtIndexPath:indexPath]];
        }
    }
}

- (void)showPinTableActionSheet:(NSString *)tableName toPin:(BOOL)toPin source:(id)source {
    [FLEXAlert makeSheet:^(FLEXAlert * _Nonnull make) {
        make.title(tableName);
        make.button(toPin ? @"Pin ": @"Unpin").handler(^(NSArray<NSString *> * _Nonnull strings) {
            toPin ? [self.pinnedTablesRepo pinTable:tableName] : [self.pinnedTablesRepo unpinTable:tableName];
            self.filterDelegate.allSections = [self makeSections];
            [self reloadData];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:source];
}

@end
