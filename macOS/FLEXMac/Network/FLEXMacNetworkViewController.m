//
//  FLEXMacNetworkViewController.m
//  FLEX (macOS)
//

#import "FLEXMacNetworkViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacUtility.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXNetworkCurlLogger.h"
#import "FLEXUtility.h"

#pragma mark - History

@interface FLEXMacNetworkViewController ()
@property (nonatomic) NSButton *enabledCheckbox;
@property (nonatomic) BOOL reloadScheduled;
@end

@implementation FLEXMacNetworkViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Network History";
        self.searchPlaceholder = @"Filter by URL";

        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        for (NSString *name in @[
            kFLEXNetworkRecorderNewTransactionNotification,
            kFLEXNetworkRecorderTransactionUpdatedNotification,
            kFLEXNetworkRecorderTransactionsClearedNotification,
            kFLEXNetworkObserverEnabledStateChangedNotification,
        ]) {
            [center addObserver:self selector:@selector(networkChanged:) name:name object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    self.enabledCheckbox = [NSButton checkboxWithTitle:@"Record network requests" target:self action:@selector(toggleEnabled:)];
    self.enabledCheckbox.controlSize = NSControlSizeSmall;
    self.enabledCheckbox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.headerAccessoryView = self.enabledCheckbox;
    [super viewDidLoad];
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    return @[FLEXMacBarButton(@"trash", @"Clear", @"Clear network history", self, @selector(clear:))];
}

- (void)toggleEnabled:(id)sender {
    FLEXNetworkObserver.enabled = self.enabledCheckbox.state == NSControlStateValueOn;
}

- (void)clear:(id)sender {
    [FLEXNetworkRecorder.defaultRecorder clearRecordedActivity];
}

- (void)networkChanged:(NSNotification *)note {
    // Coalesce bursts of updates
    if (self.reloadScheduled) {
        return;
    }
    self.reloadScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.reloadScheduled = NO;
        if (self.isViewLoaded) {
            [self reloadData];
        }
    });
}

- (NSArray<FLEXMacSection *> *)makeSections {
    BOOL enabled = FLEXNetworkObserver.isEnabled;
    self.enabledCheckbox.state = enabled ? NSControlStateValueOn : NSControlStateValueOff;
    self.emptyText = enabled ? @"No requests yet" : @"Network recording is off. Turn it on above, or set FLEXManager.sharedManager.networkDebuggingEnabled = YES at launch.";

    NSArray<FLEXHTTPTransaction *> *transactions = FLEXNetworkRecorder.defaultRecorder.HTTPTransactions;
    NSMutableArray *rows = [NSMutableArray new];
    for (FLEXHTTPTransaction *transaction in transactions) {
        FLEXMacRow *row = [FLEXMacRow
            title:[NSString stringWithFormat:@"%@  %@", transaction.request.HTTPMethod ?: @"GET", transaction.primaryDescription]
            subtitle:[NSString stringWithFormat:@"%@\n%@", transaction.secondaryDescription ?: @"", transaction.tertiaryDescription ?: @""]
            pushing:^NSViewController *{
                return [FLEXMacNetworkDetailViewController detailsForTransaction:transaction];
            }
        ];
        row.subtitleMaxLines = 2;
        row.copyString = transaction.request.URL.absoluteString;
        row.image = transaction.thumbnail;
        if (transaction.displayAsError || [FLEXUtility isErrorStatusCodeFromURLResponse:transaction.response]) {
            row.titleColor = NSColor.systemRedColor;
        }
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[
                FLEXMacMenuItem(@"Copy URL", ^{
                    [FLEXMacUtility copyToPasteboard:transaction.request.URL.absoluteString];
                }),
                FLEXMacMenuItem(@"Copy as cURL", ^{
                    [FLEXMacUtility copyToPasteboard:[FLEXNetworkCurlLogger curlCommandString:transaction.request]];
                }),
                FLEXMacMenuItem([NSString stringWithFormat:@"Exclude Host '%@'", transaction.request.URL.host], ^{
                    NSString *host = transaction.request.URL.host;
                    if (host.length) {
                        [FLEXNetworkRecorder.defaultRecorder.hostDenylist addObject:host];
                        [FLEXNetworkRecorder.defaultRecorder synchronizeDenylist];
                        [FLEXNetworkRecorder.defaultRecorder clearExcludedTransactions];
                    }
                }),
            ];
        };
        [rows addObject:row];
    }

    if (!rows.count) {
        return @[];
    }
    long long totalBytes = 0;
    for (FLEXHTTPTransaction *transaction in transactions) {
        totalBytes += transaction.receivedDataLength;
    }
    NSString *title = [NSString stringWithFormat:@"%lu requests — %@ received",
        (unsigned long)rows.count, [FLEXMacUtility stringForByteCount:totalBytes]];
    return @[[FLEXMacSection title:title rows:rows]];
}

@end

#pragma mark - Details

@interface FLEXMacNetworkDetailViewController ()
@property (nonatomic) FLEXHTTPTransaction *transaction;
@end

@implementation FLEXMacNetworkDetailViewController

+ (instancetype)detailsForTransaction:(FLEXHTTPTransaction *)transaction {
    FLEXMacNetworkDetailViewController *details = [self new];
    details.transaction = transaction;
    details.title = transaction.primaryDescription;
    details.showsRefreshButton = YES;
    return details;
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    return @[FLEXMacBarButton(@"terminal", @"cURL", @"Copy as cURL command", self, @selector(copyCurl:))];
}

- (void)copyCurl:(id)sender {
    [FLEXMacUtility copyToPasteboard:[FLEXNetworkCurlLogger curlCommandString:self.transaction.request]];
}

static FLEXMacRow *FLEXMacDetailRow(NSString *title, NSString *value) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:value.length ? value : @"—"];
    row.copyString = value;
    return row;
}

+ (NSArray<FLEXMacRow *> *)rowsForHeaders:(NSDictionary<NSString *, NSString *> *)headers {
    NSMutableArray *rows = [NSMutableArray new];
    for (NSString *key in [headers.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
        [rows addObject:FLEXMacDetailRow(key, headers[key])];
    }
    return rows;
}

/// A viewer appropriate for a request or response body
+ (NSViewController *)viewerForBody:(NSData *)data contentType:(NSString *)contentType title:(NSString *)title {
    if (!data.length) {
        return nil;
    }

    if ([contentType hasPrefix:@"image/"]) {
        NSImage *image = [[NSImage alloc] initWithData:data];
        if (image) {
            return [FLEXMacImagePreviewViewController previewForImage:image title:title];
        }
    }

    if ([FLEXUtility isValidJSONData:data]) {
        NSString *pretty = [FLEXUtility prettyJSONStringFromData:data];
        if (pretty) {
            return [FLEXMacTextViewController viewerWithText:pretty title:title];
        }
    }

    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    if (plist && ![plist isKindOfClass:[NSString class]]) {
        return [FLEXMacObjectExplorerViewController explorerForObject:plist];
    }

    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (text) {
        return [FLEXMacTextViewController viewerWithText:text title:title];
    }

    return [FLEXMacObjectExplorerViewController explorerForObject:data];
}

- (NSArray<FLEXMacSection *> *)makeSections {
    FLEXHTTPTransaction *transaction = self.transaction;
    NSURLRequest *request = transaction.request;
    NSHTTPURLResponse *response = [transaction.response isKindOfClass:[NSHTTPURLResponse class]] ? (id)transaction.response : nil;

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;

    NSMutableArray *general = [NSMutableArray arrayWithArray:@[
        FLEXMacDetailRow(@"Request URL", request.URL.absoluteString),
        FLEXMacDetailRow(@"Method", request.HTTPMethod),
        FLEXMacDetailRow(@"Status", transaction.response ?
            [FLEXUtility statusCodeStringFromURLResponse:transaction.response] :
            [FLEXNetworkTransaction readableStringFromTransactionState:transaction.state]),
        FLEXMacDetailRow(@"Mechanism", transaction.requestMechanism),
        FLEXMacDetailRow(@"Start Time", [formatter stringFromDate:transaction.startTime]),
        FLEXMacDetailRow(@"Latency", [FLEXUtility stringFromRequestDuration:transaction.latency]),
        FLEXMacDetailRow(@"Duration", [FLEXUtility stringFromRequestDuration:transaction.duration]),
        FLEXMacDetailRow(@"Response Size", [FLEXMacUtility stringForByteCount:transaction.receivedDataLength]),
        FLEXMacDetailRow(@"MIME Type", transaction.response.MIMEType),
    ]];
    if (transaction.error) {
        FLEXMacRow *errorRow = [FLEXMacRow title:@"Error" subtitle:transaction.error.localizedDescription exploring:transaction.error];
        errorRow.titleColor = NSColor.systemRedColor;
        [general addObject:errorRow];
    }

    NSData *requestBody = transaction.cachedRequestBody;
    NSString *requestType = [request valueForHTTPHeaderField:@"Content-Type"];
    if ([FLEXUtility hasCompressedContentEncoding:request]) {
        requestBody = [FLEXUtility inflatedDataFromCompressedData:requestBody] ?: requestBody;
    }

    NSData *responseBody = [FLEXNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    NSString *responseType = transaction.response.MIMEType;

    FLEXMacRow *requestBodyRow = [FLEXMacRow
        title:@"Request Body"
        subtitle:requestBody.length ? [FLEXMacUtility stringForByteCount:requestBody.length] : @"None"
        pushing:requestBody.length ? ^NSViewController *{
            return [FLEXMacNetworkDetailViewController viewerForBody:requestBody contentType:requestType title:@"Request Body"];
        } : nil
    ];
    NSString *responseSubtitle = responseBody.length ? [FLEXMacUtility stringForByteCount:responseBody.length] :
        (transaction.state == FLEXNetworkTransactionStateFinished ? @"Not cached or empty" : @"Not available yet");
    FLEXMacRow *responseBodyRow = [FLEXMacRow
        title:@"Response Body"
        subtitle:responseSubtitle
        pushing:responseBody.length ? ^NSViewController *{
            return [FLEXMacNetworkDetailViewController viewerForBody:responseBody contentType:responseType title:@"Response Body"];
        } : nil
    ];

    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[
        [FLEXMacSection title:@"General" rows:general],
        [FLEXMacSection title:@"Bodies" rows:@[requestBodyRow, responseBodyRow]],
    ]];

    NSArray *requestHeaders = [FLEXMacNetworkDetailViewController rowsForHeaders:request.allHTTPHeaderFields];
    if (requestHeaders.count) {
        [sections addObject:[FLEXMacSection title:@"Request Headers" rows:requestHeaders]];
    }
    NSArray *responseHeaders = [FLEXMacNetworkDetailViewController rowsForHeaders:response.allHeaderFields];
    if (responseHeaders.count) {
        [sections addObject:[FLEXMacSection title:@"Response Headers" rows:responseHeaders]];
    }

    NSArray<NSURLQueryItem *> *query = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO].queryItems;
    if (query.count) {
        NSMutableArray *rows = [NSMutableArray new];
        for (NSURLQueryItem *item in query) {
            [rows addObject:FLEXMacDetailRow(item.name, item.value)];
        }
        [sections addObject:[FLEXMacSection title:@"Query Parameters" rows:rows]];
    }

    [sections addObject:[FLEXMacSection title:@"Objects" rows:@[
        [FLEXMacRow title:@"Request" subtitle:request.description exploring:request],
        [FLEXMacRow title:@"Response" subtitle:transaction.response.description exploring:transaction.response],
        [FLEXMacRow title:@"Transaction" subtitle:nil exploring:transaction],
    ]]];

    return sections;
}

@end
