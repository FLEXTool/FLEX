//
//  FLEXInfoTableViewController.m
//  UICatalog
//
//  Created by Dal Rupnik on 07/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXGlobalsTableViewController.h"
#import "FLEXInfoTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXLibrariesTableViewController.h"
#import "FLEXClassesTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsTableViewController.h"
#import "FLEXFileBrowserTableViewController.h"
#import "FLEXGlobalsTableViewControllerEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXNetworkTableViewController.h"

static __weak UIWindow *s_applicationWindow = nil;

@interface FLEXInfoTableViewController ()

@property (nonatomic, strong) NSMutableArray *entries;

@end

@implementation FLEXInfoTableViewController

- (NSMutableArray *)entries
{
    if (!_entries)
    {
        _entries = [NSMutableArray array];
    }
    
    return _entries;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Information";
        
        [self buildEntries];
    }
    return self;
}

#pragma mark - Public

+ (void)setApplicationWindow:(UIWindow *)applicationWindow
{
    s_applicationWindow = applicationWindow;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
}

#pragma mark -

- (void)donePressed:(id)sender
{
    [self.delegate viewControllerDidFinish:self];
}

#pragma mark - Internal

- (void)buildEntries
{
    //
    // Build entries for FLEX.
    //
    
    [self.entries removeAllObjects];
    
    for (NSInteger rowIndex = 0; rowIndex < 4; rowIndex++)
    {
        FLEXGlobalsTableViewControllerEntryNameFuture titleFuture = nil;
        FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture = nil;
        
        switch (rowIndex)
        {
            case 0:
                titleFuture = ^NSString *
                {
                    return @"🌍  Global State";
                };
                viewControllerFuture = ^UIViewController *{
                    [FLEXGlobalsTableViewController setApplicationWindow:s_applicationWindow];
                    return [[FLEXGlobalsTableViewController alloc] init];
                };
                
                break;
                
            case 1:
                titleFuture = ^NSString *{
                    return @"💩  Heap Objects";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXLiveObjectsTableViewController alloc] init];
                };
                
                break;
                
            case 2:
                titleFuture = ^NSString *{
                    return @"📁  File Browser";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXFileBrowserTableViewController alloc] init];
                };
                break;
            case 3:
                titleFuture = ^NSString *{
                    return @"💬  Network";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXNetworkTableViewController alloc] init];
                };
                break;
            default:
                break;
        }
        
        [self.entries addObject:[FLEXGlobalsTableViewControllerEntry entryWithNameFuture:titleFuture viewControllerFuture:viewControllerFuture]];
    }
}

#pragma mark - Table Data Helpers

- (FLEXGlobalsTableViewControllerEntry *)globalEntryAtIndexPath:(NSIndexPath *)indexPath
{
    return self.entries[indexPath.row];
}

- (NSString *)titleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsTableViewControllerEntry *entry = [self globalEntryAtIndexPath:indexPath];
    
    return entry.entryNameFuture();
}

- (UIViewController *)viewControllerToPushForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsTableViewControllerEntry *entry = [self globalEntryAtIndexPath:indexPath];
    
    return entry.viewControllerFuture();
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
    }
    
    cell.textLabel.text = [self titleForRowAtIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewControllerToPush = [self viewControllerToPushForRowAtIndexPath:indexPath];
    
    [self.navigationController pushViewController:viewControllerToPush animated:YES];
}

@end
