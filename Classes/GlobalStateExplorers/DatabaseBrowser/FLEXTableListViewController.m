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
#import "NSArray+FLEX.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface FLEXTableListViewController ()
@property (nonatomic, readonly) id<FLEXDatabaseManager> dbm;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, readonly) FLEXMutableListSection<NSString *> *tables;
@property (nonatomic, readonly) FLEXMutableListSection<NSString *> *pinnedTables;

+ (NSArray<NSString *> *)supportedSQLiteExtensions;
+ (NSArray<NSString *> *)supportedRealmExtensions;

@end

@implementation FLEXTableListViewController

- (instancetype)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _path = path.copy;
        _dbm = [self databaseManagerForFileAtPath:path];
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
    _tables = [FLEXMutableListSection list:[self.dbm queryAllTables]
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    _pinnedTables = [FLEXMutableListSection list:[self.dbm queryAllTables]
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    [_pinnedTables setCustomTitle:@"Pinned Tables (Long press on a table to pin/unpin)"];
    
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
        stringWithFormat:@"Tables (%@)", @(self.tables.filteredList.count)
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
            NSLog(@"handle me");
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:source];
}

@end
