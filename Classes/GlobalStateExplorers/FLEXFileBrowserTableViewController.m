//
//  FLEXFileBrowserTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//
//

#import "FLEXFileBrowserTableViewController.h"
#import "FLEXFileBrowserFileOperationController.h"
#import "FLEXUtility.h"
#import "FLEXWebViewController.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXFileBrowserTableViewCell : UITableViewCell
@end

@interface FLEXFileBrowserTableViewController () <FLEXFileBrowserFileOperationControllerDelegate>

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray *childPaths;
@property (nonatomic, copy) NSString *searchString;
@property (nonatomic, strong) NSArray *searchPaths;
@property (nonatomic, strong) NSNumber *recursiveSize;
@property (nonatomic, strong) NSNumber *searchPathsSize;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UISearchDisplayController *searchController;
#pragma clang diagnostic pop
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;
@property (nonatomic, strong) id<FLEXFileBrowserFileOperationController> fileOperationController;

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
#pragma clang diagnostic pop
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

        [self reloadChildPaths];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIMenuItem *renameMenuItem = [[UIMenuItem alloc] initWithTitle:@"Rename" action:@selector(fileBrowserRename:)];
    UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(fileBrowserDelete:)];
    [UIMenuController sharedMenuController].menuItems = @[renameMenuItem, deleteMenuItem];
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
    self.searchString = searchString;
    [self reloadSearchPaths];

    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    //confirm to clear all operations
    [self.operationQueue cancelAllOperations];
    [self reloadChildPaths];
    [self.tableView reloadData];
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
        cell = [[FLEXFileBrowserTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
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
                prettyString = [FLEXUtility prettyJSONStringFromData:[NSData dataWithContentsOfFile:fullPath]];
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
            [self openFileController:fullPath];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self reloadDisplayedPaths];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(fileBrowserDelete:) || action == @selector(fileBrowserRename:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    // Empty, but has to exist for the menu to show
    // The table view only calls this method for actions in the UIResponderStandardEditActions informal protocol.
    // Since our actions are outside of that protocol, we need to manually handle the action forwarding from the cells.
}

#pragma mark - FLEXFileBrowserFileOperationControllerDelegate

- (void)fileOperationControllerDidDismiss:(id<FLEXFileBrowserFileOperationController>)controller
{
    [self reloadDisplayedPaths];
}

- (void)openFileController:(NSString *)fullPath
{
    UIDocumentInteractionController *controller = [UIDocumentInteractionController new];
    controller.URL = [[NSURL alloc] initFileURLWithPath:fullPath];

    [controller presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
    self.documentController = controller;
}

- (void)fileBrowserRename:(UITableViewCell *)sender
{
    NSString *fullPath = nil;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    if (indexPath) {
        NSString *subpath = [self.childPaths objectAtIndex:indexPath.row];
        fullPath = [self.path stringByAppendingPathComponent:subpath];
    } else {
        indexPath = [self.searchController.searchResultsTableView indexPathForCell:sender];
        fullPath = [self.searchPaths objectAtIndex:indexPath.row];
    }

    self.fileOperationController = [[FLEXFileBrowserFileRenameOperationController alloc] initWithPath:fullPath];
    self.fileOperationController.delegate = self;
    [self.fileOperationController show];
}

- (void)fileBrowserDelete:(UITableViewCell *)sender
{
    NSString *fullPath = nil;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    if (indexPath) {
        NSString *subpath = [self.childPaths objectAtIndex:indexPath.row];
        fullPath = [self.path stringByAppendingPathComponent:subpath];
    } else {
        indexPath = [self.searchController.searchResultsTableView indexPathForCell:sender];
        fullPath = [self.searchPaths objectAtIndex:indexPath.row];
    }

    self.fileOperationController = [[FLEXFileBrowserFileDeleteOperationController alloc] initWithPath:fullPath];
    self.fileOperationController.delegate = self;
    [self.fileOperationController show];
}

- (void)reloadDisplayedPaths
{
    if (self.searchController.isActive) {
        [self reloadSearchPaths];
        [self.searchController.searchResultsTableView reloadData];
    } else {
        [self reloadChildPaths];
        [self.tableView reloadData];
    }
}

- (void)reloadChildPaths
{
    self.childPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
}

- (void)reloadSearchPaths
{
    self.searchPaths = nil;
    self.searchPathsSize = nil;

    //clear pre search request and start a new one
    [self.operationQueue cancelAllOperations];
    FLEXFileBrowserSearchOperation *newOperation = [[FLEXFileBrowserSearchOperation alloc] initWithPath:self.path searchString:self.searchString];
    newOperation.delegate = self;
    [self.operationQueue addOperation:newOperation];
}

@end


@implementation FLEXFileBrowserTableViewCell

- (void)fileBrowserRename:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

- (void)fileBrowserDelete:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

@end
