//
//  FLEXHierarchyTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXHierarchyTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXHierarchyTableViewCell.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

static const NSInteger kFLEXHierarchyScopeViewsAtTapIndex = 0;
static const NSInteger kFLEXHierarchyScopeFullHierarchyIndex = 1;

@interface FLEXHierarchyTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *allViews;
@property (nonatomic, strong) NSDictionary *depthsForViews;
@property (nonatomic, strong) NSArray *viewsAtTap;
@property (nonatomic, strong) UIView *selectedView;
@property (nonatomic, strong) NSArray *displayedViews;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation FLEXHierarchyTableViewController

- (id)initWithViews:(NSArray *)allViews viewsAtTap:(NSArray *)viewsAtTap selectedView:(UIView *)selectedView depths:(NSDictionary *)depthsForViews
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.allViews = allViews;
        self.depthsForViews = depthsForViews;
        self.viewsAtTap = viewsAtTap;
        self.selectedView = selectedView;
        
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
    NSUInteger selectedViewIndex = [self.displayedViews indexOfObject:self.selectedView];
    if (selectedViewIndex != NSNotFound) {
        NSIndexPath *selectedViewIndexPath = [NSIndexPath indexPathForRow:selectedViewIndex inSection:0];
        [self.tableView selectRowAtIndexPath:selectedViewIndexPath animated:YES scrollPosition:scrollPosition];
    }
}

- (void)updateDisplayedViews
{
    NSArray *candidateViews = nil;
    if ([self showScopeBar]) {
        if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeViewsAtTapIndex) {
            candidateViews = self.viewsAtTap;
        } else if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeFullHierarchyIndex) {
            candidateViews = self.allViews;
        }
    } else {
        candidateViews = self.allViews;
    }
    
    if ([self.searchBar.text length] > 0) {
        self.displayedViews = [candidateViews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *candidateView, NSDictionary *bindings) {
            NSString *title = [FLEXUtility descriptionForView:candidateView includingFrame:NO];
            NSString *candidateViewPointerAddress = [NSString stringWithFormat:@"%p", candidateView];
            BOOL matchedViewPointerAddress = [candidateViewPointerAddress rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL matchedViewTitle = [title rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            return matchedViewPointerAddress || matchedViewTitle;
        }]];
    } else {
        self.displayedViews = candidateViews;
    }
    
    [self.tableView reloadData];
}

- (BOOL)showScopeBar
{
    return [self.viewsAtTap count] > 0;
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
    return [self.displayedViews count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    FLEXHierarchyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FLEXHierarchyTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    UIView *view = self.displayedViews[indexPath.row];
    NSNumber *depth = [self.depthsForViews objectForKey:[NSValue valueWithNonretainedObject:view]];
    UIColor *viewColor = [FLEXUtility consistentRandomColorForObject:view];
    cell.textLabel.text = [FLEXUtility descriptionForView:view includingFrame:NO];
    cell.detailTextLabel.text = [FLEXUtility detailDescriptionForView:view];
    cell.viewColor = viewColor;
    cell.viewDepth = [depth integerValue];
    if (view.isHidden || view.alpha < 0.01) {
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
    self.selectedView = self.displayedViews[indexPath.row];
    [self.delegate hierarchyViewController:self didFinishWithSelectedView:self.selectedView];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UIView *drillInView = self.displayedViews[indexPath.row];
    FLEXObjectExplorerViewController *viewExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:drillInView];
    [self.navigationController pushViewController:viewExplorer animated:YES];
}


#pragma mark - Button Actions

- (void)donePressed:(id)sender
{
    [self.delegate hierarchyViewController:self didFinishWithSelectedView:self.selectedView];
}

@end
