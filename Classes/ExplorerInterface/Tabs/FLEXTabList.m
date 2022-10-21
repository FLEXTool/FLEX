//
//  FLEXTabList.m
//  FLEX
//
//  Created by Tanner on 2/1/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTabList.h"
#import "FLEXUtility.h"

@interface FLEXTabList () {
    NSMutableArray *_openTabs;
    NSMutableArray *_openTabSnapshots;
}
@end
#pragma mark -
@implementation FLEXTabList

#pragma mark Initialization

+ (FLEXTabList *)sharedList {
    static FLEXTabList *sharedList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedList = [self new];
    });
    
    return sharedList;
}

- (id)init {
    self = [super init];
    if (self) {
        _openTabs = [NSMutableArray new];
        _openTabSnapshots = [NSMutableArray new];
        _activeTabIndex = NSNotFound;
    }
    
    return self;
}


#pragma mark Private

- (void)chooseNewActiveTab {
    if (self.openTabs.count) {
        self.activeTabIndex = self.openTabs.count - 1;
    } else {
        self.activeTabIndex = NSNotFound;
    }
}


#pragma mark Public

- (void)setActiveTabIndex:(NSInteger)idx {
    NSParameterAssert(idx < self.openTabs.count || idx == NSNotFound);
    if (_activeTabIndex == idx) return;
    
    _activeTabIndex = idx;
    _activeTab = (idx == NSNotFound) ? nil : self.openTabs[idx];
}

- (void)addTab:(UINavigationController *)newTab {
    NSParameterAssert(newTab);
    
    // Update snapshot of the last active tab
    if (self.activeTab) {
        [self updateSnapshotForActiveTab];
    }
    
    // Add new tab and snapshot,
    // update active tab and index
    [_openTabs addObject:newTab];
    [_openTabSnapshots addObject:[FLEXUtility previewImageForView:newTab.view]];
    _activeTab = newTab;
    _activeTabIndex = self.openTabs.count - 1;
}

- (void)closeTab:(UINavigationController *)tab {
    NSParameterAssert(tab);
    NSInteger idx = [self.openTabs indexOfObject:tab];
    if (idx != NSNotFound) {
        [self closeTabAtIndex:idx];
    }
    
    // Not sure how this is possible, but it happens sometimes
    if (self.activeTab == tab) {
        [self chooseNewActiveTab];
    }
    
    // It is possible for an object explorer to form a retain cycle
    // with its own navigation controller; clearing the view controllers
    // manually when closing a tab breaks the cycle
    tab.viewControllers = @[];
}

- (void)closeTabAtIndex:(NSInteger)idx {
    NSParameterAssert(idx < self.openTabs.count);
    
    // Remove old tab and snapshot
    [_openTabs removeObjectAtIndex:idx];
    [_openTabSnapshots removeObjectAtIndex:idx];
    
    // Update active tab and index if needed
    if (self.activeTabIndex == idx) {
        [self chooseNewActiveTab];
    }
}

- (void)closeTabsAtIndexes:(NSIndexSet *)indexes {
    // Remove old tabs and snapshot
    [_openTabs removeObjectsAtIndexes:indexes];
    [_openTabSnapshots removeObjectsAtIndexes:indexes];
    
    // Update active tab and index if needed
    if ([indexes containsIndex:self.activeTabIndex]) {
        [self chooseNewActiveTab];
    }
}

- (void)closeActiveTab {
    [self closeTab:self.activeTab];
}

- (void)closeAllTabs {
    // Remove tabs and snapshots
    [_openTabs removeAllObjects];
    [_openTabSnapshots removeAllObjects];
    
    // Update active tab index
    self.activeTabIndex = NSNotFound;
}

- (void)updateSnapshotForActiveTab {
    if (self.activeTabIndex != NSNotFound) {
        UIImage *newSnapshot = [FLEXUtility previewImageForView:self.activeTab.view];
        [_openTabSnapshots replaceObjectAtIndex:self.activeTabIndex withObject:newSnapshot];
    }
}

@end
