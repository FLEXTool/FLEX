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
#import "FLEXKeychainTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsTableViewController.h"
#import "FLEXFileBrowserTableViewController.h"
#import "FLEXCookiesTableViewController.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXSystemLogTableViewController.h"
#import "FLEXNetworkHistoryTableViewController.h"
#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXTableViewSection.h"

static __weak UIWindow *s_applicationWindow = nil;

@interface FLEXGlobalsTableViewController ()

@property (nonatomic, readonly) NSArray<FLEXTableViewSection<FLEXGlobalsEntry *> *> *sections;
@property (nonatomic, copy) NSArray<FLEXTableViewSection<FLEXGlobalsEntry *> *> *filteredSections;

@end

@implementation FLEXGlobalsTableViewController

+ (NSString *)globalsTitleForSection:(FLEXGlobalsSection)section
{
    switch (section) {
        case FLEXGlobalsSectionProcessAndEvents:
            return @"Process and Events";
        case FLEXGlobalsSectionAppShortcuts:
            return @"App Shortcuts";
        case FLEXGlobalsSectionMisc:
            return @"Miscellaneous";
        case FLEXGlobalsSectionCustom:
            return @"Custom Additions";

        default:
            @throw NSInternalInconsistencyException;
    }
}

+ (FLEXGlobalsEntry *)globalsEntryForRow:(FLEXGlobalsRow)row
{
    switch (row) {
        case FLEXGlobalsRowAppClasses:
            return [FLEXClassesTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowAppKeychainItems:
            return [FLEXKeychainTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowAddressInspector:
            return [FLEXAddressExplorerCoordinator flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowSystemLibraries:
            return [FLEXLibrariesTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowLiveObjects:
            return [FLEXLiveObjectsTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowCookies:
            return [FLEXCookiesTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowBrowseBundle:
        case FLEXGlobalsRowBrowseContainer:
            return [FLEXFileBrowserTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowSystemLog:
            return [FLEXSystemLogTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowNetworkHistory:
            return [FLEXNetworkHistoryTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowKeyWindow:
            return [FLEXGlobalsEntry
                entryWithNameFuture:^NSString *{
                    return @"🔑  -[UIApplication keyWindow]";
                } viewControllerFuture:^UIViewController *{
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:s_applicationWindow];
                }
            ];
        case FLEXGlobalsRowRootViewController:
        case FLEXGlobalsRowProcessInfo:
        case FLEXGlobalsRowAppDelegate:
        case FLEXGlobalsRowUserDefaults:
        case FLEXGlobalsRowMainBundle:
        case FLEXGlobalsRowApplication:
        case FLEXGlobalsRowMainScreen:
        case FLEXGlobalsRowCurrentDevice:
        case FLEXGlobalsRowPasteboard:
            return [FLEXObjectExplorerFactory flex_concreteGlobalsEntry:row];

        default:
            @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:@"Missing globals case in switch" userInfo:nil
            ];
    }
}

+ (NSArray<FLEXTableViewSection<FLEXGlobalsEntry *> *> *)defaultGlobalSections
{
    static NSArray<FLEXTableViewSection<FLEXGlobalsEntry *> *> *sections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *rows = @[
            @[
                [self globalsEntryForRow:FLEXGlobalsRowNetworkHistory],
                [self globalsEntryForRow:FLEXGlobalsRowSystemLog],
                [self globalsEntryForRow:FLEXGlobalsRowProcessInfo],
                [self globalsEntryForRow:FLEXGlobalsRowLiveObjects],
                [self globalsEntryForRow:FLEXGlobalsRowAddressInspector],
                [self globalsEntryForRow:FLEXGlobalsRowSystemLibraries],
                [self globalsEntryForRow:FLEXGlobalsRowAppClasses],
            ],
            @[ // FLEXGlobalsSectionAppShortcuts
                [self globalsEntryForRow:FLEXGlobalsRowBrowseBundle],
                [self globalsEntryForRow:FLEXGlobalsRowBrowseContainer],
                [self globalsEntryForRow:FLEXGlobalsRowMainBundle],
                [self globalsEntryForRow:FLEXGlobalsRowUserDefaults],
                [self globalsEntryForRow:FLEXGlobalsRowAppKeychainItems],
                [self globalsEntryForRow:FLEXGlobalsRowApplication],
                [self globalsEntryForRow:FLEXGlobalsRowAppDelegate],
                [self globalsEntryForRow:FLEXGlobalsRowKeyWindow],
                [self globalsEntryForRow:FLEXGlobalsRowRootViewController],
                [self globalsEntryForRow:FLEXGlobalsRowCookies],
            ],
            @[ // FLEXGlobalsSectionMisc
                [self globalsEntryForRow:FLEXGlobalsRowPasteboard],
                [self globalsEntryForRow:FLEXGlobalsRowMainScreen],
                [self globalsEntryForRow:FLEXGlobalsRowCurrentDevice],
            ]
        ];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSInteger i = 0; i < FLEXGlobalsSectionCount - 1; i++) { // Skip custom
            NSString *title = [self globalsTitleForSection:i];
            [tmp addObject:[FLEXTableViewSection section:i title:title rows:rows[i]]];
        }
        
        sections = tmp.copy;
    });
    
    return sections;
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

    self.title = @"💪  FLEX";
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;

    // Table view data
    _sections = [[self class] defaultGlobalSections];
    if ([FLEXManager sharedManager].userGlobalEntries.count) {
        // Make custom section
        NSString *title = [[self class] globalsTitleForSection:FLEXGlobalsSectionCustom];
        FLEXTableViewSection *custom = [FLEXTableViewSection
            section:FLEXGlobalsSectionCustom
            title:title
            rows:[FLEXManager sharedManager].userGlobalEntries
        ];
        _sections = [_sections arrayByAddingObject:custom];
    }

    // Done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self
        action:@selector(donePressed:)
    ];
}

#pragma mark - Search Bar

- (void)updateSearchResults:(NSString *)newText {
    if (!newText.length) {
        self.filteredSections = nil;
        [self.tableView reloadData];
        return;
    }

    // Sections are a map of index to rows, since empty sections are omitted
    NSMutableArray *filteredSections = [NSMutableArray array];

    [self.sections enumerateObjectsUsingBlock:^(FLEXTableViewSection<FLEXGlobalsEntry *> *section, NSUInteger idx, BOOL *stop) {
        section = [section newSectionWithRowsMatchingQuery:newText];
        if (section) {
            [filteredSections addObject:section];
        }
    }];

    self.filteredSections = filteredSections.copy;
    [self.tableView reloadData];
}

#pragma mark - Misc

- (void)donePressed:(id)sender
{
    [self.delegate globalsViewControllerDidFinish:self];
}

#pragma mark - Table Data Helpers

- (FLEXGlobalsEntry *)globalEntryAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.filteredSections) {
        return self.filteredSections[indexPath.section][indexPath.row];
    } else {
        return self.sections[indexPath.section][indexPath.row];
    }
}

- (NSString *)titleForSection:(NSInteger)section
{
    if (self.filteredSections) {
        return self.filteredSections[section].title;
    } else {
        return self.sections[section].title;
    }
}

- (NSString *)titleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsEntry *entry = [self globalEntryAtIndexPath:indexPath];
    return entry.entryNameFuture();
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.filteredSections ? self.filteredSections.count : self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filteredSections) {
        return self.filteredSections[section].count;
    } else {
        return self.sections[section].count;
    }
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self titleForSection:section];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXGlobalsEntry *entry = [self globalEntryAtIndexPath:indexPath];
    if (entry.viewControllerFuture) {
        [self.navigationController pushViewController:entry.viewControllerFuture() animated:YES];
    } else {
        entry.rowAction(self);
    }
}

@end
