//
//  FLEXFilteringTableViewController.m
//  FLEX
//
//  Created by Tanner on 3/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXFilteringTableViewController.h"
#import "FLEXTableViewSection.h"
#import "NSArray+FLEX.h"
#import "FLEXMacros.h"

@interface FLEXFilteringTableViewController ()

@end

@implementation FLEXFilteringTableViewController
@synthesize allSections = _allSections;

#pragma mark - View controller lifecycle

- (void)loadView {
    [super loadView];
    
    if (!self.filterDelegate) {
        self.filterDelegate = self;
    } else {
        [self _registerCellsForReuse];
    }
}

- (void)_registerCellsForReuse {
    for (FLEXTableViewSection *section in self.filterDelegate.allSections) {
        if (section.cellRegistrationMapping) {
            [self.tableView registerCells:section.cellRegistrationMapping];
        }
    }
}


#pragma mark - Public

- (void)setFilterDelegate:(id<FLEXTableViewFiltering>)filterDelegate {
    _filterDelegate = filterDelegate;
    filterDelegate.allSections = [filterDelegate makeSections];
    
    if (self.isViewLoaded) {
        [self _registerCellsForReuse];
    }
}

- (void)reloadData {
    [self reloadData:self.nonemptySections];
}

- (void)reloadData:(NSArray *)nonemptySections {
    // Recalculate displayed sections
    self.filterDelegate.sections = nonemptySections;

    // Refresh table view
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)reloadSections {
    for (FLEXTableViewSection *section in self.filterDelegate.allSections) {
        [section reloadData];
    }
}


#pragma mark - Search

- (void)updateSearchResults:(NSString *)newText {
    NSArray *(^filter)() = ^NSArray *{
        self.filterText = newText;

        // Sections will adjust data based on this property
        for (FLEXTableViewSection *section in self.filterDelegate.allSections) {
            section.filterText = newText;
        }
        
        return nil;
    };
    
    if (self.filterInBackground) {
        [self onBackgroundQueue:filter thenOnMainQueue:^(NSArray *unused) {
            if ([self.searchText isEqualToString:newText]) {
                [self reloadData];
            }
        }];
    } else {
        filter();
        [self reloadData];
    }
}


#pragma mark Filtering

- (NSArray<FLEXTableViewSection *> *)nonemptySections {
    return [self.filterDelegate.allSections flex_filtered:^BOOL(FLEXTableViewSection *section, NSUInteger idx) {
        return section.numberOfRows > 0;
    }];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    return @[];
}

- (void)setAllSections:(NSArray<FLEXTableViewSection *> *)allSections {
    _allSections = allSections.copy;
    // Only display nonempty sections
    self.sections = self.nonemptySections;
}

- (void)setSections:(NSArray<FLEXTableViewSection *> *)sections {
    // Allow sections to reload a portion of the table view at will
    [sections enumerateObjectsUsingBlock:^(FLEXTableViewSection *s, NSUInteger idx, BOOL *stop) {
        [s setTable:self.tableView section:idx];
    }];
    _sections = sections.copy;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.filterDelegate.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filterDelegate.sections[section].numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.filterDelegate.sections[section].title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuse = [self.filterDelegate.sections[indexPath.section] reuseIdentifierForRow:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
    [self.filterDelegate.sections[indexPath.section] configureCell:cell forRow:indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.wantsSectionIndexTitles) {
        return [NSArray flex_forEachUpTo:self.filterDelegate.sections.count map:^id(NSUInteger i) {
            return @"⦁";
        }];
    }
    
    return nil;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.filterDelegate.sections[indexPath.section] canSelectRow:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXTableViewSection *section = self.filterDelegate.sections[indexPath.section];

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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self.filterDelegate.sections[indexPath.section] didPressInfoButtonAction:indexPath.row](self);
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    FLEXTableViewSection *section = self.filterDelegate.sections[indexPath.section];
    NSString *title = [section menuTitleForRow:indexPath.row];
    NSArray<UIMenuElement *> *menuItems = [section menuItemsForRow:indexPath.row sender:self];
    
    if (menuItems.count) {
        return [UIContextMenuConfiguration
            configurationWithIdentifier:nil
            previewProvider:nil
            actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
                return [UIMenu menuWithTitle:title children:menuItems];
            }
        ];
    }
    
    return nil;
}

@end
