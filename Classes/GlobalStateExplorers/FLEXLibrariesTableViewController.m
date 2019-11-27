//
//  FLEXLibrariesTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-02.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXLibrariesTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXClassesTableViewController.h"
#import "FLEXClassExplorerViewController.h"
#import <objc/runtime.h>

@interface FLEXLibrariesTableViewController ()

@property (nonatomic) NSArray<NSString *> *imageNames;
@property (nonatomic) NSArray<NSString *> *filteredImageNames;
@property (nonatomic) NSString *headerTitle;

@property (nonatomic) Class foundClass;

@end

@implementation FLEXLibrariesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self loadImageNames];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsSearchBar = YES;
    [self updateHeaderTitle];
}

- (void)updateHeaderTitle
{
    if (self.foundClass) {
        self.headerTitle = @"Looking for this?";
    } else if (self.imageNames.count == self.filteredImageNames.count) {
        // Unfiltered
        self.headerTitle = [NSString stringWithFormat:@"%@ libraries", @(self.imageNames.count)];
    } else {
        self.headerTitle = [NSString
            stringWithFormat:@"%@ of %@ libraries",
            @(self.filteredImageNames.count), @(self.imageNames.count)
        ];
    }
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"📚  System Libraries";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    FLEXLibrariesTableViewController *librariesViewController = [self new];
    librariesViewController.title = [self globalsEntryTitle:row];

    return librariesViewController;
}


#pragma mark - Binary Images

- (void)loadImageNames
{
    unsigned int imageNamesCount = 0;
    const char **imageNames = objc_copyImageNames(&imageNamesCount);
    if (imageNames) {
        NSMutableArray<NSString *> *imageNameStrings = [NSMutableArray array];
        NSString *appImageName = [FLEXUtility applicationImageName];
        for (unsigned int i = 0; i < imageNamesCount; i++) {
            const char *imageName = imageNames[i];
            NSString *imageNameString = [NSString stringWithUTF8String:imageName];
            // Skip the app's image. We're just showing system libraries and frameworks.
            if (![imageNameString isEqual:appImageName]) {
                [imageNameStrings addObject:imageNameString];
            }
        }
        
        // Sort alphabetically
        self.imageNames = [imageNameStrings sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
            NSString *shortName1 = [self shortNameForImageName:name1];
            NSString *shortName2 = [self shortNameForImageName:name2];
            return [shortName1 caseInsensitiveCompare:shortName2];
        }];
        
        free(imageNames);
    }
}

- (NSString *)shortNameForImageName:(NSString *)imageName
{
    NSArray<NSString *> *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        return [NSString stringWithFormat:@"%@/%@", components[components.count - 2], components[components.count - 1]];
    }
    return imageName.lastPathComponent;
}

- (void)setImageNames:(NSArray<NSString *> *)imageNames
{
    if (![_imageNames isEqual:imageNames]) {
        _imageNames = imageNames;
        self.filteredImageNames = imageNames;
    }
}


#pragma mark - Filtering

- (void)updateSearchResults:(NSString *)searchText
{
    if (searchText.length) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary<NSString *, id> *bindings) {
            BOOL matches = NO;
            NSString *shortName = [self shortNameForImageName:evaluatedObject];
            if ([shortName rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
                matches = YES;
            }
            return matches;
        }];
        self.filteredImageNames = [self.imageNames filteredArrayUsingPredicate:searchPredicate];
    } else {
        self.filteredImageNames = self.imageNames;
    }
    
    self.foundClass = NSClassFromString(searchText);
    [self updateHeaderTitle];
    [self.tableView reloadData];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredImageNames.count + (self.foundClass ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
    }
    
    NSString *executablePath;
    if (self.foundClass) {
        if (indexPath.row == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"Class \"%@\"", self.searchText];
            return cell;
        } else {
            executablePath = self.filteredImageNames[indexPath.row-1];
        }
    } else {
        executablePath = self.filteredImageNames[indexPath.row];
    }
    
    cell.textLabel.text = [self shortNameForImageName:executablePath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.headerTitle;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && self.foundClass) {
        FLEXClassExplorerViewController *objectExplorer = [FLEXClassExplorerViewController new];
        objectExplorer.object = self.foundClass;
        [self.navigationController pushViewController:objectExplorer animated:YES];
    } else {
        FLEXClassesTableViewController *classesViewController = [FLEXClassesTableViewController new];
        classesViewController.binaryImageName = self.filteredImageNames[self.foundClass ? indexPath.row-1 : indexPath.row];
        [self.navigationController pushViewController:classesViewController animated:YES];
    }
}

@end
