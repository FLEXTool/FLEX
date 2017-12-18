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

@property (nonatomic, strong) NSArray<NSString *> *tables;

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
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FLEXTableListViewControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"FLEXTableListViewControllerCell"];
    }
    cell.textLabel.text = self.tables[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXTableContentViewController *contentViewController = [[FLEXTableContentViewController alloc] init];
    
    contentViewController.contentsArray = [_dbm queryAllDataWithTableName:self.tables[indexPath.row]];
    contentViewController.columnsArray = [_dbm queryAllColumnsWithTableName:self.tables[indexPath.row]];
    
    contentViewController.title = self.tables[indexPath.row];
    [self.navigationController pushViewController:contentViewController animated:YES];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%lu tables", (unsigned long)self.tables.count];
}

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
