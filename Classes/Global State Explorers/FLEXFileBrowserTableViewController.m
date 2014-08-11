//
//  FLEXFileBrowserTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//
//

#import "FLEXFileBrowserTableViewController.h"
#import "FLEXUtility.h"
#import "FLEXWebViewController.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXFileBrowserTableViewController ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray *childPaths;
@property (nonatomic, strong) NSArray *searchPaths;
@property (nonatomic, strong) NSNumber *recursiveSize;
@property (nonatomic, strong) NSNumber *searchPathsSize;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic) NSOperationQueue *operationQueue;

@end

@implementation FLEXFileBrowserTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithPath:NSHomeDirectory()];
}

- (id)initWithPath:(NSString *)path
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.path = path;
        self.title = [path lastPathComponent];
        self.operationQueue = [NSOperationQueue new];
        
        //add search controller
        UISearchBar *searchBar = [UISearchBar new];
        [searchBar sizeToFit];
        self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        self.searchController.delegate = self;
        self.searchController.searchResultsDataSource = self;
        self.searchController.searchResultsDelegate = self;
        self.tableView.tableHeaderView = self.searchController.searchBar;
        
        //computing path size
        FLEXFileBrowserTableViewController *__weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
            uint64_t totalSize = [attributes fileSize];
            
            for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
                attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
                totalSize += [attributes fileSize];
                
                // Bail if the interested view controller has gone away.
                if (!weakSelf) {
                    return;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                FLEXFileBrowserTableViewController *__strong strongSelf = weakSelf;
                strongSelf.recursiveSize = @(totalSize);
                [strongSelf.tableView reloadData];
            });
        });
        
        self.childPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    }
    return self;
}

#pragma mark - FLEXFileBrowserSearchOperationDelegate

- (void)fileBrowserSearchOperationResult:(NSArray *)searchResult size:(uint64_t)size
{
    self.searchPaths = searchResult;
    self.searchPathsSize = @(size);
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.searchPaths = nil;
    self.searchPathsSize = nil;
    
    //clear pre search request and start a new one
    [self.operationQueue cancelAllOperations];
    FLEXFileBrowserSearchOperation *newOperation = [[FLEXFileBrowserSearchOperation alloc] initWithPath:self.path searchString:searchString];
    newOperation.delegate = self;
    [self.operationQueue addOperation:newOperation];

    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    //confirm to clear all operations
    [self.operationQueue cancelAllOperations];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [self.childPaths count];
    } else {
        return [self.searchPaths count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSNumber *currentSize = nil;
    NSArray *currentPaths = nil;
    
    if (tableView == self.tableView) {
        currentSize = self.recursiveSize;
        currentPaths = self.childPaths;
    } else {
        currentSize = self.searchPathsSize;
        currentPaths = self.searchPaths;
    }
    
    NSString *sizeString = nil;
    if (!currentSize) {
        sizeString = @"Computing size…";
    } else {
        sizeString = [NSByteCountFormatter stringFromByteCount:[currentSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    }
    
    return [NSString stringWithFormat:@"%lu files (%@)", (unsigned long)[currentPaths count], sizeString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fullPath = nil;
    if (tableView == self.tableView) {
        NSString *subpath = [self.childPaths objectAtIndex:indexPath.row];
        fullPath = [self.path stringByAppendingPathComponent:subpath];
    } else {
        fullPath = [self.searchPaths objectAtIndex:indexPath.row];
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    BOOL isDirectory = [[attributes fileType] isEqual:NSFileTypeDirectory];
    NSString *subtitle = nil;
    if (isDirectory) {
        NSUInteger count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL] count];
        subtitle = [NSString stringWithFormat:@"%lu file%@", (unsigned long)count, (count == 1 ? @"" : @"s")];
    } else {
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[attributes fileSize] countStyle:NSByteCountFormatterCountStyleFile];
        subtitle = [NSString stringWithFormat:@"%@ - %@", sizeString, [attributes fileModificationDate]];
    }
    
    static NSString *textCellIdentifier = @"textCell";
    static NSString *imageCellIdentifier = @"imageCell";
    UITableViewCell *cell = nil;
    
    // Separate image and text only cells because otherwise the separator lines get out-of-whack on image cells reused with text only.
    BOOL showImagePreview = [FLEXUtility isImagePathExtension:[fullPath pathExtension]];
    NSString *cellIdentifier = showImagePreview ? imageCellIdentifier : textCellIdentifier;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSString *cellTitle = [fullPath lastPathComponent];
    cell.textLabel.text = cellTitle;
    cell.detailTextLabel.text = subtitle;
    
    if (showImagePreview) {
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = [UIImage imageWithContentsOfFile:fullPath];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subpath = nil;
    NSString *fullPath = nil;
    
    if (tableView == self.tableView) {
        subpath = [self.childPaths objectAtIndex:indexPath.row];
        fullPath = [self.path stringByAppendingPathComponent:subpath];
    } else {
        fullPath = [self.searchPaths objectAtIndex:indexPath.row];
        subpath = [fullPath lastPathComponent];
    }
    
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    if (stillExists) {
        UIViewController *drillInViewController = nil;
        if (isDirectory) {
            drillInViewController = [[[self class] alloc] initWithPath:fullPath];
        } else if ([FLEXUtility isImagePathExtension:[fullPath pathExtension]]) {
            UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
            drillInViewController = [[FLEXImagePreviewViewController alloc] initWithImage:image];
        } else {
            // Special case keyed archives, json, and plists to get more readable data.
            NSString *prettyString = nil;
            if ([[subpath pathExtension] isEqual:@"archive"]) {
                prettyString = [[NSKeyedUnarchiver unarchiveObjectWithFile:fullPath] description];
            } else if ([[subpath pathExtension] isEqualToString:@"json"]) {
                NSData *fileData = [NSData dataWithContentsOfFile:fullPath];
                id jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:NULL];
                prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
            } else if ([[subpath pathExtension] isEqualToString:@"plist"]) {
                NSData *fileData = [NSData dataWithContentsOfFile:fullPath];
                prettyString = [[NSPropertyListSerialization propertyListWithData:fileData options:0 format:NULL error:NULL] description];
            }
            
            if ([prettyString length] > 0) {
                drillInViewController = [[FLEXWebViewController alloc] initWithText:prettyString];
            } else if ([FLEXWebViewController supportsPathExtension:[subpath pathExtension]]) {
                drillInViewController = [[FLEXWebViewController alloc] initWithURL:[NSURL fileURLWithPath:fullPath]];
            } else {
                NSString *fileString = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];
                if ([fileString length] > 0) {
                    drillInViewController = [[FLEXWebViewController alloc] initWithText:fileString];
                }
            }
        }
        
        if (drillInViewController) {
            drillInViewController.title = [subpath lastPathComponent];
            [self.navigationController pushViewController:drillInViewController animated:YES];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end
