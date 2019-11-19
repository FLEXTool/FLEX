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

@interface FLEXTableListViewController ()
{
    id<FLEXDatabaseManager> _dbm;
    NSString *_databasePath;
}

@property (nonatomic) NSArray<NSString *> *tables;
@property (nonatomic) NSArray<NSString *> *filteredTables;

+ (NSArray<NSString *> *)supportedSQLiteExtensions;
+ (NSArray<NSString *> *)supportedRealmExtensions;

@end

@implementation FLEXTableListViewController

- (instancetype)initWithPath:(NSString *)path
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _databasePath = [path copy];
        _dbm = [self databaseManagerForFileAtPath:_databasePath];
        [_dbm open];
        [self getAllTables];
    }
    return self;
}

- (id<FLEXDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path
{
    NSString *pathExtension = path.pathExtension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = [FLEXTableListViewController supportedSQLiteExtensions];
    if ([sqliteExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [[FLEXSQLiteDatabaseManager alloc] initWithPath:path];
    }
    
    NSArray<NSString *> *realmExtensions = [FLEXTableListViewController supportedRealmExtensions];
    if (realmExtensions != nil && [realmExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [[FLEXRealmDatabaseManager alloc] initWithPath:path];
    }
    
    return nil;
}

- (void)getAllTables
{
    NSArray<NSDictionary<NSString *, id> *> *resultArray = [_dbm queryAllTables];
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *dict in resultArray) {
        NSString *columnName = (NSString *)dict[@"name"] ?: @"";
        [array addObject:columnName];
    }
    self.tables = array;
    self.filteredTables = array;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsSearchBar = YES;
}

#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)searchText
{
    if (searchText.length > 0) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", searchText];
        self.filteredTables = [self.tables filteredArrayUsingPredicate:searchPredicate];
    } else {
        self.filteredTables = self.tables;
    }
    [self.tableView reloadData];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredTables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FLEXTableListViewControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"FLEXTableListViewControllerCell"];
    }
    cell.textLabel.text = self.filteredTables[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXTableContentViewController *contentViewController = [FLEXTableContentViewController new];
    
    contentViewController.contentsArray = [_dbm queryAllDataWithTableName:self.filteredTables[indexPath.row]];
    contentViewController.columnsArray = [_dbm queryAllColumnsWithTableName:self.filteredTables[indexPath.row]];
    
    contentViewController.title = self.filteredTables[indexPath.row];
    [self.navigationController pushViewController:contentViewController animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Tables (%lu)", (unsigned long)self.filteredTables.count];
}

#pragma mark - FLEXTableListViewController

+ (BOOL)supportsExtension:(NSString *)extension
{
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

+ (NSArray<NSString *> *)supportedSQLiteExtensions
{
    return @[@"db", @"sqlite", @"sqlite3"];
}

+ (NSArray<NSString *> *)supportedRealmExtensions
{
    if (NSClassFromString(@"RLMRealm") == nil) {
        return nil;
    }
    
    return @[@"realm"];
}

@end
