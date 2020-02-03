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
#import "FLEXObjcRuntimeViewController.h"
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
#import "FLEXGlobalsSection.h"

@interface FLEXGlobalsTableViewController ()
/// Only displayed sections of the table view; empty sections are purged from this array.
@property (nonatomic, copy) NSArray<FLEXGlobalsSection *> *sections;
/// Every section in the table view, regardless of whether or not a section is empty.
@property (nonatomic, readonly) NSArray<FLEXGlobalsSection *> *allSections;
@end

@implementation FLEXGlobalsTableViewController

+ (NSString *)globalsTitleForSection:(FLEXGlobalsSectionKind)section
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
        case FLEXGlobalsRowAppKeychainItems:
            return [FLEXKeychainTableViewController flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowAddressInspector:
            return [FLEXAddressExplorerCoordinator flex_concreteGlobalsEntry:row];
        case FLEXGlobalsRowBrowseRuntime:
            return [FLEXObjcRuntimeViewController flex_concreteGlobalsEntry:row];
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

+ (NSArray<FLEXGlobalsSection *> *)defaultGlobalSections
{
    static NSArray<FLEXGlobalsSection *> *sections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *rowsBySection = @[
            @[
                [self globalsEntryForRow:FLEXGlobalsRowNetworkHistory],
                [self globalsEntryForRow:FLEXGlobalsRowSystemLog],
                [self globalsEntryForRow:FLEXGlobalsRowProcessInfo],
                [self globalsEntryForRow:FLEXGlobalsRowLiveObjects],
                [self globalsEntryForRow:FLEXGlobalsRowAddressInspector],
                [self globalsEntryForRow:FLEXGlobalsRowBrowseRuntime],
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
        
        sections = [NSArray flex_forEachUpTo:rowsBySection.count map:^FLEXGlobalsSection *(NSUInteger i) {
            NSString *title = [self globalsTitleForSection:i];
            return [FLEXGlobalsSection title:title rows:rowsBySection[i]];
        }];
    });
    
    return sections;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"💪  FLEX";
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;

    // Table view data
    _allSections = [[self class] defaultGlobalSections];
    if ([FLEXManager sharedManager].userGlobalEntries.count) {
        // Make custom section
        NSString *title = [[self class] globalsTitleForSection:FLEXGlobalsSectionCustom];
        FLEXGlobalsSection *custom = [FLEXGlobalsSection
            title:title
            rows:[FLEXManager sharedManager].userGlobalEntries
        ];
        _allSections = [_allSections arrayByAddingObject:custom];
    }
    self.sections = self.allSections;
}

#pragma mark - Search Bar

- (void)updateSearchResults:(NSString *)newText {
    // Sections will adjust data based on this property
    for (FLEXTableViewSection *section in self.allSections) {
        section.filterText = newText;
    }

    // Recalculate empty sections
    self.sections = [self nonemptySections];

    // Refresh table view
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (NSArray<FLEXGlobalsSection *> *)nonemptySections
{
    return [self.allSections flex_filtered:^BOOL(FLEXTableViewSection *section, NSUInteger idx) {
        return section.numberOfRows > 0;
    }];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sections[section].numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    [self.sections[indexPath.section] configureCell:cell forRow:indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section].title;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXTableViewSection *section = self.sections[indexPath.section];

    void (^action)(UIViewController *) = [section didSelectRowAction:indexPath.row];
    UIViewController *details = [section viewControllerToPushForRow:indexPath.row];

    if (action) {
        action(self);
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (details) {
        [self.navigationController pushViewController:details animated:YES];
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Row is selectable but has no action or view controller"];
    }
}

@end
