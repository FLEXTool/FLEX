//
//  FLEXNetworkTableViewController.m
//  UICatalog
//
//  Created by Dal Rupnik on 07/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXNetworkTableViewController.h"
#import "FLEXNetworkInformationCollector.h"
#import "FLEXUtility.h"
#import "FLEXLibrariesTableViewController.h"
#import "FLEXClassesTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsTableViewController.h"
#import "FLEXFileBrowserTableViewController.h"
#import "FLEXGlobalsTableViewControllerEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXNetworkConnection.h"

@interface FLEXNetworkTableViewController ()

@property (nonatomic, strong) NSArray *requests;

@end

@implementation FLEXNetworkTableViewController
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        self.title = @"💬  Network";
        self.requests = [[FLEXNetworkInformationCollector sharedCollector].requests copy];
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table Data Helpers

- (NSAttributedString *)titleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkConnection *networkConnection = self.requests[indexPath.row];
    
    NSString *method = networkConnection.request.method.uppercaseString;
    NSURL *url = [NSURL URLWithString:networkConnection.request.url];
    NSInteger statusCode = [networkConnection.response.status integerValue];
    
    NSString *string = [NSString stringWithFormat:@"● %ld  %@ %@", (long)statusCode, method, url.path];
    
    UIFont *font = [FLEXUtility defaultTableViewCellLabelFont];
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : font }];
    
    //
    // Get the color correct of status
    //
    
    if ( (statusCode >= 200) && (statusCode < 300) )
    {
        [title addAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:39.0 / 255.0 green:174.0 / 255.0 blue:96.0 / 255.0 alpha:1.0], NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] } range:NSMakeRange(0, 1)];
    }
    else
    {
        [title addAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:231.0 / 255.0 green:76.0 / 255.0 blue:60.0 / 255.0 alpha:1.0], NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0] } range:NSMakeRange(0, 1)];
    }
    
    //
    // Bold the method
    //
    
    [title addAttributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:font.pointSize] } range:NSMakeRange(2 + [networkConnection.response.status stringValue].length + 2, method.length)];
    
    
    return title;
}

- (NSAttributedString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkConnection *networkConnection = self.requests[indexPath.row];
    
    NSURL *url = [NSURL URLWithString:networkConnection.request.url];
    
    NSTimeInterval time = fabs([networkConnection.timing.connectEnd doubleValue] - [networkConnection.timing.connectStart doubleValue]);
    double timeMilliseconds = time * 1000.0;
    
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@ - ", url.host];
    
    if (!networkConnection.timing.connectEnd)
    {
        [detailString appendString:@"Loading..."];
    }
    else
    {
        [detailString appendFormat:@"%@ - ", networkConnection.response.mimeType];
        
        NSString* bytes = [NSByteCountFormatter stringFromByteCount:networkConnection.size.longLongValue countStyle:NSByteCountFormatterCountStyleFile];
        
        [detailString appendFormat:@"%@ - ", bytes];
        
        if (timeMilliseconds > 1000.0)
        {
            [detailString appendFormat:@"%.2f s", time];
        }
        else
        {
            [detailString appendFormat:@"%ld ms", (long)timeMilliseconds];
        }
    }
    
    UIFont *font = [FLEXUtility defaultTableViewCellLabelFont];
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:detailString attributes:@{ NSFontAttributeName : [font fontWithSize:10.0] }];
    
    return title;
}

- (UIViewController *)viewControllerToPushForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkConnection *networkConnection = self.requests[indexPath.row];
    
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:networkConnection];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.requests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.attributedText = [self titleForRowAtIndexPath:indexPath];
    cell.detailTextLabel.attributedText = [self subtitleForRowAtIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewControllerToPush = [self viewControllerToPushForRowAtIndexPath:indexPath];
    
    [self.navigationController pushViewController:viewControllerToPush animated:YES];
}

@end
