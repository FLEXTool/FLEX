//
//  FLEXHierarchyTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXHierarchyTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXElement.h"
#import "FLEXHierarchyTableViewCell.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

static const NSInteger kFLEXHierarchyScopeViewsAtTapIndex = 0;
static const NSInteger kFLEXHierarchyScopeFullHierarchyIndex = 1;

@interface FLEXHierarchyTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray<FLEXElement *> *allElements;
@property (nonatomic, strong) NSDictionary<NSValue *, NSNumber *> *depthsForElements;
@property (nonatomic, strong) NSArray<FLEXElement *> *elementsAtTap;
@property (nonatomic, strong) FLEXElement *selectedElement;
@property (nonatomic, strong) NSArray<FLEXElement *> *displayedElements;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation FLEXHierarchyTableViewController

- (id)initWithElements:(NSArray *)allElements elementsAtTap:(NSArray *)elementsAtTap selectedElement:(FLEXElement *)selectedElement depths:(NSDictionary *)depthsForElements
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.allElements = allElements;
        self.depthsForElements = depthsForElements;
        self.elementsAtTap = elementsAtTap;
        self.selectedElement = selectedElement;
        
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
    NSUInteger selectedElementIndex = [self.displayedElements indexOfObjectPassingTest:^BOOL(FLEXElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return self.selectedElement.object == obj.object;
    }];
    if (selectedElementIndex != NSNotFound) {
        NSIndexPath *selectedElementIndexPath = [NSIndexPath indexPathForRow:selectedElementIndex inSection:0];
        [self.tableView selectRowAtIndexPath:selectedElementIndexPath animated:YES scrollPosition:scrollPosition];
    }
}

- (void)updateDisplayedViews
{
    NSArray<FLEXElement *> *candidateElements = nil;
    if ([self showScopeBar]) {
        if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeViewsAtTapIndex) {
            candidateElements = self.elementsAtTap;
        } else if (self.searchBar.selectedScopeButtonIndex == kFLEXHierarchyScopeFullHierarchyIndex) {
            candidateElements = self.allElements;
        }
    } else {
        candidateElements = self.allElements;
    }
    
    if ([self.searchBar.text length] > 0) {
        self.displayedElements = [candidateElements filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXElement *candidateElement, NSDictionary *bindings) {
            NSString *title = [candidateElement descriptionIncludingFrame:NO];
            NSString *candidateElementPointerAddress = [NSString stringWithFormat:@"%p", candidateElement.object];
            BOOL matchedElementPointerAddress = [candidateElementPointerAddress rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL matchedElementTitle = [title rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
            return matchedElementPointerAddress || matchedElementTitle;
        }]];
    } else {
        self.displayedElements = candidateElements;
    }
    
    [self.tableView reloadData];
}

- (BOOL)showScopeBar
{
    return [self.elementsAtTap count] > 0;
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
    return [self.displayedElements count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    FLEXHierarchyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FLEXHierarchyTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    FLEXElement *element = self.displayedElements[indexPath.row];
    NSNumber *depth = [self.depthsForElements objectForKey:[NSValue valueWithNonretainedObject:element]];
    UIColor *viewColor = element.color;
    cell.textLabel.text = [element descriptionIncludingFrame:NO];
    cell.detailTextLabel.text = [element detailDescription];
    cell.viewColor = viewColor;
    cell.viewDepth = [depth integerValue];
    if (element.isInvisible) {
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
    self.selectedElement = self.displayedElements[indexPath.row];
    [self.delegate hierarchyViewController:self didFinishWithSelectedElement:self.selectedElement];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    FLEXElement *drillInElement = self.displayedElements[indexPath.row];
    FLEXObjectExplorerViewController *viewExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:drillInElement.object];
    [self.navigationController pushViewController:viewExplorer animated:YES];
}


#pragma mark - Button Actions

- (void)donePressed:(id)sender
{
    [self.delegate hierarchyViewController:self didFinishWithSelectedElement:self.selectedElement];
}

@end
