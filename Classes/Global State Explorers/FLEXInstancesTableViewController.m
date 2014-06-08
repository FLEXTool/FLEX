//
//  FLEXInstancesTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXInstancesTableViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"

@interface FLEXInstancesTableViewController ()

@end

@implementation FLEXInstancesTableViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.instances count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        cell.textLabel.font = cellFont;
        cell.detailTextLabel.font = cellFont;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    id instance = [self.instances objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%p", instance];
    cell.detailTextLabel.text = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:instance];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id instance = [self.instances objectAtIndex:indexPath.row];
    FLEXObjectExplorerViewController *drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:instance];
    [self.navigationController pushViewController:drillInViewController animated:YES];
}

@end
