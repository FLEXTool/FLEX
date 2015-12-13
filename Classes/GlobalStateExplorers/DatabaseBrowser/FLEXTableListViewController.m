//
//  PTTableListViewController.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXTableListViewController.h"
#import "FLEXDatabaseManager.h"
#import "FLEXTableContentViewController.h"

@interface FLEXTableListViewController ()
{
    FLEXDatabaseManager *_dbm;
    NSString *_databasePath;
}

@property (nonatomic, strong) NSArray *tables;

@end

@implementation FLEXTableListViewController


- (instancetype)initWithPath:(NSString *)path
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _databasePath = [path copy];
        _dbm = [[FLEXDatabaseManager alloc] initWithPath:path];
        [_dbm open];
        [self getAllTables];
    }
    return self;
}

- (void)getAllTables
{
    NSArray *resultArray = [_dbm queryAllTables];
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in resultArray) {
        [array addObject:dict[@"name"]];
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

@end
