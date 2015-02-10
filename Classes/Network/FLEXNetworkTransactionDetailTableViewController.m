//
//  FLEXNetworkTransactionDetailTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2/10/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXNetworkTransactionDetailTableViewController.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXWebViewController.h"
#import "FLEXImagePreviewViewController.h"
#import "FLEXMultilineTableViewCell.h"
#import "FLEXUtility.h"

@interface FLEXNetworkDetailSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray *rows;

@end

@implementation FLEXNetworkDetailSection

@end

typedef UIViewController *(^FLEXNetworkDetailRowSelectionFuture)(void);

@interface FLEXNetworkDetailRow : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) FLEXNetworkDetailRowSelectionFuture selectionFuture;

@end

@implementation FLEXNetworkDetailRow

@end

@interface FLEXNetworkTransactionDetailTableViewController ()

@property (nonatomic, copy) NSArray *sections;

@end

@implementation FLEXNetworkTransactionDetailTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    // Force grouped style
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[FLEXMultilineTableViewCell class] forCellReuseIdentifier:kFLEXMultilineTableViewCellIdentifier];
}

- (void)setTransaction:(FLEXNetworkTransaction *)transaction
{
    if (![_transaction isEqual:transaction]) {
        _transaction = transaction;
        self.title = [transaction.request.URL lastPathComponent];
        [self rebuildTableSections];
    }
}

- (void)setSections:(NSArray *)sections
{
    if (![_sections isEqual:sections]) {
        _sections = [sections copy];
        [self.tableView reloadData];
    }
}

- (void)rebuildTableSections
{
    NSMutableArray *sections = [NSMutableArray array];

    FLEXNetworkDetailSection *generalSection = [[self class] generalSectionForTransaction:self.transaction];
    if ([generalSection.rows count] > 0) {
        [sections addObject:generalSection];
    }
    FLEXNetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
    if ([requestHeadersSection.rows count] > 0) {
        [sections addObject:requestHeadersSection];
    }
    FLEXNetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
    if ([queryParametersSection.rows count] > 0) {
        [sections addObject:queryParametersSection];
    }
    FLEXNetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if ([responseHeadersSection.rows count] > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    FLEXNetworkDetailSection *sectionModel = [self.sections objectAtIndex:section];
    return [sectionModel.rows count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    FLEXNetworkDetailSection *sectionModel = [self.sections objectAtIndex:section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXMultilineTableViewCellIdentifier forIndexPath:indexPath];

    FLEXNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    cell.textLabel.attributedText = [[self class] attributedTextForRow:rowModel];
    cell.accessoryType = rowModel.selectionFuture ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = rowModel.selectionFuture ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    UIViewController *viewControllerToPush = nil;
    if (rowModel.selectionFuture) {
        viewControllerToPush = rowModel.selectionFuture();
    }

    if (viewControllerToPush) {
        [self.navigationController pushViewController:viewControllerToPush animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
    NSAttributedString *attributedText = [[self class] attributedTextForRow:row];
    BOOL showsAccessory = row.selectionFuture != nil;
    return [FLEXMultilineTableViewCell preferredHeightWithAttributedText:attributedText inTableViewWidth:self.tableView.bounds.size.width style:UITableViewStyleGrouped showsAccessory:showsAccessory];
}

- (FLEXNetworkDetailRow *)rowModelAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXNetworkDetailSection *sectionModel = [self.sections objectAtIndex:indexPath.section];
    return [sectionModel.rows objectAtIndex:indexPath.row];
}

#pragma mark - View Configuration

+ (NSAttributedString *)attributedTextForRow:(FLEXNetworkDetailRow *)row
{
    NSDictionary *titleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0],
                                       NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1.0] };
    NSDictionary *detailAttributes = @{ NSFontAttributeName : [FLEXUtility defaultTableViewCellLabelFont],
                                        NSForegroundColorAttributeName : [UIColor blackColor] };

    NSString *title = [NSString stringWithFormat:@"%@: ", row.title];
    NSString *detailText = row.detailText ?: @"";
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttributes]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:detailText attributes:detailAttributes]];

    return attributedText;
}

#pragma mark - Table Data Generation

+ (FLEXNetworkDetailSection *)generalSectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    NSMutableArray *rows = [NSMutableArray array];

    FLEXNetworkDetailRow *requestURLRow = [[FLEXNetworkDetailRow alloc] init];
    requestURLRow.title = @"Request URL";
    NSURL *url = transaction.request.URL;
    requestURLRow.detailText = url.absoluteString;
    requestURLRow.selectionFuture = ^{
        UIViewController *urlWebViewController = [[FLEXWebViewController alloc] initWithURL:url];
        urlWebViewController.title = url.absoluteString;
        return urlWebViewController;
    };
    [rows addObject:requestURLRow];

    FLEXNetworkDetailRow *responseBodyRow = [[FLEXNetworkDetailRow alloc] init];
    responseBodyRow.title = @"Response Body";
    NSData *responseData = [[FLEXNetworkRecorder defaultRecorder] cachedResponseBodyForTransaction:transaction];
    if ([responseData length] > 0) {
        responseBodyRow.detailText = @"tap to view";
        // Avoid a long lived strong reference to the response data in case we need to purge it from the cache.
        __weak NSData *weakResponseData = responseData;
        responseBodyRow.selectionFuture = ^{
            UIViewController *responseBodyDetailViewController = nil;
            NSData *strongResponseData = weakResponseData;
            if (strongResponseData) {
                responseBodyDetailViewController = [self detailViewControllerForMIMEType:transaction.response.MIMEType data:strongResponseData];
            } else {
                // FIXME (RKO): Show an alert explaining that the data was purged?
            }
            return responseBodyDetailViewController;
        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"empty" : @"purged from cache";
    }
    [rows addObject:responseBodyRow];

    FLEXNetworkDetailRow *requestMethodRow = [[FLEXNetworkDetailRow alloc] init];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    NSString *statusCodeString = [FLEXUtility statusCodeStringFromURLResponse:transaction.response];
    if ([statusCodeString length] > 0) {
        FLEXNetworkDetailRow *statusCodeRow = [[FLEXNetworkDetailRow alloc] init];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    FLEXNetworkDetailRow *mimeTypeRow = [[FLEXNetworkDetailRow alloc] init];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    FLEXNetworkDetailRow *responseSizeRow = [[FLEXNetworkDetailRow alloc] init];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    FLEXNetworkDetailRow *durationRow = [[FLEXNetworkDetailRow alloc] init];
    durationRow.title = @"Total Duration";
    durationRow.detailText = [FLEXUtility stringFromRequestDuration:transaction.duration];
    [rows addObject:durationRow];

    FLEXNetworkDetailRow *latencyRow = [[FLEXNetworkDetailRow alloc] init];
    latencyRow.title = @"Latency";
    latencyRow.detailText = [FLEXUtility stringFromRequestDuration:transaction.latency];
    [rows addObject:latencyRow];

    FLEXNetworkDetailSection *generalSection = [[FLEXNetworkDetailSection alloc] init];
    generalSection.title = @"General";
    generalSection.rows = rows;

    return generalSection;
}

+ (FLEXNetworkDetailSection *)requestHeadersSectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    FLEXNetworkDetailSection *requestHeadersSection = [[FLEXNetworkDetailSection alloc] init];
    requestHeadersSection.title = @"Request Headers";
    requestHeadersSection.rows = [self networkDetailRowsFromDictionary:transaction.request.allHTTPHeaderFields];

    return requestHeadersSection;
}

+ (FLEXNetworkDetailSection *)queryParametersSectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    NSDictionary *queryDictionary = [FLEXUtility queryDictionaryFromURL:transaction.request.URL];
    FLEXNetworkDetailSection *querySection = [[FLEXNetworkDetailSection alloc] init];
    querySection.title = @"Query Parameters";
    querySection.rows = [self networkDetailRowsFromDictionary:queryDictionary];

    return querySection;
}

+ (FLEXNetworkDetailSection *)responseHeadersSectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    FLEXNetworkDetailSection *responseHeadersSection = [[FLEXNetworkDetailSection alloc] init];
    responseHeadersSection.title = @"Response Headers";
    if ([transaction.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
        responseHeadersSection.rows = [self networkDetailRowsFromDictionary:httpResponse.allHeaderFields];
    }
    return responseHeadersSection;
}

+ (NSArray *)networkDetailRowsFromDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[dictionary count]];
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString *key in sortedKeys) {
        NSString *value = [dictionary objectForKey:key];
        FLEXNetworkDetailRow *row = [[FLEXNetworkDetailRow alloc] init];
        row.title = key;
        row.detailText = value;
        [rows addObject:row];
    }
    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data
{
    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([mimeType isEqual:@"application/json"]) {
        NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:data];
        detailViewController = [[FLEXWebViewController alloc] initWithText:prettyJSON];
    } else if ([mimeType hasPrefix:@"image/"]) {
        UIImage *image = [UIImage imageWithData:data];
        detailViewController = [[FLEXImagePreviewViewController alloc] initWithImage:image];
    } else if ([mimeType hasPrefix:@"text/"]) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        detailViewController = [[FLEXWebViewController alloc] initWithText:text];
    }
    detailViewController.title = @"Response";
    return detailViewController;
}

@end
