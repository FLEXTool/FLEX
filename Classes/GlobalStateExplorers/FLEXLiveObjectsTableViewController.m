//
//  FLEXLiveObjectsTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXLiveObjectsTableViewController.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXInstancesTableViewController.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>

static const NSInteger kFLEXLiveObjectsSortAlphabeticallyIndex = 0;
static const NSInteger kFLEXLiveObjectsSortByCountIndex = 1;
static const NSInteger kFLEXLiveObjectsSortBySizeIndex = 2;

@interface FLEXLiveObjectsTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *instanceCountsForClassNames;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *instanceSizesForClassNames;
@property (nonatomic, readonly) NSArray<NSString *> *allClassNames;
@property (nonatomic, strong) NSArray<NSString *> *filteredClassNames;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation FLEXLiveObjectsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = [FLEXUtility searchBarPlaceholderText];
    self.searchBar.delegate = self;
    self.searchBar.showsScopeBar = YES;
    self.searchBar.scopeButtonTitles = @[@"Sort Alphabetically", @"Sort by Count", @"Sort by Size"];
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [self reloadTableData];
}

- (NSArray<NSString *> *)allClassNames
{
    return [self.instanceCountsForClassNames allKeys];
}

- (void)reloadTableData
{
    // Set up a CFMutableDictionary with class pointer keys and NSUInteger values.
    // We abuse CFMutableDictionary a little to have primitive keys through judicious casting, but it gets the job done.
    // The dictionary is intialized with a 0 count for each class so that it doesn't have to expand during enumeration.
    // While it might be a little cleaner to populate an NSMutableDictionary with class name string keys to NSNumber counts,
    // we choose the CF/primitives approach because it lets us enumerate the objects in the heap without allocating any memory during enumeration.
    // The alternative of creating one NSString/NSNumber per object on the heap ends up polluting the count of live objects quite a bit.
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    CFMutableDictionaryRef mutableCountsForClasses = CFDictionaryCreateMutable(NULL, classCount, NULL, NULL);
    for (unsigned int i = 0; i < classCount; i++) {
        CFDictionarySetValue(mutableCountsForClasses, (__bridge const void *)classes[i], (const void *)0);
    }
    
    // Enumerate all objects on the heap to build the counts of instances for each class.
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        NSUInteger instanceCount = (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)actualClass);
        instanceCount++;
        CFDictionarySetValue(mutableCountsForClasses, (__bridge const void *)actualClass, (const void *)instanceCount);
    }];
    
    // Convert our CF primitive dictionary into a nicer mapping of class name strings to counts that we will use as the table's model.
    NSMutableDictionary<NSString *, NSNumber *> *mutableCountsForClassNames = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *mutableSizesForClassNames = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < classCount; i++) {
        Class class = classes[i];
        NSUInteger instanceCount = (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)(class));
        NSString *className = @(class_getName(class));
        if (instanceCount > 0) {
            [mutableCountsForClassNames setObject:@(instanceCount) forKey:className];
        }
        [mutableSizesForClassNames setObject:@(class_getInstanceSize(class)) forKey:className];
    }
    free(classes);
    
    self.instanceCountsForClassNames = mutableCountsForClassNames;
    self.instanceSizesForClassNames = mutableSizesForClassNames;
    
    [self updateTableDataForSearchFilter];
}

- (void)refreshControlDidRefresh:(id)sender
{
    [self reloadTableData];
    [self.refreshControl endRefreshing];
}

- (void)updateTitle
{
    NSString *title = @"Live Objects";
    
    NSUInteger totalCount = 0;
    NSUInteger totalSize = 0;
    for (NSString *className in self.allClassNames) {
        NSUInteger count = [self.instanceCountsForClassNames[className] unsignedIntegerValue];
        totalCount += count;
        totalSize += count * [self.instanceSizesForClassNames[className] unsignedIntegerValue];
    }
    NSUInteger filteredCount = 0;
    NSUInteger filteredSize = 0;
    for (NSString *className in self.filteredClassNames) {
        NSUInteger count = [self.instanceCountsForClassNames[className] unsignedIntegerValue];
        filteredCount += count;
        filteredSize += count * [self.instanceSizesForClassNames[className] unsignedIntegerValue];
    }
    
    if (filteredCount == totalCount) {
        // Unfiltered
        title = [title stringByAppendingFormat:@" (%lu, %@)", (unsigned long)totalCount,
              [NSByteCountFormatter stringFromByteCount:totalSize countStyle:NSByteCountFormatterCountStyleFile]];
    } else {
        title = [title stringByAppendingFormat:@" (filtered, %lu, %@)", (unsigned long)filteredCount,
              [NSByteCountFormatter stringFromByteCount:filteredSize countStyle:NSByteCountFormatterCountStyleFile]];
    }
    
    self.title = title;
}


#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateTableDataForSearchFilter];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateTableDataForSearchFilter];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Dismiss the keyboard when interacting with filtered results.
    [self.searchBar endEditing:YES];
}

- (void)updateTableDataForSearchFilter
{
    if ([self.searchBar.text length] > 0) {
        NSPredicate *searchPreidcate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", self.searchBar.text];
        self.filteredClassNames = [self.allClassNames filteredArrayUsingPredicate:searchPreidcate];
    } else {
        self.filteredClassNames = self.allClassNames;
    }
    
    if (self.searchBar.selectedScopeButtonIndex == kFLEXLiveObjectsSortAlphabeticallyIndex) {
        self.filteredClassNames = [self.filteredClassNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    } else if (self.searchBar.selectedScopeButtonIndex == kFLEXLiveObjectsSortByCountIndex) {
        self.filteredClassNames = [self.filteredClassNames sortedArrayUsingComparator:^NSComparisonResult(NSString *className1, NSString *className2) {
            NSNumber *count1 = self.instanceCountsForClassNames[className1];
            NSNumber *count2 = self.instanceCountsForClassNames[className2];
            // Reversed for descending counts.
            return [count2 compare:count1];
        }];
    } else if (self.searchBar.selectedScopeButtonIndex == kFLEXLiveObjectsSortBySizeIndex) {
        self.filteredClassNames = [self.filteredClassNames sortedArrayUsingComparator:^NSComparisonResult(NSString *className1, NSString *className2) {
            NSNumber *count1 = self.instanceCountsForClassNames[className1];
            NSNumber *count2 = self.instanceCountsForClassNames[className2];
            NSNumber *size1 = self.instanceSizesForClassNames[className1];
            NSNumber *size2 = self.instanceSizesForClassNames[className2];
            // Reversed for descending sizes.
            return [@(count2.integerValue * size2.integerValue) compare:@(count1.integerValue * size1.integerValue)];
        }];
    }
    
    [self updateTitle];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredClassNames count];
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
    
    NSString *className = self.filteredClassNames[indexPath.row];
    NSNumber *count = self.instanceCountsForClassNames[className];
    NSNumber *size = self.instanceSizesForClassNames[className];
    unsigned long totalSize = count.unsignedIntegerValue * size.unsignedIntegerValue;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld, %@)", className, (long)[count integerValue],
        [NSByteCountFormatter stringFromByteCount:totalSize countStyle:NSByteCountFormatterCountStyleFile]];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *className = self.filteredClassNames[indexPath.row];
    FLEXInstancesTableViewController *instancesViewController = [FLEXInstancesTableViewController instancesTableViewControllerForClassName:className];
    [self.navigationController pushViewController:instancesViewController animated:YES];
}

@end
