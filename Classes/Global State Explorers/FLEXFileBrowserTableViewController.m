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

@interface FLEXFileBrowserTableViewController ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray *childPaths;
@property (nonatomic, strong) NSNumber *recursiveSize;

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
        
        FLEXFileBrowserTableViewController *__weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
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
                weakSelf.recursiveSize = @(totalSize);
                [weakSelf.tableView reloadData];
            });
        });
        
        self.childPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    }
    return self;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.childPaths count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sizeString = nil;
    if (!self.recursiveSize) {
        sizeString = @"Computing size…";
    } else {
        sizeString = [NSByteCountFormatter stringFromByteCount:[self.recursiveSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    }
    
    return [NSString stringWithFormat:@"%lu files (%@)", (unsigned long)[self.childPaths count], sizeString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subpath = [self.childPaths objectAtIndex:indexPath.row];
    NSString *fullPath = [self.path stringByAppendingPathComponent:subpath];
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
    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [subpath lastPathComponent];
    cell.detailTextLabel.text = subtitle;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subpath = [self.childPaths objectAtIndex:indexPath.row];
    NSString *fullPath = [self.path stringByAppendingPathComponent:subpath];
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    if (stillExists) {
        UIViewController *drillInViewController = nil;
        if (isDirectory) {
            drillInViewController = [[[self class] alloc] initWithPath:fullPath];
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
