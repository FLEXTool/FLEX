//
//  FLEXGlobalsTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXGlobalsTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXLibrariesTableViewController.h"
#import "FLEXClassesTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsTableViewController.h"
#import "FLEXFileBrowserTableViewController.h"

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowAppClasses,
    FLEXGlobalsRowSystemLibraries,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowAppDelegate,
    FLEXGlobalsRowRootViewController,
    FLEXGlobalsRowUserDefaults,
    FLEXGlobalsRowApplication,
    FLEXGlobalsRowKeyWindow,
    FLEXGlobalsRowMainScreen,
    FLEXGlobalsRowCurrentDevice,
    FLEXGlobalsRowFileBrowser
};

@interface FLEXGlobalsTableViewController ()

@property (nonatomic, strong) NSArray *rows;

@end

@implementation FLEXGlobalsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"🌎  Global State";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.rows = @[@(FLEXGlobalsRowLiveObjects),
                  @(FLEXGlobalsRowFileBrowser),
                  @(FLEXGlobalsRowSystemLibraries),
                  @(FLEXGlobalsRowAppClasses),
                  @(FLEXGlobalsRowAppDelegate),
                  @(FLEXGlobalsRowRootViewController),
                  @(FLEXGlobalsRowUserDefaults),
                  @(FLEXGlobalsRowApplication),
                  @(FLEXGlobalsRowKeyWindow),
                  @(FLEXGlobalsRowMainScreen),
                  @(FLEXGlobalsRowCurrentDevice)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
}

- (void)donePressed:(id)sender
{
    [self.delegate globalsViewControllerDidFinish:self];
}


#pragma mark - Table Data Helpers

- (FLEXGlobalsRow)rowTypeAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rows objectAtIndex:indexPath.row] unsignedIntegerValue];
}

- (NSString *)titleForRowType:(FLEXGlobalsRow)rowType
{
    NSString *title = nil;
    switch (rowType) {
        case FLEXGlobalsRowAppClasses:
            title = [NSString stringWithFormat:@"📕  %@ Classes", [FLEXUtility applicationName]];
            break;
            
        case FLEXGlobalsRowSystemLibraries:
            title = @"📚  System Libraries";
            break;
        
        case FLEXGlobalsRowLiveObjects:
            title = @"💩  Heap Objects";
            break;
            
        case FLEXGlobalsRowAppDelegate:
            title = [NSString stringWithFormat:@"👉  %@", [[[UIApplication sharedApplication] delegate] class]];
            break;
            
        case FLEXGlobalsRowRootViewController:
            title = [NSString stringWithFormat:@"🌴  %@", [[self.applicationWindow rootViewController] class]];
            break;
            
        case FLEXGlobalsRowUserDefaults:
            title = @"🚶  +[NSUserDefaults standardUserDefaults]";
            break;
            
        case FLEXGlobalsRowApplication:
            title = @"💾  +[UIApplication sharedApplication]";
            break;
            
        case FLEXGlobalsRowKeyWindow:
            title = @"🔑  -[UIApplication keyWindow]";
            break;
            
        case FLEXGlobalsRowMainScreen:
            title = @"💻  +[UIScreen mainScreen]";
            break;
            
        case FLEXGlobalsRowCurrentDevice:
            title = @"📱  +[UIDevice currentDevice]";
            break;
            
        case FLEXGlobalsRowFileBrowser:
            title = @"📁  File Browser";
            break;
    }
    return title;
}

- (UIViewController *)drillDownViewControllerForRowType:(FLEXGlobalsRow)rowType
{
    UIViewController *viewController = nil;
    switch (rowType) {
        case FLEXGlobalsRowAppClasses: {
            FLEXClassesTableViewController *classesViewController = [[FLEXClassesTableViewController alloc] init];
            classesViewController.binaryImageName = [FLEXUtility applicationImageName];
            viewController = classesViewController;
        } break;
            
        case FLEXGlobalsRowSystemLibraries: {
            FLEXLibrariesTableViewController *librariesViewController = [[FLEXLibrariesTableViewController alloc] init];
            librariesViewController.title = [self titleForRowType:FLEXGlobalsRowSystemLibraries];
            viewController = librariesViewController;
        } break;
            
        case FLEXGlobalsRowLiveObjects: {
            viewController = [[FLEXLiveObjectsTableViewController alloc] init];
        } break;
            
        case FLEXGlobalsRowAppDelegate: {
            id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:appDelegate];
        } break;
            
        case FLEXGlobalsRowRootViewController: {
            UIViewController *rootViewController = [self.applicationWindow rootViewController];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:rootViewController];
        } break;
            
        case FLEXGlobalsRowUserDefaults: {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:standardUserDefaults];
        } break;
            
        case FLEXGlobalsRowApplication: {
            UIApplication *sharedApplication = [UIApplication sharedApplication];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:sharedApplication];
        } break;
            
        case FLEXGlobalsRowKeyWindow: {
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.applicationWindow];
        } break;
            
        case FLEXGlobalsRowMainScreen: {
            UIScreen *mainScreen = [UIScreen mainScreen];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:mainScreen];
        } break;
            
        case FLEXGlobalsRowCurrentDevice: {
            UIDevice *currentDevice = [UIDevice currentDevice];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentDevice];
        } break;
            
        case FLEXGlobalsRowFileBrowser: {
            viewController = [[FLEXFileBrowserTableViewController alloc] init];
        }
    }
    return viewController;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rows count];
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
    FLEXGlobalsRow rowType = [self rowTypeAtIndexPath:indexPath];
    cell.textLabel.text = [self titleForRowType:rowType];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsRow rowType = [self rowTypeAtIndexPath:indexPath];
    UIViewController *drillDownViewController = [self drillDownViewControllerForRowType:rowType];
    [self.navigationController pushViewController:drillDownViewController animated:YES];
}

@end
