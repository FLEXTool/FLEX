//
//  FLEXHierarchyTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXHierarchyTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXHierarchyItem.h"
#import "FLEXHierarchyTableViewCell.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

static const NSInteger kFLEXHierarchyScopeViewsAtTapIndex = 0;
static const NSInteger kFLEXHierarchyScopeFullHierarchyIndex = 1;

@interface FLEXHierarchyTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray<FLEXHierarchyItem *> *allItems;
@property (nonatomic, strong) NSDictionary<NSValue *, NSNumber *> *depthsForViews;
@property (nonatomic, strong) NSArray<FLEXHierarchyItem *> *itemsAtTap;
@property (nonatomic, strong) FLEXHierarchyItem *selectedItem;
@property (nonatomic, strong) NSArray<FLEXHierarchyItem *> *displayedItems;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation FLEXHierarchyTableViewController

- (id)initWithItems:(NSArray *)allItems itemsAtTap:(NSArray *)itemsAtTap selectedItem:(FLEXHierarchyItem *)selectedItem depths:(NSDictionary *)depthsForItems
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.allItems = allItems;
        self.depthsForViews = depthsForItems;
        self.itemsAtTap = itemsAtTap;
        self.selectedItem = selectedItem;
        
        self.title = @"View Hierarchy";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    // Done button.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
    
    // A little more breathing room.
    self.tableView.rowHeight = 50.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // Separator inset clashes with persistent cell selection.
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = [FLEXUtility searchBarPlaceholderText];
    self.searchBar.delegate = self;
    if ([self showScopeBar]) {
        self.searchBar.showsScopeBar = YES;
        self.searchBar.scopeButtonTitles = @[@"Views at Tap", @"Full Hierarchy"];
    }
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
    
    [self updateDisplayedViews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self trySelectCellForSelectedViewWithScrollPosition:UITableViewScrollPositionMiddle];
}


#pragma mark Selection and Filtering Helpers

- (void)trySelectCellForSelectedViewWithScrollPosition:(UITableViewScrollPosition)scrollPosition
{
    NSUInteger selectedItemIndex = [self.displayedItems indexOfObject:self.selectedItem];
    if (selectedItemIndex != NSNotFound) {
        NSIndexPath *selectedItemIndexPath = [NSIndexPath indexPathForRow:selectedItemIndex inSection:0];
        [self.tableView selectRowAtIndexPath:selectedItemIndexPath animated:YES scrollPosition:scrollPosition];
    }
}

- (void)updateDisplayedViews
{
    NSArray<FLEXHierarchyItem *> *candidateItems = nil;
    if ([self showScopeBar]) {
        if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeViewsAtTapIndex) {
            candidateItems = self.itemsAtTap;
        } else if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeFullHierarchyIndex) {
            candidateItems = self.allItems;
        }
    } else {
        candidateItems = self.allItems;
    }
    
    if ([self.searchBar.text length] > 0) {
        self.displayedItems = [candidateItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXHierarchyItem *candidateItem, NSDictionary *bindings) {
            NSString *title = [candidateItem descriptionIncludingFrame:NO];
            NSString *candidateViewPointerAddress = [NSString stringWithFormat:@"%p", candidateItem.object];
            BOOL matchedViewPointerAddress = [candidateViewPointerAddress rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL matchedViewTitle = [title rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            return matchedViewPointerAddress || matchedViewTitle;
        }]];
    } else {
        self.displayedItems = candidateItems;
    }
    
    [self.tableView reloadData];
}

- (BOOL)showScopeBar
{
    return [self.itemsAtTap count] > 0;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateDisplayedViews];
    
    // If the search bar text field is active, don't scroll on selection because we may want to continue typing.
    // Otherwise, scroll so that the selected cell is visible.
    UITableViewScrollPosition scrollPosition = self.searchBar.isFirstResponder ? UITableViewScrollPositionNone : UITableViewScrollPositionMiddle;
    [self trySelectCellForSelectedViewWithScrollPosition:scrollPosition];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateDisplayedViews];
    [self trySelectCellForSelectedViewWithScrollPosition:UITableViewScrollPositionNone];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.displayedItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    FLEXHierarchyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FLEXHierarchyTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    FLEXHierarchyItem *item = self.displayedItems[indexPath.row];
    NSNumber *depth = [self.depthsForViews objectForKey:[NSValue valueWithNonretainedObject:item]];
    UIColor *viewColor = item.color;
    cell.textLabel.text = [item descriptionIncludingFrame:NO];
    cell.detailTextLabel.text = [item detailDescription];
    cell.viewColor = viewColor;
    cell.viewDepth = [depth integerValue];
    if ([item isInvisible]) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedItem = self.displayedItems[indexPath.row];
    [self.delegate hierarchyViewController:self didFinishWithSelectedItem:self.selectedItem];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    FLEXHierarchyItem *drillInItem = self.displayedItems[indexPath.row];
    FLEXObjectExplorerViewController *viewExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:drillInItem.object];
    [self.navigationController pushViewController:viewExplorer animated:YES];
}


#pragma mark - Button Actions

- (void)donePressed:(id)sender
{
    [self.delegate hierarchyViewController:self didFinishWithSelectedItem:self.selectedItem];
}

@end
