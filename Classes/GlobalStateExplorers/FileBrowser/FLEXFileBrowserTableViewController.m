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
#import "FLEXTableListViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"

@interface FLEXFileBrowserTableViewCell : UITableViewCell
@end

@interface FLEXFileBrowserTableViewController () <FLEXFileBrowserFileOperationControllerDelegate, FLEXFileBrowserSearchOperationDelegate>

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray<NSString *> *childPaths;
@property (nonatomic, strong) NSArray<NSString *> *searchPaths;
@property (nonatomic, strong) NSNumber *recursiveSize;
@property (nonatomic, strong) NSNumber *searchPathsSize;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;
@property (nonatomic, strong) id<FLEXFileBrowserFileOperationController> fileOperationController;

@end

@implementation FLEXFileBrowserTableViewController

- (id)init
{
    return [self initWithPath:NSHomeDirectory()];
}

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.path = path;
        self.title = [path lastPathComponent];
        self.operationQueue = [NSOperationQueue new];
        
        
        //computing path size
        FLEXFileBrowserTableViewController *__weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
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

        [self reloadCurrentPath];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceForAsyncSearch;
}

#pragma mark - FLEXGlobalsTableViewControllerEntry

+ (NSString *)globalsEntryTitle {
    return @"📁  File Browser";
}

+ (instancetype)globalsEntryViewController {
    return [self new];
}

#pragma mark - Misc

- (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - FLEXFileBrowserSearchOperationDelegate

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size
{
    self.searchPaths = searchResult;
    self.searchPathsSize = @(size);
    [self.tableView reloadData];
}

#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)newText
{
    [self reloadDisplayedPaths];
}

#pragma mark UISearchControllerDelegate

- (void)willDismissSearchController:(UISearchController *)searchController
{
    [self.operationQueue cancelAllOperations];
    [self reloadCurrentPath];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? [self.searchPaths count] : [self.childPaths count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BOOL isSearchActive = self.searchController.isActive;
    NSNumber *currentSize = isSearchActive ? self.searchPathsSize : self.recursiveSize;
    NSArray<NSString *> *currentPaths = isSearchActive ? self.searchPaths : self.childPaths;

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
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    BOOL isDirectory = [attributes.fileType isEqual:NSFileTypeDirectory];
    NSString *subtitle = nil;
    if (isDirectory) {
        NSUInteger count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL] count];
        subtitle = [NSString stringWithFormat:@"%lu item%@", (unsigned long)count, (count == 1 ? @"" : @"s")];
    } else {
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:attributes.fileSize countStyle:NSByteCountFormatterCountStyleFile];
        subtitle = [NSString stringWithFormat:@"%@ - %@", sizeString, attributes.fileModificationDate ?: @"Never modified"];
    }

    static NSString *textCellIdentifier = @"textCell";
    static NSString *imageCellIdentifier = @"imageCell";
    UITableViewCell *cell = nil;

    // Separate image and text only cells because otherwise the separator lines get out-of-whack on image cells reused with text only.
    UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
    NSString *cellIdentifier = image ? imageCellIdentifier : textCellIdentifier;

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

    if (image) {
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = image;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSString *subpath = fullPath.lastPathComponent;
    NSString *pathExtension = subpath.pathExtension;

    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIImage *image = cell.imageView.image;

    if (!stillExists) {
        [self alert:@"File Not Found" message:@"The file at the specified path no longer exists."];
        [self reloadDisplayedPaths];
        return;
    }

    UIViewController *drillInViewController = nil;
    if (isDirectory) {
        drillInViewController = [[[self class] alloc] initWithPath:fullPath];
    } else if (image) {
        drillInViewController = [[FLEXImagePreviewViewController alloc] initWithImage:image];
    } else {
        NSData *fileData = [NSData dataWithContentsOfFile:fullPath];
        if (!fileData.length) {
            [self alert:@"Empty File" message:@"No data returned from the file."];
            return;
        }

        // Special case keyed archives, json, and plists to get more readable data.
        NSString *prettyString = nil;
        if ([pathExtension isEqualToString:@"json"]) {
            prettyString = [FLEXUtility prettyJSONStringFromData:fileData];
        } else {
            // Regardless of file extension...
            
            id object = nil;
            @try {
                // Try to decode an archived object regardless of file extension
                object = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
            } @catch (NSException *e) { }
            
            // Try to decode other things instead
            object = object
                        ?: [NSPropertyListSerialization propertyListWithData:fileData
                                                                     options:0
                                                                      format:NULL
                                                                       error:NULL]
                        ?: [NSDictionary dictionaryWithContentsOfFile:fullPath]
                        ?: [NSArray arrayWithContentsOfFile:fullPath];
            
            if (object) {
                drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
            }
        }

        if (prettyString.length) {
            drillInViewController = [[FLEXWebViewController alloc] initWithText:prettyString];
        } else if ([FLEXWebViewController supportsPathExtension:pathExtension]) {
            drillInViewController = [[FLEXWebViewController alloc] initWithURL:[NSURL fileURLWithPath:fullPath]];
        } else if ([FLEXTableListViewController supportsExtension:pathExtension]) {
            drillInViewController = [[FLEXTableListViewController alloc] initWithPath:fullPath];
        }
        else if (!drillInViewController) {
            NSString *fileString = [NSString stringWithUTF8String:fileData.bytes];
            if (fileString.length) {
                drillInViewController = [[FLEXWebViewController alloc] initWithText:fileString];
            }
        }
    }

    if (drillInViewController) {
        drillInViewController.title = subpath.lastPathComponent;
        [self.navigationController pushViewController:drillInViewController animated:YES];
    } else {
        // Share the file otherwise
        [self openFileController:fullPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIMenuItem *rename = [[UIMenuItem alloc] initWithTitle:@"Rename" action:@selector(fileBrowserRename:)];
    UIMenuItem *delete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(fileBrowserDelete:)];
    UIMenuItem *copyPath = [[UIMenuItem alloc] initWithTitle:@"Copy Path" action:@selector(fileBrowserCopyPath:)];
    UIMenuItem *share = [[UIMenuItem alloc] initWithTitle:@"Share" action:@selector(fileBrowserShare:)];

    [UIMenuController sharedMenuController].menuItems = @[rename, delete, copyPath, share];

    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(fileBrowserDelete:)
        || action == @selector(fileBrowserRename:)
        || action == @selector(fileBrowserCopyPath:)
        || action == @selector(fileBrowserShare:);
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
    controller.URL = [NSURL fileURLWithPath:fullPath];

    [controller presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
    self.documentController = controller;
}

- (void)fileBrowserRename:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];

    self.fileOperationController = [[FLEXFileBrowserFileRenameOperationController alloc] initWithPath:fullPath];
    self.fileOperationController.delegate = self;
    [self.fileOperationController show];
}

- (void)fileBrowserDelete:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];

    self.fileOperationController = [[FLEXFileBrowserFileDeleteOperationController alloc] initWithPath:fullPath];
    self.fileOperationController.delegate = self;
    [self.fileOperationController show];
}

- (void)fileBrowserCopyPath:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    [UIPasteboard generalPasteboard].string = fullPath;
}

- (void)fileBrowserShare:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *pathString = [self filePathAtIndexPath:indexPath];
    NSURL *filePath = [NSURL fileURLWithPath:pathString];

    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:pathString isDirectory:&isDirectory];

    if (isDirectory) {
        // UIDocumentInteractionController for folders
        [self openFileController:pathString];
    } else {
        // Share sheet for files
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[filePath] applicationActivities:nil];
        [self presentViewController:shareSheet animated:true completion:nil];
    }
}

- (void)reloadDisplayedPaths
{
    if (self.searchController.isActive) {
        [self updateSearchPaths];
    } else {
        [self reloadCurrentPath];
        [self.tableView reloadData];
    }
}

- (void)reloadCurrentPath
{
    NSMutableArray<NSString *> *childPaths = [NSMutableArray array];
    NSArray<NSString *> *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
    for (NSString *subpath in subpaths) {
        [childPaths addObject:[self.path stringByAppendingPathComponent:subpath]];
    }
    self.childPaths = childPaths;
}

- (void)updateSearchPaths
{
    self.searchPaths = nil;
    self.searchPathsSize = nil;

    //clear pre search request and start a new one
    [self.operationQueue cancelAllOperations];
    FLEXFileBrowserSearchOperation *newOperation = [[FLEXFileBrowserSearchOperation alloc] initWithPath:self.path searchString:self.searchText];
    newOperation.delegate = self;
    [self.operationQueue addOperation:newOperation];
}

- (NSString *)filePathAtIndexPath:(NSIndexPath *)indexPath
{
    return self.searchController.isActive ? self.searchPaths[indexPath.row] : self.childPaths[indexPath.row];
}

@end


@implementation FLEXFileBrowserTableViewCell

- (void)forwardAction:(SEL)action withSender:(id)sender
{
    id target = [self.nextResponder targetForAction:action withSender:sender];
    [[UIApplication sharedApplication] sendAction:action to:target from:self forEvent:nil];
}

- (void)fileBrowserRename:(UIMenuController *)sender
{
    [self forwardAction:_cmd withSender:sender];
}

- (void)fileBrowserDelete:(UIMenuController *)sender
{
    [self forwardAction:_cmd withSender:sender];
}

- (void)fileBrowserCopyPath:(UIMenuController *)sender
{
    [self forwardAction:_cmd withSender:sender];
}

- (void)fileBrowserShare:(UIMenuController *)sender
{
    [self forwardAction:_cmd withSender:sender];
}

@end
