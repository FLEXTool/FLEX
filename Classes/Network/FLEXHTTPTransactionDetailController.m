//
//  FLEXNetworkTransactionDetailController.m
//  Flipboard
//
//  Created by Ryan Olson on 2/10/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXHTTPTransactionDetailController.h"
#import "FLEXNetworkCurlLogger.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXWebViewController.h"
#import "FLEXImagePreviewViewController.h"
#import "FLEXMultilineTableViewCell.h"
#import "FLEXUtility.h"
#import "FLEXManager+Private.h"
#import "FLEXTableView.h"
#import "UIBarButtonItem+FLEX.h"
#import "NSDateFormatter+FLEX.h"

typedef UIViewController *(^FLEXNetworkDetailRowSelectionFuture)(void);

@interface FLEXNetworkDetailRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) FLEXNetworkDetailRowSelectionFuture selectionFuture;
@end

@implementation FLEXNetworkDetailRow
@end

@interface FLEXNetworkDetailSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<FLEXNetworkDetailRow *> *rows;
@end

@implementation FLEXNetworkDetailSection
@end

@interface FLEXHTTPTransactionDetailController ()

@property (nonatomic, readonly) FLEXHTTPTransaction *transaction;
@property (nonatomic, copy) NSArray<FLEXNetworkDetailSection *> *sections;

@end

@implementation FLEXHTTPTransactionDetailController

+ (instancetype)withTransaction:(FLEXHTTPTransaction *)transaction {
    FLEXHTTPTransactionDetailController *controller = [self new];
    controller.transaction = transaction;
    return controller;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    // Force grouped style
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [NSNotificationCenter.defaultCenter addObserver:self
        selector:@selector(handleTransactionUpdatedNotification:)
        name:kFLEXNetworkRecorderTransactionUpdatedNotification
        object:nil
    ];
    self.toolbarItems = @[
        UIBarButtonItem.flex_flexibleSpace,
        [UIBarButtonItem
            flex_itemWithTitle:@"Copy curl"
            target:self
            action:@selector(copyButtonPressed:)
        ]
    ];
    
    [self.tableView registerClass:[FLEXMultilineTableViewCell class] forCellReuseIdentifier:kFLEXMultilineCell];
}

- (void)setTransaction:(FLEXHTTPTransaction *)transaction {
    if (![_transaction isEqual:transaction]) {
        _transaction = transaction;
        self.title = [transaction.request.URL lastPathComponent];
        [self rebuildTableSections];
    }
}

- (void)setSections:(NSArray<FLEXNetworkDetailSection *> *)sections {
    if (![_sections isEqual:sections]) {
        _sections = [sections copy];
        [self.tableView reloadData];
    }
}

- (void)rebuildTableSections {
    NSMutableArray<FLEXNetworkDetailSection *> *sections = [NSMutableArray new];

    FLEXNetworkDetailSection *generalSection = [[self class] generalSectionForTransaction:self.transaction];
    if (generalSection.rows.count > 0) {
        [sections addObject:generalSection];
    }
    FLEXNetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
    if (requestHeadersSection.rows.count > 0) {
        [sections addObject:requestHeadersSection];
    }
    FLEXNetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
    if (queryParametersSection.rows.count > 0) {
        [sections addObject:queryParametersSection];
    }
    FLEXNetworkDetailSection *postBodySection = [[self class] postBodySectionForTransaction:self.transaction];
    if (postBodySection.rows.count > 0) {
        [sections addObject:postBodySection];
    }
    FLEXNetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if (responseHeadersSection.rows.count > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification {
    FLEXNetworkTransaction *transaction = [[notification userInfo] objectForKey:kFLEXNetworkRecorderUserInfoTransactionKey];
    if (transaction == self.transaction) {
        [self rebuildTableSections];
    }
}

- (void)copyButtonPressed:(id)sender {
    [UIPasteboard.generalPasteboard setString:[FLEXNetworkCurlLogger curlCommandString:_transaction.request]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    FLEXNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    FLEXNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXMultilineCell forIndexPath:indexPath];

    FLEXNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    cell.textLabel.attributedText = [[self class] attributedTextForRow:rowModel];
    cell.accessoryType = rowModel.selectionFuture ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = rowModel.selectionFuture ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    UIViewController *viewController = nil;
    if (rowModel.selectionFuture) {
        viewController = rowModel.selectionFuture();
    }

    if ([viewController isKindOfClass:UIAlertController.class]) {
        [self presentViewController:viewController animated:YES completion:nil];
    } else if (viewController) {
        [self.navigationController pushViewController:viewController animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
    NSAttributedString *attributedText = [[self class] attributedTextForRow:row];
    BOOL showsAccessory = row.selectionFuture != nil;
    return [FLEXMultilineTableViewCell
        preferredHeightWithAttributedText:attributedText
        maxWidth:tableView.bounds.size.width
        style:tableView.style
        showsAccessory:showsAccessory
    ];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [NSArray flex_forEachUpTo:self.sections.count map:^id(NSUInteger i) {
        return @"⦁";
    }];
}

- (FLEXNetworkDetailRow *)rowModelAtIndexPath:(NSIndexPath *)indexPath {
    FLEXNetworkDetailSection *sectionModel = self.sections[indexPath.section];
    return sectionModel.rows[indexPath.row];
}

#pragma mark - Cell Copying

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        FLEXNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
        UIPasteboard.generalPasteboard.string = row.detailText;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
        previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction
                actionWithTitle:@"Copy"
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    FLEXNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
                    UIPasteboard.generalPasteboard.string = row.detailText;
                }
            ];
            return [UIMenu
                menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline
                children:@[copy]
            ];
        }
    ];
}

#pragma mark - View Configuration

+ (NSAttributedString *)attributedTextForRow:(FLEXNetworkDetailRow *)row {
    NSDictionary<NSString *, id> *titleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0],
                                                       NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1.0] };
    NSDictionary<NSString *, id> *detailAttributes = @{ NSFontAttributeName : UIFont.flex_defaultTableCellFont,
                                                        NSForegroundColorAttributeName : FLEXColor.primaryTextColor };

    NSString *title = [NSString stringWithFormat:@"%@: ", row.title];
    NSString *detailText = row.detailText ?: @"";
    NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttributes]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:detailText attributes:detailAttributes]];

    return attributedText;
}

#pragma mark - Table Data Generation

+ (FLEXNetworkDetailSection *)generalSectionForTransaction:(FLEXHTTPTransaction *)transaction {
    NSMutableArray<FLEXNetworkDetailRow *> *rows = [NSMutableArray new];

    FLEXNetworkDetailRow *requestURLRow = [FLEXNetworkDetailRow new];
    requestURLRow.title = @"Request URL";
    NSURL *url = transaction.request.URL;
    requestURLRow.detailText = url.absoluteString;
    requestURLRow.selectionFuture = ^{
        UIViewController *urlWebViewController = [[FLEXWebViewController alloc] initWithURL:url];
        urlWebViewController.title = url.absoluteString;
        return urlWebViewController;
    };
    [rows addObject:requestURLRow];

    FLEXNetworkDetailRow *requestMethodRow = [FLEXNetworkDetailRow new];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    if (transaction.cachedRequestBody.length > 0) {
        FLEXNetworkDetailRow *postBodySizeRow = [FLEXNetworkDetailRow new];
        postBodySizeRow.title = @"Request Body Size";
        postBodySizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.cachedRequestBody.length countStyle:NSByteCountFormatterCountStyleBinary];
        [rows addObject:postBodySizeRow];

        FLEXNetworkDetailRow *postBodyRow = [FLEXNetworkDetailRow new];
        postBodyRow.title = @"Request Body";
        postBodyRow.detailText = @"tap to view";
        postBodyRow.selectionFuture = ^UIViewController * () {
            // Show the body if we can
            NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
            UIViewController *detailViewController = [self detailViewControllerForMIMEType:contentType data:[self postBodyDataForTransaction:transaction]];
            if (detailViewController) {
                detailViewController.title = @"Request Body";
                return detailViewController;
            }

            // We can't show the body, alert user
            return [FLEXAlert makeAlert:^(FLEXAlert *make) {
                make.title(@"Can't View HTTP Body Data");
                make.message(@"FLEX does not have a viewer for request body data with MIME type: ");
                make.message(contentType);
                make.button(@"Dismiss").cancelStyle();
            }];
        };

        [rows addObject:postBodyRow];
    }

    NSString *statusCodeString = [FLEXUtility statusCodeStringFromURLResponse:transaction.response];
    if (statusCodeString.length > 0) {
        FLEXNetworkDetailRow *statusCodeRow = [FLEXNetworkDetailRow new];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    if (transaction.error) {
        FLEXNetworkDetailRow *errorRow = [FLEXNetworkDetailRow new];
        errorRow.title = @"Error";
        errorRow.detailText = transaction.error.localizedDescription;
        [rows addObject:errorRow];
    }

    FLEXNetworkDetailRow *responseBodyRow = [FLEXNetworkDetailRow new];
    responseBodyRow.title = @"Response Body";
    NSData *responseData = [FLEXNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        responseBodyRow.detailText = @"tap to view";

        // Avoid a long lived strong reference to the response data in case we need to purge it from the cache.
        weakify(responseData)
        responseBodyRow.selectionFuture = ^UIViewController *() { strongify(responseData)

            // Show the response if we can
            NSString *contentType = transaction.response.MIMEType;
            if (responseData) {
                UIViewController *bodyDetails = [self detailViewControllerForMIMEType:contentType data:responseData];
                if (bodyDetails) {
                    bodyDetails.title = @"Response";
                    return bodyDetails;
                }
            }

            // We can't show the response, alert user
            return [FLEXAlert makeAlert:^(FLEXAlert *make) {
                make.title(@"Unable to View Response");
                if (responseData) {
                    make.message(@"No viewer content type: ").message(contentType);
                } else {
                    make.message(@"The response has been purged from the cache");
                }
                make.button(@"OK").cancelStyle();
            }];
        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"empty" : @"not in cache";
    }

    [rows addObject:responseBodyRow];

    FLEXNetworkDetailRow *responseSizeRow = [FLEXNetworkDetailRow new];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    FLEXNetworkDetailRow *mimeTypeRow = [FLEXNetworkDetailRow new];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    FLEXNetworkDetailRow *mechanismRow = [FLEXNetworkDetailRow new];
    mechanismRow.title = @"Mechanism";
    mechanismRow.detailText = transaction.requestMechanism;
    [rows addObject:mechanismRow];

    FLEXNetworkDetailRow *localStartTimeRow = [FLEXNetworkDetailRow new];
    localStartTimeRow.title = [NSString stringWithFormat:@"Start Time (%@)", [NSTimeZone.localTimeZone abbreviationForDate:transaction.startTime]];
    localStartTimeRow.detailText = [NSDateFormatter flex_stringFrom:transaction.startTime format:FLEXDateFormatVerbose];
    [rows addObject:localStartTimeRow];

    FLEXNetworkDetailRow *utcStartTimeRow = [FLEXNetworkDetailRow new];
    utcStartTimeRow.title = @"Start Time (UTC)";
    utcStartTimeRow.detailText = [NSDateFormatter flex_stringFrom:transaction.startTime format:FLEXDateFormatVerbose];
    [rows addObject:utcStartTimeRow];

    FLEXNetworkDetailRow *unixStartTime = [FLEXNetworkDetailRow new];
    unixStartTime.title = @"Unix Start Time";
    unixStartTime.detailText = [NSString stringWithFormat:@"%f", [transaction.startTime timeIntervalSince1970]];
    [rows addObject:unixStartTime];

    FLEXNetworkDetailRow *durationRow = [FLEXNetworkDetailRow new];
    durationRow.title = @"Total Duration";
    durationRow.detailText = [FLEXUtility stringFromRequestDuration:transaction.duration];
    [rows addObject:durationRow];

    FLEXNetworkDetailRow *latencyRow = [FLEXNetworkDetailRow new];
    latencyRow.title = @"Latency";
    latencyRow.detailText = [FLEXUtility stringFromRequestDuration:transaction.latency];
    [rows addObject:latencyRow];

    FLEXNetworkDetailSection *generalSection = [FLEXNetworkDetailSection new];
    generalSection.title = @"General";
    generalSection.rows = rows;

    return generalSection;
}

+ (FLEXNetworkDetailSection *)requestHeadersSectionForTransaction:(FLEXHTTPTransaction *)transaction {
    FLEXNetworkDetailSection *requestHeadersSection = [FLEXNetworkDetailSection new];
    requestHeadersSection.title = @"Request Headers";
    requestHeadersSection.rows = [self networkDetailRowsFromDictionary:transaction.request.allHTTPHeaderFields];

    return requestHeadersSection;
}

+ (FLEXNetworkDetailSection *)postBodySectionForTransaction:(FLEXHTTPTransaction *)transaction {
    FLEXNetworkDetailSection *postBodySection = [FLEXNetworkDetailSection new];
    postBodySection.title = @"Request Body Parameters";
    if (transaction.cachedRequestBody.length > 0) {
        NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
        if ([contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *body = [self postBodyDataForTransaction:transaction];
            NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            postBodySection.rows = [self networkDetailRowsFromQueryItems:[FLEXUtility itemsFromQueryString:bodyString]];
        }
    }
    return postBodySection;
}

+ (FLEXNetworkDetailSection *)queryParametersSectionForTransaction:(FLEXHTTPTransaction *)transaction {
    NSArray<NSURLQueryItem *> *queries = [FLEXUtility itemsFromQueryString:transaction.request.URL.query];
    FLEXNetworkDetailSection *querySection = [FLEXNetworkDetailSection new];
    querySection.title = @"Query Parameters";
    querySection.rows = [self networkDetailRowsFromQueryItems:queries];

    return querySection;
}

+ (FLEXNetworkDetailSection *)responseHeadersSectionForTransaction:(FLEXHTTPTransaction *)transaction {
    FLEXNetworkDetailSection *responseHeadersSection = [FLEXNetworkDetailSection new];
    responseHeadersSection.title = @"Response Headers";
    if ([transaction.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
        responseHeadersSection.rows = [self networkDetailRowsFromDictionary:httpResponse.allHeaderFields];
    }
    return responseHeadersSection;
}

+ (NSArray<FLEXNetworkDetailRow *> *)networkDetailRowsFromDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSMutableArray<FLEXNetworkDetailRow *> *rows = [NSMutableArray new];
    NSArray<NSString *> *sortedKeys = [dictionary.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *key in sortedKeys) {
        id value = dictionary[key];
        FLEXNetworkDetailRow *row = [FLEXNetworkDetailRow new];
        row.title = key;
        row.detailText = [value description];
        [rows addObject:row];
    }

    return rows.copy;
}

+ (NSArray<FLEXNetworkDetailRow *> *)networkDetailRowsFromQueryItems:(NSArray<NSURLQueryItem *> *)items {
    // Sort the items by name
    items = [items sortedArrayUsingComparator:^NSComparisonResult(NSURLQueryItem *item1, NSURLQueryItem *item2) {
        return [item1.name caseInsensitiveCompare:item2.name];
    }];

    NSMutableArray<FLEXNetworkDetailRow *> *rows = [NSMutableArray new];
    for (NSURLQueryItem *item in items) {
        FLEXNetworkDetailRow *row = [FLEXNetworkDetailRow new];
        row.title = item.name;
        row.detailText = item.value;
        [rows addObject:row];
    }

    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data {
    FLEXCustomContentViewerFuture makeCustomViewer = FLEXManager.sharedManager.customContentTypeViewers[mimeType.lowercaseString];

    if (makeCustomViewer) {
        UIViewController *viewer = makeCustomViewer(data);

        if (viewer) {
            return viewer;
        }
    }

    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([FLEXUtility isValidJSONData:data]) {
        NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            detailViewController = [[FLEXWebViewController alloc] initWithText:prettyJSON];
        }
    } else if ([mimeType hasPrefix:@"image/"]) {
        UIImage *image = [UIImage imageWithData:data];
        detailViewController = [FLEXImagePreviewViewController forImage:image];
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        detailViewController = [[FLEXWebViewController alloc] initWithText:[propertyList description]];
    }

    // Fall back to trying to show the response as text
    if (!detailViewController) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (text.length > 0) {
            detailViewController = [[FLEXWebViewController alloc] initWithText:text];
        }
    }
    return detailViewController;
}

+ (NSData *)postBodyDataForTransaction:(FLEXHTTPTransaction *)transaction {
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0) {
        NSString *contentEncoding = [transaction.request valueForHTTPHeaderField:@"Content-Encoding"];
        if ([contentEncoding rangeOfString:@"deflate" options:NSCaseInsensitiveSearch].length > 0 || [contentEncoding rangeOfString:@"gzip" options:NSCaseInsensitiveSearch].length > 0) {
            bodyData = [FLEXUtility inflatedDataFromCompressedData:bodyData];
        }
    }
    return bodyData;
}

@end
