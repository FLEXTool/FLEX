//
//  FLEXObjectExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorerViewController.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXMultilineTableViewCell.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXInstancesTableViewController.h"
#import "FLEXTableView.h"
#import "FLEXTableViewCell.h"
#import "FLEXScopeCarousel.h"
#import "FLEXMetadataSection.h"
#import "FLEXSingleRowSection.h"
#import "FLEXShortcutsSection.h"
#import <objc/runtime.h>

#pragma mark - Private properties
@interface FLEXObjectExplorerViewController ()

@property (nonatomic, copy) NSString *filterText;
/// Every section in the table view, regardless of whether or not a section is empty.
@property (nonatomic, readonly) NSArray<FLEXExplorerSection *> *allSections;
/// Only displayed sections of the table view; empty sections are purged from this array.
@property (nonatomic) NSArray<FLEXExplorerSection *> *sections;
@property (nonatomic, readonly) FLEXSingleRowSection *descriptionSection;
@property (nonatomic, readonly) FLEXExplorerSection *customSection;
@property (nonatomic, readonly) FLEXSingleRowSection *referencesSection;
@property (nonatomic) NSIndexSet *customSectionVisibleIndexes;

@end

@implementation FLEXObjectExplorerViewController

#pragma mark - Initialization

+ (instancetype)exploringObject:(id)target
{
    return [self exploringObject:target customSection:[FLEXShortcutsSection forObject:target]];
}

+ (instancetype)exploringObject:(id)target customSection:(FLEXExplorerSection *)section
{
    return [[self alloc]
        initWithObject:target
        explorer:[FLEXObjectExplorer forObject:target]
        customSection:section
    ];
}

- (id)initWithObject:(id)target
            explorer:(__kindof FLEXObjectExplorer *)explorer
       customSection:(FLEXExplorerSection *)customSection
{
    NSParameterAssert(target);
    
    self = [super init];
    if (self) {
        _object = target;
        _explorer = explorer;
        _customSection = customSection;
        _allSections = [self makeSections];
    }

    return self;
}

#pragma mark - View controller lifecycle

- (void)loadView
{
    // TODO: grouped with rounded corners or not?
    FLEXTableView *tableView = [[FLEXTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView = tableView;

    // Register cell classes
    for (FLEXExplorerSection *section in self.allSections) {
        if (section.cellRegistrationMapping) {
            [tableView registerCells:section.cellRegistrationMapping];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Use [object class] here rather than object_getClass
    // to avoid the KVO prefix for observed objects
    self.title = [[self.object class] description];

    // Refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl
        addTarget:self
        action:@selector(refreshControlDidRefresh:)
        forControlEvents:UIControlEventValueChanged
    ];

    // Search
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;
    self.showsCarousel = YES;

    // Carousel scope bar
    [self.explorer reloadClassHierarchy];
    self.carousel.items = [self.explorer.classHierarchy flex_mapped:^id(Class cls, NSUInteger idx) {
        return NSStringFromClass(cls);
    }];
    
    // Initialize custom menu items for explorer screen
    UIMenuItem *copyObjectAddress = [[UIMenuItem alloc]
        initWithTitle:@"Copy Address"
        action:@selector(copyObjectAddress:)
    ];
    UIMenuController.sharedMenuController.menuItems = @[copyObjectAddress];
    [UIMenuController.sharedMenuController update];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload the entire table view rather than just the visible cells, because the filtered rows
    // may have changed (i.e. a change in the description row that causes it to get filtered out).
    [self reloadData];
}

#pragma mark - Private

- (void)refreshControlDidRefresh:(id)sender
{
    [self reloadData];
    [self.refreshControl endRefreshing];
}

- (NSArray<FLEXExplorerSection *> *)makeSections
{
    FLEXObjectExplorer *explorer = self.explorer;
    
    // Description section is only for instances
    if (self.explorer.objectIsInstance) {
        _descriptionSection = [FLEXSingleRowSection
             title:@"Description" reuse:kFLEXMultilineCell cell:^(FLEXTableViewCell *cell) {
                 cell.titleLabel.font = UIFont.flex_defaultTableCellFont;
                 cell.titleLabel.text = explorer.objectDescription;
             }
        ];
        self.descriptionSection.filterMatcher = ^BOOL(NSString *filterText) {
            return [explorer.objectDescription localizedCaseInsensitiveContainsString:filterText];
        };
    }

    // Object graph section
    _referencesSection = [FLEXSingleRowSection
        title:@"Object Graph" reuse:kFLEXDefaultCell cell:^(FLEXTableViewCell *cell) {
            cell.titleLabel.text = @"Other objects with ivars referencing this object";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    ];
    self.referencesSection.selectionAction = ^(UIViewController *host) {
        UIViewController *references = [FLEXInstancesTableViewController
            instancesTableViewControllerForInstancesReferencingObject:explorer.object
        ];
        [host.navigationController pushViewController:references animated:YES];
    };

    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[
        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindProperties],
        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindClassProperties],
        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindIvars],
        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindMethods],
        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindClassMethods],
        self.referencesSection
//        [FLEXMetadataSection explorer:self.explorer kind:FLEXMetadataKindClassHierarchy],
    ]];

    if (self.customSection) {
        [sections insertObject:self.customSection atIndex:0];
    }
    if (self.descriptionSection) {
        [sections insertObject:self.descriptionSection atIndex:0];
    }

    return sections.copy;
}

#pragma mark - Description

- (BOOL)shouldShowDescription
{
    // Hide if we have filter text; it is rarely
    // useful to see the description when searching
    // since it's already at the top of the screen
    if (self.filterText.length) {
        return NO;
    }

    return YES;
}

#pragma mark - Search

- (void)updateSearchResults:(NSString *)newText;
{
    self.filterText = newText;

    // Sections will adjust data based on this property
    for (FLEXExplorerSection *section in self.allSections) {
        section.filterText = newText;
    }

    // Check to see if class scope changed, update accordingly
    if (self.explorer.classScope != self.selectedScope) {
        self.explorer.classScope = self.selectedScope;
        for (FLEXExplorerSection *section in self.allSections) {
            [section reloadData];
        }
    }

    // Recalculate empty sections
    self.sections = [self nonemptySections];

    // Refresh table view
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

#pragma mark - Reloading

- (void)reloadData
{
    // Reload explorer
    [self.explorer reloadMetadata];

    // Reload sections
    for (FLEXExplorerSection *section in self.allSections) {
        [section reloadData];
    }

    // Recalculate displayed sections
    self.sections = [self nonemptySections];

    // Refresh table view
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (NSArray<FLEXExplorerSection *> *)nonemptySections
{
    return [self.allSections flex_filtered:^BOOL(FLEXExplorerSection *section, NSUInteger idx) {
        return section.numberOfRows > 0;
    }];
}

- (BOOL)sectionHasActions:(NSInteger)section
{
    return self.sections[section] == self.descriptionSection;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sections[section].numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section].title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuse = [self.sections[indexPath.section] reuseIdentifierForRow:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
    [self.sections[indexPath.section] configureCell:cell forRow:indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For the description section, we want that nice slim looking row.
    // Other rows use the automatic size.
    FLEXExplorerSection *section = self.sections[indexPath.section];
    if (section == self.descriptionSection) {
        NSString *text = self.explorer.objectDescription;
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName : UIFont.flex_defaultTableCellFont }];
        return [FLEXMultilineTableViewCell preferredHeightWithAttributedText:attributedText inTableViewWidth:self.tableView.frame.size.width style:tableView.style showsAccessory:NO];
    }

    return UITableViewAutomaticDimension;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.sections[indexPath.section] canSelectRow:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXExplorerSection *section = self.sections[indexPath.section];

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

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionHasActions:indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    // Only the description section has "actions"
    if (self.sections[indexPath.section] == self.descriptionSection) {
        return action == @selector(copy:) || action == @selector(copyObjectAddress:);
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:action withObject:indexPath];
#pragma clang diagnostic pop
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self.sections[indexPath.section] didPressInfoButtonAction:indexPath.row](self);
}


#pragma mark - UIMenuController

/// Prevent the search bar from trying to use us as a responder
///
/// Our table cells will use the UITableViewDelegate methods
/// to make sure we can perform the actions we want to
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

- (void)copy:(NSIndexPath *)indexPath
{
    FLEXExplorerSection *section = self.sections[indexPath.section];
    UIPasteboard.generalPasteboard.string = ({
        NSString *copy = [section titleForRow:indexPath.row];
        NSString *subtitle = [section subtitleForRow:indexPath.row];

        if (subtitle.length) {
            copy = [NSString stringWithFormat:@"%@\n\n%@", copy, subtitle];
        }

        // If no string was provided, don't overwrite the pasteboard
        copy.length > 2 ? copy : UIPasteboard.generalPasteboard.string;
    });
}

- (void)copyObjectAddress:(NSIndexPath *)indexPath
{
    UIPasteboard.generalPasteboard.string = [FLEXUtility addressOfObject:self.object];
}

@end
