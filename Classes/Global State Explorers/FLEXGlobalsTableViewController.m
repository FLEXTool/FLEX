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

typedef NSString *(^FLEXGlobalsTableViewControllerEntryNameFuture)(void);
typedef UIViewController *(^FLEXGlobalsTableViewControllerViewControllerFuture)(void);

static UIWindow *s_applicationWindow = nil;
static NSMutableArray *s_globalEntries = nil;

@interface FLEXGlobalsTableViewControllerEntry : NSObject

@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerEntryNameFuture entryName;
@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerViewControllerFuture viewControllerToPush;

+ (instancetype)entryWithName:(FLEXGlobalsTableViewControllerEntryNameFuture)name
         viewControllerToPush:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerToPush;

@end

@implementation FLEXGlobalsTableViewControllerEntry

+ (instancetype)entryWithName:(FLEXGlobalsTableViewControllerEntryNameFuture)name
         viewControllerToPush:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerToPush
{
    NSParameterAssert(name);
    NSParameterAssert(viewControllerToPush);

    FLEXGlobalsTableViewControllerEntry *entry = [[self alloc] init];
    entry->_entryName = [name copy];
    entry->_viewControllerToPush = [viewControllerToPush copy];

    return entry;
}

@end

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
    FLEXGlobalsRowFileBrowser,
    FLEXGlobalsRowCount
};

@interface FLEXGlobalsTableViewController ()

/// [FLEXGlobalsTableViewControllerEntry *]
@property (nonatomic, readonly, copy) NSArray *entries;

@end

@implementation FLEXGlobalsTableViewController

+ (void)initialize
{
    if (self == [FLEXGlobalsTableViewController class]) {
        [self initializeStandardGlobalEntries];
    }
}

+ (void)initializeStandardGlobalEntries {
    s_globalEntries = [NSMutableArray array];

    for (FLEXGlobalsRow defaultRowIndex = 0; defaultRowIndex < FLEXGlobalsRowCount; defaultRowIndex++) {
        FLEXGlobalsTableViewControllerEntryNameFuture title = nil;
        FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture = nil;

        switch (defaultRowIndex) {
            case FLEXGlobalsRowAppClasses:
                title = ^NSString *{
                    return [NSString stringWithFormat:@"📕  %@ Classes", [FLEXUtility applicationName]];;
                };
                viewControllerFuture = ^UIViewController *{
                    FLEXClassesTableViewController *classesViewController = [[FLEXClassesTableViewController alloc] init];
                    classesViewController.binaryImageName = [FLEXUtility applicationImageName];

                    return classesViewController;
                };
                break;

            case FLEXGlobalsRowSystemLibraries: {
                NSString *titleString = @"📚  System Libraries";
                title = ^NSString *{
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
                title = ^NSString *{
                    return @"💩  Heap Objects";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXLiveObjectsTableViewController alloc] init];
                };

                break;

            case FLEXGlobalsRowAppDelegate:
                title = ^NSString *{
                    return [NSString stringWithFormat:@"👉  %@", [[[UIApplication sharedApplication] delegate] class]];
                };
                viewControllerFuture = ^UIViewController *{
                    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:appDelegate];
                };
                break;

            case FLEXGlobalsRowRootViewController:
                title = ^NSString *{
                    return [NSString stringWithFormat:@"🌴  %@", [[s_applicationWindow rootViewController] class]];
                };
                viewControllerFuture = ^UIViewController *{
                    UIViewController *rootViewController = [s_applicationWindow rootViewController];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:rootViewController];
                };
                break;

            case FLEXGlobalsRowUserDefaults:
                title = ^NSString *{
                    return @"🚶  +[NSUserDefaults standardUserDefaults]";
                };
                viewControllerFuture = ^UIViewController *{
                    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:standardUserDefaults];
                };
                break;

            case FLEXGlobalsRowApplication:
                title = ^NSString *{
                    return @"💾  +[UIApplication sharedApplication]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIApplication *sharedApplication = [UIApplication sharedApplication];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:sharedApplication];
                };
                break;

            case FLEXGlobalsRowKeyWindow:
                title = ^NSString *{
                   return @"🔑  -[UIApplication keyWindow]";
                };
                viewControllerFuture = ^UIViewController *{
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:s_applicationWindow];
                };
                break;

            case FLEXGlobalsRowMainScreen:
                title = ^NSString *{
                    return @"💻  +[UIScreen mainScreen]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIScreen *mainScreen = [UIScreen mainScreen];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:mainScreen];
                };
                break;

            case FLEXGlobalsRowCurrentDevice:
                title = ^NSString *{
                    return @"📱  +[UIDevice currentDevice]";
                };
                viewControllerFuture = ^UIViewController *{
                    UIDevice *currentDevice = [UIDevice currentDevice];
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:currentDevice];
                };
                break;

            case FLEXGlobalsRowFileBrowser:
                title = ^NSString *{
                    return @"📁  File Browser";
                };
                viewControllerFuture = ^UIViewController *{
                    return [[FLEXFileBrowserTableViewController alloc] init];
                };
                break;
            case FLEXGlobalsRowCount:
                break;
        }

        NSParameterAssert(title);
        NSParameterAssert(viewControllerFuture);
        
        [s_globalEntries addObject:[FLEXGlobalsTableViewControllerEntry entryWithName:title
                                                                 viewControllerToPush:viewControllerFuture]];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"🌎  Global State";
        _entries = [s_globalEntries copy];
    }
    return self;
}

#pragma mark - Public

+ (void)setApplicationWindow:(UIWindow *)applicationWindow
{
    s_applicationWindow = applicationWindow;
}

+ (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock
{
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsTableViewControllerEntry *entry = [FLEXGlobalsTableViewControllerEntry entryWithName:^NSString *{
        return entryName;
    }
                                                                               viewControllerToPush:^UIViewController *
                                                  {
                                                      return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
                                                  }];

    [s_globalEntries addObject:entry];    
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

    return entry.entryName();
}

- (UIViewController *)viewControllerToPushForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsTableViewControllerEntry *entry = [self globalEntryAtIndexPath:indexPath];

    return entry.viewControllerToPush();
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
