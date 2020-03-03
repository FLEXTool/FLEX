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
#import "NSArray+Functional.h"
#import "FLEXAlert.h"

@interface FLEXTableListViewController ()
@property (nonatomic, readonly) id<FLEXDatabaseManager> dbm;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic) NSArray<NSString *> *tables;
@property (nonatomic) NSArray<NSString *> *filteredTables;

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
    [self getAllTables];
    
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
                    columns:result.columns rows:result.rows
                ];
                
                [self.navigationController pushViewController:resultsScreen animated:YES];
            }
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}
    
- (id<FLEXDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path {
    NSString *pathExtension = path.pathExtension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = [FLEXTableListViewController supportedSQLiteExtensions];
    if ([sqliteExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXSQLiteDatabaseManager managerForDatabase:path];
    }
    
    NSArray<NSString *> *realmExtensions = [FLEXTableListViewController supportedRealmExtensions];
    if (realmExtensions != nil && [realmExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXRealmDatabaseManager managerForDatabase:path];
    }
    
    return nil;
}

- (void)getAllTables {
    self.tables = self.filteredTables = [self.dbm queryAllTables];
}


#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)searchText {
    if (searchText.length) {
        self.filteredTables = [self.tables flex_filtered:^BOOL(NSString *tableName, NSUInteger idx) {
            return [tableName containsString:searchText];
        }];
    } else {
        self.filteredTables = self.tables;
    }
    
    [self.tableView reloadData];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredTables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FLEXTableListViewControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"FLEXTableListViewControllerCell"];
    }
    cell.textLabel.text = self.filteredTables[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rows = [self.dbm queryAllDataInTable:self.filteredTables[indexPath.row]];
    NSArray *columns = [self.dbm queryAllColumnsOfTable:self.filteredTables[indexPath.row]];
    
    UIViewController *resultsScreen = [FLEXTableContentViewController columns:columns rows:rows];
    resultsScreen.title = self.filteredTables[indexPath.row];
    [self.navigationController pushViewController:resultsScreen animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Tables (%lu)", (unsigned long)self.filteredTables.count];
}

#pragma mark - FLEXTableListViewController

+ (BOOL)supportsExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = [FLEXTableListViewController supportedSQLiteExtensions];
    if (sqliteExtensions.count > 0 && [sqliteExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }
    
    NSArray<NSString *> *realmExtensions = [FLEXTableListViewController supportedRealmExtensions];
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

@end
