//
//  FLEXHierarchyTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXHierarchyTableViewController.h"
#import "NSMapTable+FLEX_Subscripting.h"
#import "FLEXUtility.h"
#import "FLEXHierarchyTableViewCell.h"
#import "FLEXSwiftUIInspector.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXResources.h"
#import "FLEXWindow.h"

typedef NS_ENUM(NSUInteger, FLEXHierarchyScope) {
    FLEXHierarchyScopeFullHierarchy,
    FLEXHierarchyScopeViewsAtTap
};

@interface FLEXHierarchyTableViewController ()

/// Views, and the SwiftUI view nodes listed under their hosting views
@property (nonatomic) NSArray *allViews;
/// Map of view's or node's address to its depth
/// @((uintptr_t)(__bridge void *)view) -> depth
@property (nonatomic) NSMapTable<NSNumber *, NSNumber *> *depthsForViews;
@property (nonatomic) NSArray *viewsAtTap;
@property (nonatomic) NSArray *displayedViews;
@property (nonatomic, readonly) BOOL showScopeBar;

@end

@implementation FLEXHierarchyTableViewController

+ (instancetype)windows:(NSArray<UIWindow *> *)allWindows
             viewsAtTap:(NSArray *)viewsAtTap
           selectedView:(id)selected {
    NSParameterAssert(allWindows.count);

    NSArray *allViews = [self allViewsInHierarchy:allWindows];
    NSMapTable *depths = [self hierarchyDepthsForViews:allViews];
    return [[self alloc] initWithViews:allViews viewsAtTap:viewsAtTap selectedView:selected depths:depths];
}

- (instancetype)initWithViews:(NSArray *)allViews
                   viewsAtTap:(NSArray *)viewsAtTap
                 selectedView:(id)selectedView
                       depths:(NSMapTable<NSNumber *, NSNumber *> *)depthsForViews {
    NSParameterAssert(allViews);
    NSParameterAssert(depthsForViews.count == allViews.count);

    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.allViews = allViews;
        self.depthsForViews = depthsForViews;
        self.viewsAtTap = viewsAtTap;
        self.selectedView = selectedView;
        
        self.title = @"View Hierarchy Tree";
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = NO;
    
    // A little more breathing room
    self.tableView.rowHeight = 50.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // Separator inset clashes with persistent cell selection
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    self.showsSearchBar = YES;
    self.showSearchBarInitially = YES;
    // Using pinSearchBar on this screen causes a weird visual
    // thing on the next view controller that gets pushed.
    //
    // self.pinSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;
    self.automaticallyShowsSearchBarCancelButton = NO;
    if (self.showScopeBar) {
        self.searchController.searchBar.showsScopeBar = YES;
        self.searchController.searchBar.scopeButtonTitles = @[@"Full Hierarchy", @"Views at Tap"];
        self.selectedScope = FLEXHierarchyScopeViewsAtTap;
    }
    
    [self updateDisplayedViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self disableToolbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self trySelectCellForSelectedView];
}


#pragma mark - Hierarchy helpers

+ (NSArray *)allViewsInHierarchy:(NSArray<UIWindow *> *)windows {
    return [windows flex_flatmapped:^id(UIWindow *window, NSUInteger idx) {
        if (![window isKindOfClass:[FLEXWindow class]]) {
            return [self viewWithRecursiveSubviews:window];
        }

        return nil;
    }];
}

+ (NSArray *)viewWithRecursiveSubviews:(UIView *)view {
    NSMutableArray *subviews = [NSMutableArray arrayWithObject:view];

    // A hosting view's SwiftUI views go right under it, ahead of its UIKit internals
    if ([FLEXSwiftUIInspector isHostingView:view]) {
        for (FLEXSwiftUIViewNode *root in [FLEXSwiftUIInspector rootNodesInHostingView:view]) {
            [subviews addObjectsFromArray:[self nodeWithDescendants:root]];
        }
    }

    for (UIView *subview in view.subviews) {
        [subviews addObjectsFromArray:[self viewWithRecursiveSubviews:subview]];
    }

    return subviews;
}

+ (NSArray<FLEXSwiftUIViewNode *> *)nodeWithDescendants:(FLEXSwiftUIViewNode *)node {
    NSMutableArray<FLEXSwiftUIViewNode *> *nodes = [NSMutableArray arrayWithObject:node];
    for (FLEXSwiftUIViewNode *child in node.children) {
        [nodes addObjectsFromArray:[self nodeWithDescendants:child]];
    }

    return nodes;
}

+ (NSInteger)depthOfView:(UIView *)view {
    NSInteger depth = 0;
    for (UIView *tryView = view; tryView.superview; tryView = tryView.superview) {
        depth++;
    }

    return depth;
}

+ (NSMapTable<NSNumber *, NSNumber *> *)hierarchyDepthsForViews:(NSArray *)views {
    NSMapTable<NSNumber *, NSNumber *> *depths = [NSMapTable strongToStrongObjectsMapTable];
    for (id view in views) {
        NSInteger depth;
        if ([view isKindOfClass:[FLEXSwiftUIViewNode class]]) {
            // One level under its hosting view, then nested by the SwiftUI tree
            FLEXSwiftUIViewNode *node = view;
            depth = [self depthOfView:node.hostingView] + 1;
            for (FLEXSwiftUIViewNode *parent = node.parent; parent; parent = parent.parent) {
                depth++;
            }
        } else {
            depth = [self depthOfView:view];
        }
        depths[@((uintptr_t)(__bridge void *)view)] = @(depth);
    }

    return depths;
}


#pragma mark Selection and Filtering Helpers

- (void)trySelectCellForSelectedView {
    NSUInteger selectedViewIndex = [self.displayedViews indexOfObject:self.selectedView];
    if (selectedViewIndex != NSNotFound) {
        UITableViewScrollPosition scrollPosition = UITableViewScrollPositionMiddle;
        NSIndexPath *selectedViewIndexPath = [NSIndexPath indexPathForRow:selectedViewIndex inSection:0];
        [self.tableView selectRowAtIndexPath:selectedViewIndexPath animated:YES scrollPosition:scrollPosition];
    }
}

- (void)updateDisplayedViews {
    NSArray *candidateViews = nil;
    if (self.showScopeBar) {
        if (self.selectedScope == FLEXHierarchyScopeViewsAtTap) {
            candidateViews = self.viewsAtTap;
        } else if (self.selectedScope == FLEXHierarchyScopeFullHierarchy) {
            candidateViews = self.allViews;
        }
    } else {
        candidateViews = self.allViews;
    }
    
    if (self.searchText.length) {
        self.displayedViews = [candidateViews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id candidateView, NSDictionary<NSString *, id> *bindings) {
            NSString *title = [FLEXUtility descriptionForNode:candidateView includingFrame:NO];
            NSString *candidateViewPointerAddress = [NSString stringWithFormat:@"%p", candidateView];
            BOOL matchedViewPointerAddress = [candidateViewPointerAddress rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL matchedViewTitle = [title rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
            return matchedViewPointerAddress || matchedViewTitle;
        }]];
    } else {
        self.displayedViews = candidateViews;
    }
    
    [self.tableView reloadData];
}

- (void)setSelectedView:(id)selectedView {
    _selectedView = selectedView;
    if (self.isViewLoaded) {
        [self trySelectCellForSelectedView];
    }
}


#pragma mark - Search Bar / Scope Bar

- (BOOL)showScopeBar {
    return self.viewsAtTap.count > 0;
}

- (void)updateSearchResults:(NSString *)newText {
    [self updateDisplayedViews];
    
    // If the search bar text field is active, don't scroll on selection because we may want
    // to continue typing. Otherwise, scroll so that the selected cell is visible.
    if (!self.searchController.searchBar.isFirstResponder) {
        [self trySelectCellForSelectedView];
    }
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedViews.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    FLEXHierarchyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FLEXHierarchyTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    id item = self.displayedViews[indexPath.row];
    UIView *view = [item isKindOfClass:[UIView class]] ? item : nil;

    cell.textLabel.text = [FLEXUtility descriptionForNode:item includingFrame:NO];
    cell.detailTextLabel.text = view ? [FLEXUtility detailDescriptionForView:view] : [NSString
        stringWithFormat:@"frame %@", [FLEXUtility stringForCGRect:[(FLEXSwiftUIViewNode *)item frameInHostingView]]
    ];
    cell.randomColorTag = [FLEXUtility consistentRandomColorForObject:item];
    cell.viewDepth = self.depthsForViews[@((uintptr_t)(__bridge void *)item)].integerValue;
    cell.indicatedViewColor = view.backgroundColor;

    if (view && (view.isHidden || view.alpha < 0.01)) {
        cell.textLabel.textColor = FLEXColor.deemphasizedTextColor;
        cell.detailTextLabel.textColor = FLEXColor.deemphasizedTextColor;
    } else {
        cell.textLabel.textColor = FLEXColor.primaryTextColor;
        cell.detailTextLabel.textColor = FLEXColor.primaryTextColor;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedView = self.displayedViews[indexPath.row]; // Don't scroll, avoid setter
    if (self.didSelectRowAction) {
        self.didSelectRowAction(_selectedView);
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    id drillInView = self.displayedViews[indexPath.row];
    FLEXObjectExplorerViewController *viewExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:drillInView];
    [self.navigationController pushViewController:viewExplorer animated:YES];
}

@end
