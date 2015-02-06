//
//  FLEXNetworkRecorder.m
//  Flipboard
//
//  Created by Ryan Olson on 2/4/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"

@interface FLEXNetworkRecorder ()

@property (nonatomic, strong) NSCache *responseCache;
@property (nonatomic, strong) NSMutableArray *orderedTransactions;
@property (nonatomic, strong) NSMutableDictionary *networkTransactionsForRequestIdentifiers;

@end

@implementation FLEXNetworkRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseCache = [[NSCache alloc] init];
        self.orderedTransactions = [NSMutableArray array];
        self.networkTransactionsForRequestIdentifiers = [NSMutableDictionary dictionary];
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
    return [self.orderedTransactions copy];
}

- (NSData *)cachedResponseBodyForTransaction:(FLEXNetworkTransaction *)transaction
{
    return [self.responseCache objectForKey:transaction.requestId];
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestId:(NSString *)requestId request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    // FIXME (RKO): What to do with the redirect response?

    FLEXNetworkTransaction *transaction = [[FLEXNetworkTransaction alloc] init];
    transaction.requestId = requestId;
    transaction.request = request;
    transaction.startTime = [NSDate date];
    transaction.transactionState = FLEXNetworkTransactionStateAwaitingResponse;

    [self.orderedTransactions addObject:transaction];
    [self.networkTransactionsForRequestIdentifiers setObject:transaction forKey:requestId];
}

- (void)recordResponseReceivedWithRequestId:(NSString *)requestId response:(NSURLResponse *)response
{
    FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
    transaction.response = response;
    transaction.transactionState = FLEXNetworkTransactionStateReceivingData;
    transaction.latency = -[transaction.startTime timeIntervalSinceNow];
}

- (void)recordDataReceivedWithRequestId:(NSString *)requestId dataLength:(int64_t)dataLength
{
    FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
    transaction.receivedDataLength += dataLength;
}

- (void)recordLoadingFinishedWithRequestId:(NSString *)requestId responseBody:(NSData *)responseBody
{
    FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
    transaction.transactionState = FLEXNetworkTransactionStateFinished;
    transaction.duration = -[transaction.startTime timeIntervalSinceNow];

    [self.responseCache setObject:responseBody forKey:requestId cost:[responseBody length]];
}

- (void)recordLoadingFailedWithRequestId:(NSString *)requestId error:(NSError *)error
{
    FLEXNetworkTransaction *transaction = [self.networkTransactionsForRequestIdentifiers objectForKey:requestId];
    transaction.transactionState = FLEXNetworkTransactionStateFailed;
    transaction.duration = [transaction.startTime timeIntervalSinceNow];
    transaction.error = error;
}

@end
