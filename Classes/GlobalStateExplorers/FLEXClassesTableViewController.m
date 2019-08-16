//
//  FLEXClassesTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXClassesTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>

@interface FLEXClassesTableViewController ()

@property (nonatomic) NSArray<NSString *> *classNames;
@property (nonatomic) NSArray<NSString *> *filteredClassNames;

@end

@implementation FLEXClassesTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsSearchBar = YES;
}

- (void)setBinaryImageName:(NSString *)binaryImageName
{
    if (![_binaryImageName isEqual:binaryImageName]) {
        _binaryImageName = binaryImageName;
        [self loadClassNames];
        [self updateTitle];
    }
}

- (void)setClassNames:(NSArray<NSString *> *)classNames
{
    _classNames = classNames;
    self.filteredClassNames = classNames;
}

- (void)loadClassNames
{
    unsigned int classNamesCount = 0;
    const char **classNames = objc_copyClassNamesForImage(self.binaryImageName.UTF8String, &classNamesCount);
    if (classNames) {
        NSMutableArray<NSString *> *classNameStrings = [NSMutableArray array];
        for (unsigned int i = 0; i < classNamesCount; i++) {
            const char *className = classNames[i];
            NSString *classNameString = [NSString stringWithUTF8String:className];
            [classNameStrings addObject:classNameString];
        }
        
        self.classNames = [classNameStrings sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        free(classNames);
    }
}

- (void)updateTitle
{
    NSString *shortImageName = self.binaryImageName.lastPathComponent;
    self.title = [NSString stringWithFormat:@"%@ Classes (%lu)", shortImageName, (unsigned long)self.filteredClassNames.count];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return [NSString stringWithFormat:@"📕  %@ Classes", [FLEXUtility applicationName]];
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    FLEXClassesTableViewController *classesViewController = [self new];
    classesViewController.binaryImageName = [FLEXUtility applicationImageName];

    return classesViewController;
}


#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)searchText
{
    if (searchText.length > 0) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", searchText];
        self.filteredClassNames = [self.classNames filteredArrayUsingPredicate:searchPredicate];
    } else {
        self.filteredClassNames = self.classNames;
    }
    [self updateTitle];
    [self.tableView reloadData];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredClassNames.count;
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
    
    cell.textLabel.text = self.filteredClassNames[indexPath.row];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *className = self.filteredClassNames[indexPath.row];
    Class selectedClass = objc_getClass(className.UTF8String);
    FLEXObjectExplorerViewController *objectExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:selectedClass];
    [self.navigationController pushViewController:objectExplorer animated:YES];
}

@end
