//
//  FLEXGlobalsTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXGlobalsTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
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
#import "FLEXAddressExplorerCoordinator.h"

static __weak UIWindow *s_applicationWindow = nil;

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowNetworkHistory,
    FLEXGlobalsRowSystemLog,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowAddressInspector,
    FLEXGlobalsRowFileBrowser,
    FLEXGlobalsCookies,    
    FLEXGlobalsRowSystemLibraries,
    FLEXGlobalsRowAppClasses,
    FLEXGlobalsRowAppDelegate,
    FLEXGlobalsRowRootViewController,
    FLEXGlobalsRowUserDefaults,
    FLEXGlobalsRowMainBundle,
    FLEXGlobalsRowApplication,
    FLEXGlobalsRowKeyWindow,
    FLEXGlobalsRowMainScreen,
    FLEXGlobalsRowCurrentDevice,
    FLEXGlobalsRowCount
};

@interface FLEXGlobalsTableViewController ()

@property (nonatomic, readonly) NSArray<FLEXGlobalsTableViewControllerEntry *> *entries;

@end

@implementation FLEXGlobalsTableViewController

+ (FLEXGlobalsTableViewControllerEntry *)globalsEntryForRow:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowAppClasses:
            return [FLEXClassesTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowAddressInspector:
            return [FLEXAddressExplorerCoordinator flex_concreteGlobalsEntry];
        case FLEXGlobalsRowSystemLibraries:
            return [FLEXLibrariesTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowLiveObjects:
            return [FLEXLiveObjectsTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsCookies:
            return [FLEXCookiesTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowFileBrowser:
            return [FLEXFileBrowserTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowSystemLog:
            return [FLEXSystemLogTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowNetworkHistory:
            return [FLEXNetworkHistoryTableViewController flex_concreteGlobalsEntry];
        case FLEXGlobalsRowAppDelegate:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return [NSString stringWithFormat:@"👉  %@", [[UIApplication sharedApplication].delegate class]];
                } viewControllerFuture:^UIViewController *{
                    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:appDelegate];
                }
            ];
        case FLEXGlobalsRowRootViewController:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return [NSString stringWithFormat:@"🌴  %@", [s_applicationWindow.rootViewController class]];
                } viewControllerFuture:^UIViewController *{
                    UIViewController *rootViewController = s_applicationWindow.rootViewController;
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:rootViewController];
                }
            ];
        case FLEXGlobalsRowUserDefaults:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"🚶  +[NSUserDefaults standardUserDefaults]";
                } viewControllerFuture:^UIViewController *{
                    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:standardUserDefaults];
                }
            ];
        case FLEXGlobalsRowMainBundle:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"📦  +[NSBundle mainBundle]";
                } viewControllerFuture:^UIViewController *{
                    NSBundle *mainBundle = [NSBundle mainBundle];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:mainBundle];
                }
            ];
        case FLEXGlobalsRowApplication:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"💾  +[UIApplication sharedApplication]";
                } viewControllerFuture:^UIViewController *{
                    UIApplication *sharedApplication = [UIApplication sharedApplication];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:sharedApplication];
                }
            ];
        case FLEXGlobalsRowKeyWindow:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"🔑  -[UIApplication keyWindow]";
                } viewControllerFuture:^UIViewController *{
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:s_applicationWindow];
                }
            ];
        case FLEXGlobalsRowMainScreen:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"💻  +[UIScreen mainScreen]";
                } viewControllerFuture:^UIViewController *{
                    UIScreen *mainScreen = [UIScreen mainScreen];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:mainScreen];
                }
            ];

        case FLEXGlobalsRowCurrentDevice:
            return [FLEXGlobalsTableViewControllerEntry
                entryWithNameFuture:^NSString *{
                    return @"📱  +[UIDevice currentDevice]";
                } viewControllerFuture:^UIViewController *{
                    UIDevice *currentDevice = [UIDevice currentDevice];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:currentDevice];
                }
            ];

        default:
            @throw NSInternalInconsistencyException;
    }
}

+ (NSArray<FLEXGlobalsTableViewControllerEntry *> *)defaultGlobalEntries
{
    NSMutableArray<FLEXGlobalsTableViewControllerEntry *> *defaultGlobalEntries = [NSMutableArray array];
    for (FLEXGlobalsRow defaultRowIndex = 0; defaultRowIndex < FLEXGlobalsRowCount; defaultRowIndex++) {
        [defaultGlobalEntries addObject:[self globalsEntryForRow:defaultRowIndex]];
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

#pragma mark - Misc

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
    FLEXGlobalsTableViewControllerEntry *entry = [self globalEntryAtIndexPath:indexPath];
    if (entry.viewControllerFuture) {
        [self.navigationController pushViewController:entry.viewControllerFuture() animated:YES];
    } else {
        entry.rowAction(self);
    }
}

@end
