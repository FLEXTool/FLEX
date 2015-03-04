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
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTransactionUpdatedNotification:) name:kFLEXNetworkRecorderTransactionUpdatedNotification object:nil];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonPressed:)];
    }
    return self;
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
    FLEXNetworkDetailSection *postBodySection = [[self class] postBodySectionForTransaction:self.transaction];
    if ([postBodySection.rows count] > 0) {
        [sections addObject:postBodySection];
    }
    FLEXNetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if ([responseHeadersSection.rows count] > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification
{
    FLEXNetworkTransaction *transaction = [[notification userInfo] objectForKey:kFLEXNetworkRecorderUserInfoTransactionKey];
    if (transaction == self.transaction) {
        [self rebuildTableSections];
    }
}

- (void)copyButtonPressed:(id)sender
{
    NSMutableString *requestDetailString = [NSMutableString string];

    for (FLEXNetworkDetailSection *section in self.sections) {
        if ([section.rows count] > 0) {
            if ([section.title length] > 0) {
                [requestDetailString appendString:section.title];
                [requestDetailString appendString:@"\n\n"];
            }
            for (FLEXNetworkDetailRow *row in section.rows) {
                NSString *rowDescription = [[[self class] attributedTextForRow:row] string];
                if ([rowDescription length] > 0) {
                    [requestDetailString appendString:rowDescription];
                    [requestDetailString appendString:@"\n"];
                }
            }
            [requestDetailString appendString:@"\n\n"];
        }
    }

    [[UIPasteboard generalPasteboard] setString:requestDetailString];
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

#pragma mark - Cell Copying

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        FLEXNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
        [[UIPasteboard generalPasteboard] setString:row.detailText];
    }
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

    FLEXNetworkDetailRow *requestMethodRow = [[FLEXNetworkDetailRow alloc] init];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    if ([transaction.request.HTTPBody length] > 0) {
        FLEXNetworkDetailRow *postBodySizeRow = [[FLEXNetworkDetailRow alloc] init];
        postBodySizeRow.title = @"Request Body Size";
        postBodySizeRow.detailText = [NSByteCountFormatter stringFromByteCount:[transaction.request.HTTPBody length] countStyle:NSByteCountFormatterCountStyleBinary];
        [rows addObject:postBodySizeRow];

        FLEXNetworkDetailRow *postBodyRow = [[FLEXNetworkDetailRow alloc] init];
        postBodyRow.title = @"Request Body";
        postBodyRow.detailText = @"tap to view";
        postBodyRow.selectionFuture = ^{
            NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
            UIViewController *detailViewController = [self detailViewControllerForMIMEType:contentType data:[self postBodyDataForTransaction:transaction]];
            if (detailViewController) {
                detailViewController.title = @"Request Body";
            } else {
                NSString *alertMessage = [NSString stringWithFormat:@"FLEX does not have a viewer for request body data with MIME type: %@", [transaction.request valueForHTTPHeaderField:@"Content-Type"]];
                [[[UIAlertView alloc] initWithTitle:@"Can't View Body Data" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            return detailViewController;
        };
        [rows addObject:postBodyRow];
    }

    NSString *statusCodeString = [FLEXUtility statusCodeStringFromURLResponse:transaction.response];
    if ([statusCodeString length] > 0) {
        FLEXNetworkDetailRow *statusCodeRow = [[FLEXNetworkDetailRow alloc] init];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    if (transaction.error) {
        FLEXNetworkDetailRow *errorRow = [[FLEXNetworkDetailRow alloc] init];
        errorRow.title = @"Error";
        errorRow.detailText = transaction.error.localizedDescription;
        [rows addObject:errorRow];
    }

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
                if (!responseBodyDetailViewController) {
                    NSString *alertMessage = [NSString stringWithFormat:@"FLEX does not have a viewer for responses with MIME type: %@", transaction.response.MIMEType];
                    [[[UIAlertView alloc] initWithTitle:@"Can't View Response" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
                responseBodyDetailViewController.title = @"Response";
            } else {
                NSString *alertMessage = @"The response has been purged from the cache";
                [[[UIAlertView alloc] initWithTitle:@"Can't View Response" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            return responseBodyDetailViewController;
        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"empty" : @"not in cache";
    }
    [rows addObject:responseBodyRow];

    FLEXNetworkDetailRow *responseSizeRow = [[FLEXNetworkDetailRow alloc] init];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    FLEXNetworkDetailRow *mimeTypeRow = [[FLEXNetworkDetailRow alloc] init];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    FLEXNetworkDetailRow *mechanismRow = [[FLEXNetworkDetailRow alloc] init];
    mechanismRow.title = @"Mechanism";
    mechanismRow.detailText = transaction.requestMechanism;
    [rows addObject:mechanismRow];

    NSDateFormatter *startTimeFormatter = [[NSDateFormatter alloc] init];
    startTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";

    FLEXNetworkDetailRow *localStartTimeRow = [[FLEXNetworkDetailRow alloc] init];
    localStartTimeRow.title = [NSString stringWithFormat:@"Start Time (%@)", [[NSTimeZone localTimeZone] abbreviationForDate:transaction.startTime]];
    localStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:localStartTimeRow];

    startTimeFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    FLEXNetworkDetailRow *utcStartTimeRow = [[FLEXNetworkDetailRow alloc] init];
    utcStartTimeRow.title = @"Start Time (UTC)";
    utcStartTimeRow.detailText = [startTimeFormatter stringFromDate:transaction.startTime];
    [rows addObject:utcStartTimeRow];

    FLEXNetworkDetailRow *unixStartTime = [[FLEXNetworkDetailRow alloc] init];
    unixStartTime.title = @"Unix Start Time";
    unixStartTime.detailText = [NSString stringWithFormat:@"%f", [transaction.startTime timeIntervalSince1970]];
    [rows addObject:unixStartTime];

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

+ (FLEXNetworkDetailSection *)postBodySectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    FLEXNetworkDetailSection *postBodySection = [[FLEXNetworkDetailSection alloc] init];
    postBodySection.title = @"Request Body Parameters";
    if ([transaction.request.HTTPBody length] > 0) {
        NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
        if ([contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSString *bodyString = [[NSString alloc] initWithData:[self postBodyDataForTransaction:transaction] encoding:NSUTF8StringEncoding];
            postBodySection.rows = [self networkDetailRowsFromDictionary:[FLEXUtility dictionaryFromQuery:bodyString]];
        }
    }
    return postBodySection;
}

+ (FLEXNetworkDetailSection *)queryParametersSectionForTransaction:(FLEXNetworkTransaction *)transaction
{
    NSDictionary *queryDictionary = [FLEXUtility dictionaryFromQuery:transaction.request.URL.query];
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
        row.detailText = [value description];
        [rows addObject:row];
    }
    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data
{
    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([FLEXUtility isValidJSONData:data]) {
        NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:data];
        if ([prettyJSON length] > 0) {
            detailViewController = [[FLEXWebViewController alloc] initWithText:prettyJSON];
        }
    } else if ([mimeType hasPrefix:@"image/"]) {
        UIImage *image = [UIImage imageWithData:data];
        detailViewController = [[FLEXImagePreviewViewController alloc] initWithImage:image];
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        detailViewController = [[FLEXWebViewController alloc] initWithText:[propertyList description]];
    }

    // Fall back to trying to show the response as text
    if (!detailViewController) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([text length] > 0) {
            detailViewController = [[FLEXWebViewController alloc] initWithText:text];
        }
    }
    return detailViewController;
}

+ (NSData *)postBodyDataForTransaction:(FLEXNetworkTransaction *)transaction
{
    NSData *bodyData = transaction.request.HTTPBody;
    if ([bodyData length] > 0) {
        NSString *contentEncoding = [transaction.request valueForHTTPHeaderField:@"Content-Encoding"];
        if ([contentEncoding rangeOfString:@"deflate" options:NSCaseInsensitiveSearch].length > 0 || [contentEncoding rangeOfString:@"gzip" options:NSCaseInsensitiveSearch].length > 0) {
            bodyData = [FLEXUtility inflatedDataFromCompressedData:bodyData];
        }
    }
    return bodyData;
}

@end
