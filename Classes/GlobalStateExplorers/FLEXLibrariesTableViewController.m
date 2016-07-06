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

@interface FLEXLibrariesTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *imageNames;
@property (nonatomic, strong) NSArray *filteredImageNames;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) Class foundClass;

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
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = [FLEXUtility searchBarPlaceholderText];
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}


#pragma mark - Binary Images

- (void)loadImageNames
{
    unsigned int imageNamesCount = 0;
    const char **imageNames = objc_copyImageNames(&imageNamesCount);
    if (imageNames) {
        NSMutableArray *imageNameStrings = [NSMutableArray array];
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
    NSArray *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        return [NSString stringWithFormat:@"%@/%@", components[components.count - 2], components[components.count - 1]];
    }
    return imageName.lastPathComponent;
}

- (void)setImageNames:(NSArray *)imageNames
{
    if (![_imageNames isEqual:imageNames]) {
        _imageNames = imageNames;
        self.filteredImageNames = imageNames;
    }
}


#pragma mark - Filtering

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0) {
        NSPredicate *searchPreidcate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            BOOL matches = NO;
            NSString *shortName = [self shortNameForImageName:evaluatedObject];
            if ([shortName rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
                matches = YES;
            }
            return matches;
        }];
        self.filteredImageNames = [self.imageNames filteredArrayUsingPredicate:searchPreidcate];
    } else {
        self.filteredImageNames = self.imageNames;
    }
    
    self.foundClass = NSClassFromString(searchText);
    [self.tableView reloadData];
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
            cell.textLabel.text = [NSString stringWithFormat:@"Class \"%@\"", self.searchBar.text];
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


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && self.foundClass) {
        FLEXClassExplorerViewController *objectExplorer = [FLEXClassExplorerViewController new];
        objectExplorer.object = self.foundClass;
        [self.navigationController pushViewController:objectExplorer animated:YES];
    } else {
        FLEXClassesTableViewController *classesViewController = [[FLEXClassesTableViewController alloc] init];
        classesViewController.binaryImageName = self.filteredImageNames[self.foundClass ? indexPath.row-1 : indexPath.row];
        [self.navigationController pushViewController:classesViewController animated:YES];
    }
}

@end
