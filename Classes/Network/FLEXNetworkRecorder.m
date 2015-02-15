//
//  FLEXNetworkRecorder.m
//  Flipboard
//
//  Created by Ryan Olson on 2/4/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"

NSString *const kFLEXNetworkRecorderNewTransactionNotification = @"kFLEXNetworkRecorderNewTransactionNotification";
NSString *const kFLEXNetworkRecorderTransactionUpdatedNotification = @"kFLEXNetworkRecorderTransactionUpdatedNotification";
NSString *const kFLEXNetworkRecorderUserInfoTransactionKey = @"transaction";

@interface FLEXNetworkRecorder ()

@property (nonatomic, strong) NSCache *responseCache;
@property (nonatomic, strong) NSMutableArray *orderedTransactions;
@property (nonatomic, strong) NSMutableDictionary *networkTransactionsForRequestIdentifiers;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation FLEXNetworkRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseCache = [[NSCache alloc] init];
        self.orderedTransactions = [NSMutableArray array];
        self.networkTransactionsForRequestIdentifiers = [NSMutableDictionary dictionary];
        self.queue = dispatch_queue_create("com.flex.FLEXNetworkRecorder", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (instancetype)defaultRecorder
{
    static FLEXNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [[[self class] alloc] init];
    });
    return defaultRecorder;
}

#pragma mark - Public Data Access

- (NSArray *)networkTransactions
{
    __block NSArray *transactions = nil;
    dispatch_sync(self.queue, ^{
        transactions = [self.orderedTransactions copy];
    });
    return transactions;
}

- (NSData *)cachedResponseBodyForTransaction:(FLEXNetworkTransaction *)transaction
{
    return [self.responseCache objectForKey:transaction.requestId];
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestId:(NSString *)requestId request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    // Use a barrier here because we mutate collections that are not thread safe.
    dispatch_barrier_async(self.queue, ^{
        // FIXME (RKO): What to do with the redirect response?

        FLEXNetworkTransaction *transaction = [[FLEXNetworkTransaction alloc] init];
        transaction.requestId = requestId;
        transaction.request = request;
        transaction.startTime = [NSDate date];
        transaction.transactionState = FLEXNetworkTransactionStateAwaitingResponse;

        [self.orderedTransactions insertObject:transaction atIndex:0];
        [self.networkTransactionsForRequestIdentifiers setObject:transaction forKey:requestId];

        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestId:(NSString *)requestId response:(NSURLResponse *)response
{
    dispatch_async(self.queue, ^{
        FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
        transaction.response = response;
        transaction.transactionState = FLEXNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceNow];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestId:(NSString *)requestId dataLength:(int64_t)dataLength
{
    dispatch_async(self.queue, ^{
        FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
        transaction.receivedDataLength += dataLength;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestId:(NSString *)requestId responseBody:(NSData *)responseBody
{
    dispatch_async(self.queue, ^{
        FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
        transaction.transactionState = FLEXNetworkTransactionStateFinished;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];

        if ([responseBody length] > 0) {
            [self.responseCache setObject:responseBody forKey:requestId cost:[responseBody length]];
        }

        NSString *mimeType = transaction.response.MIMEType;
        if ([mimeType hasPrefix:@"image/"]) {
            // Thumbnail image previews on a separate background queue
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSInteger maxPixelDimension = [[UIScreen mainScreen] scale] * 32.0;
                transaction.responseThumbnail = [FLEXUtility thumbnailedImageWithMaxPixelDimension:maxPixelDimension fromImageData:responseBody];
                [self postUpdateNotificationForTransaction:transaction];
            });
        } else if ([mimeType isEqual:@"application/json"]) {
            transaction.responseThumbnail = [FLEXResources jsonIcon];
        } else if ([mimeType isEqual:@"text/plain"]){
            transaction.responseThumbnail = [FLEXResources textPlainIcon];
        } else if ([mimeType isEqual:@"text/html"]) {
            transaction.responseThumbnail = [FLEXResources htmlIcon];
        }
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFailedWithRequestId:(NSString *)requestId error:(NSError *)error
{
    dispatch_async(self.queue, ^{
        FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
        transaction.transactionState = FLEXNetworkTransactionStateFailed;
        transaction.duration = [transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)postNewTransactionNotificationWithTransaction:(FLEXNetworkTransaction *)transaction
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{ kFLEXNetworkRecorderUserInfoTransactionKey : transaction };
        [[NSNotificationCenter defaultCenter] postNotificationName:kFLEXNetworkRecorderNewTransactionNotification object:self userInfo:userInfo];
    });
}

- (void)postUpdateNotificationForTransaction:(FLEXNetworkTransaction *)transaction
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{ kFLEXNetworkRecorderUserInfoTransactionKey : transaction };
        [[NSNotificationCenter defaultCenter] postNotificationName:kFLEXNetworkRecorderTransactionUpdatedNotification object:self userInfo:userInfo];
    });
}

@end
