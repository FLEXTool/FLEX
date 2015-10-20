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
#import "FLEXCookiesTableViewController.h"
#import "FLEXGlobalsTableViewControllerEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXSystemLogTableViewController.h"
#import "FLEXNetworkHistoryTableViewController.h"

static __weak UIWindow *s_applicationWindow = nil;

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowNetworkHistory,
    FLEXGlobalsRowSystemLog,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowFileBrowser,
    FLEXGlobalsCookies,    
    FLEXGlobalsRowSystemLibraries,
    FLEXGlobalsRowAppClasses,
    FLEXGlobalsRowAppDelegate,
    FLEXGlobalsRowRootViewController,
    FLEXGlobalsRowUserDefaults,
    FLEXGlobalsRowApplication,
    FLEXGlobalsRowKeyWindow,
    FLEXGlobalsRowMainScreen,
    FLEXGlobalsRowCurrentDevice,
    FLEXGlobalsRowCount
};

@interface FLEXGlobalsTableViewController ()

/// [FLEXGlobalsTableViewControllerEntry *]
@property (nonatomic, readonly, copy) NSArray *entries;

@end

@implementation FLEXGlobalsTableViewController

/// [FLEXGlobalsTableViewControllerEntry *]
+ (NSArray *)defaultGlobalEntries
{
    NSMutableArray *defaultGlobalEntries = [NSMutableArray array];

    for (FLEXGlobalsRow defaultRowIndex = 0; defaultRowIndex < FLEXGlobalsRowCount; defaultRowIndex++) {
        FLEXGlobalsTableViewControllerEntryNameFuture titleFuture = nil;
        FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture = nil;

        switch (defaultRowIndex) {
            case FLEXGlobalsRowAppClasses:
                titleFuture = ^NSString *{
                    return [NSString stringWithFormat:@"📕  %@ Classes", [FLEXUtility applicationName]];
                };
                viewControllerFuture = ^UIViewController *{
                    FLEXClassesTableViewController *classesViewController = [[FLEXClassesTableViewController alloc] init];
                    classesViewController.binaryImageName = [FLEXUtility applicationImageName];

                    return classesViewController;
                };
                break;

            case FLEXGlobalsRowSystemLibraries: {
                NSString *titleString = @"📚  System Libraries";
                titleFuture = ^NSString *{
                    return titleString;
                };
                viewControllerFuture = ^UIViewController *{
                    FLEXLibrariesTableViewController *librariesViewController = [[FLEXLibrariesTableViewController alloc] init];
                    librariesViewController.title = titleString;

                    return librariesViewController;
                };
                break;
            }

            case FLEXGlobalsRowLiveObjects:
                titleFuture = ^NSString *{
                    return @"💩  Heap Objects";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXLiveObjectsTableViewController alloc] init];
                };

                break;

            case FLEXGlobalsRowAppDelegate:
                titleFuture = ^NSString *{
                    return [NSString stringWithFormat:@"👉  %@", [[[UIApplication sharedApplication] delegate] class]];
                };
                viewControllerFuture = ^UIViewController *{
                    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:appDelegate];
                };
                break;

            case FLEXGlobalsRowRootViewController:
                titleFuture = ^NSString *{
                    return [NSString stringWithFormat:@"🌴  %@", [[s_applicationWindow rootViewController] class]];
                };
                viewControllerFuture = ^UIViewController *{
                    UIViewController *rootViewController = [s_applicationWindow rootViewController];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:rootViewController];
                };
                break;

            case FLEXGlobalsRowUserDefaults:
                titleFuture = ^NSString *{
                    return @"🚶  +[NSUserDefaults standardUserDefaults]";
                };
                viewControllerFuture = ^UIViewController *{
                    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:standardUserDefaults];
                };
                break;

            case FLEXGlobalsRowApplication:
                titleFuture = ^NSString *{
                    return @"💾  +[UIApplication sharedApplication]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIApplication *sharedApplication = [UIApplication sharedApplication];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:sharedApplication];
                };
                break;

            case FLEXGlobalsRowKeyWindow:
                titleFuture = ^NSString *{
                    return @"🔑  -[UIApplication keyWindow]";
                };
                viewControllerFuture = ^UIViewController *{
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:s_applicationWindow];
                };
                break;

            case FLEXGlobalsRowMainScreen:
                titleFuture = ^NSString *{
                    return @"💻  +[UIScreen mainScreen]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIScreen *mainScreen = [UIScreen mainScreen];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:mainScreen];
                };
                break;

            case FLEXGlobalsRowCurrentDevice:
                titleFuture = ^NSString *{
                    return @"📱  +[UIDevice currentDevice]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIDevice *currentDevice = [UIDevice currentDevice];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:currentDevice];
                };
                break;

            case FLEXGlobalsCookies:
                titleFuture = ^NSString *{
                    return @"🍪  Cookies";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXCookiesTableViewController alloc] init];
                };
                break;                
                
            case FLEXGlobalsRowFileBrowser:
                titleFuture = ^NSString *{
                    return @"📁  File Browser";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXFileBrowserTableViewController alloc] init];
                };
                break;

            case FLEXGlobalsRowSystemLog:
                titleFuture = ^{
                    return @"⚠️  System Log";
                };
                viewControllerFuture = ^{
                    return [[FLEXSystemLogTableViewController alloc] init];
                };
                break;

            case FLEXGlobalsRowNetworkHistory:
                titleFuture = ^{
                    return @"📡  Network History";
                };
                viewControllerFuture = ^{
                    return [[FLEXNetworkHistoryTableViewController alloc] init];
                };
                break;
            case FLEXGlobalsRowCount:
                break;
        }

        NSParameterAssert(titleFuture);
        NSParameterAssert(viewControllerFuture);

        [defaultGlobalEntries addObject:[FLEXGlobalsTableViewControllerEntry entryWithNameFuture:titleFuture viewControllerFuture:viewControllerFuture]];
    }

    return defaultGlobalEntries;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"💪  FLEX";
        _entries = [[[self class] defaultGlobalEntries] arrayByAddingObjectsFromArray:[FLEXManager sharedManager].userGlobalEntries];
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
    [self.delegate globalsViewControllerDidFinish:self];
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
        cell.textLabel.font = [FLEXUtility defaultFontOfSize:14.0];
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
