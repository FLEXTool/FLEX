//
//  FLEXNetworkRecorder.m
//  Flipboard
//
//  Created by Ryan Olson on 2/4/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkCurlLogger.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"
#import "NSUserDefaults+FLEX.h"
#import "OSCache.h"

NSString *const kFLEXNetworkRecorderNewTransactionNotification = @"kFLEXNetworkRecorderNewTransactionNotification";
NSString *const kFLEXNetworkRecorderTransactionUpdatedNotification = @"kFLEXNetworkRecorderTransactionUpdatedNotification";
NSString *const kFLEXNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kFLEXNetworkRecorderTransactionsClearedNotification = @"kFLEXNetworkRecorderTransactionsClearedNotification";

NSString *const kFLEXNetworkRecorderResponseCacheLimitDefaultsKey = @"com.flex.responseCacheLimit";

@interface FLEXNetworkRecorder ()

@property (nonatomic) OSCache *restCache;
@property (nonatomic) NSMutableArray<FLEXHTTPTransaction *> *orderedHTTPTransactions;
@property (nonatomic) NSMutableArray<FLEXWebsocketTransaction *> *orderedWSTransactions;
@property (nonatomic) NSMutableDictionary<NSString *, FLEXHTTPTransaction *> *requestIDsToHTTPTransactions;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation FLEXNetworkRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.restCache = [OSCache new];
        NSUInteger responseCacheLimit = [[NSUserDefaults.standardUserDefaults
            objectForKey:kFLEXNetworkRecorderResponseCacheLimitDefaultsKey] unsignedIntegerValue
        ];
        
        // Default to 25 MB max. The cache will purge earlier if there is memory pressure.
        self.restCache.totalCostLimit = responseCacheLimit ?: 25 * 1024 * 1024;
        [self.restCache setTotalCostLimit:responseCacheLimit];
        
        self.orderedWSTransactions = [NSMutableArray new];
        self.orderedHTTPTransactions = [NSMutableArray new];
        self.requestIDsToHTTPTransactions = [NSMutableDictionary new];
        self.hostDenylist = NSUserDefaults.standardUserDefaults.flex_networkHostDenylist.mutableCopy;

        // Serial queue used because we use mutable objects that are not thread safe
        self.queue = dispatch_queue_create("com.flex.FLEXNetworkRecorder", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)defaultRecorder {
    static FLEXNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [self new];
    });
    
    return defaultRecorder;
}

#pragma mark - Public Data Access

- (NSUInteger)responseCacheByteLimit {
    return self.restCache.totalCostLimit;
}

- (void)setResponseCacheByteLimit:(NSUInteger)responseCacheByteLimit {
    self.restCache.totalCostLimit = responseCacheByteLimit;
    [NSUserDefaults.standardUserDefaults
        setObject:@(responseCacheByteLimit)
        forKey:kFLEXNetworkRecorderResponseCacheLimitDefaultsKey
    ];
}

- (NSArray<FLEXHTTPTransaction *> *)HTTPTransactions {
    return self.orderedHTTPTransactions.copy;
}

- (NSArray<FLEXWebsocketTransaction *> *)websocketTransactions {
    return self.orderedWSTransactions.copy;
}

- (NSData *)cachedResponseBodyForTransaction:(FLEXHTTPTransaction *)transaction {
    return [self.restCache objectForKey:transaction.requestID];
}

- (void)clearRecordedActivity {
    dispatch_async(self.queue, ^{
        [self.restCache removeAllObjects];
        [self.orderedWSTransactions removeAllObjects];
        [self.orderedHTTPTransactions removeAllObjects];
        [self.requestIDsToHTTPTransactions removeAllObjects];
        
        [self notify:kFLEXNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearExcludedTransactions {
    dispatch_sync(self.queue, ^{
        self.orderedHTTPTransactions = ({
            [self.orderedHTTPTransactions flex_filtered:^BOOL(FLEXHTTPTransaction *ta, NSUInteger idx) {
                NSString *host = ta.request.URL.host;
                for (NSString *excluded in self.hostDenylist) {
                    if ([host hasSuffix:excluded]) {
                        return NO;
                    }
                }
                
                return YES;
            }];
        });
    });
}

- (void)synchronizeDenylist {
    NSUserDefaults.standardUserDefaults.flex_networkHostDenylist = self.hostDenylist;
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse {
    for (NSString *host in self.hostDenylist) {
        if ([request.URL.host hasSuffix:host]) {
            return;
        }
    }
    
    FLEXHTTPTransaction *transaction = [FLEXHTTPTransaction request:request identifier:requestID];

    // Before async block to keep times accurate
    if (redirectResponse) {
        [self recordResponseReceivedWithRequestID:requestID response:redirectResponse];
        [self recordLoadingFinishedWithRequestID:requestID responseBody:nil];
    }

    dispatch_async(self.queue, ^{
        [self.orderedHTTPTransactions insertObject:transaction atIndex:0];
        [self.requestIDsToHTTPTransactions setObject:transaction forKey:requestID];
        transaction.transactionState = FLEXNetworkTransactionStateAwaitingResponse;

        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    // Before async block to stay accurate
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToHTTPTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.response = response;
        transaction.transactionState = FLEXNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToHTTPTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.receivedDataLength += dataLength;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody {
    NSDate *finishedDate = [NSDate date];

    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToHTTPTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = FLEXNetworkTransactionStateFinished;
        transaction.duration = -[transaction.startTime timeIntervalSinceDate:finishedDate];

        BOOL shouldCache = responseBody.length > 0;
        if (!self.shouldCacheMediaResponses) {
            NSArray<NSString *> *ignoredMIMETypePrefixes = @[ @"audio", @"image", @"video" ];
            for (NSString *ignoredPrefix in ignoredMIMETypePrefixes) {
                shouldCache = shouldCache && ![transaction.response.MIMEType hasPrefix:ignoredPrefix];
            }
        }
        
        if (shouldCache) {
            [self.restCache setObject:responseBody forKey:requestID cost:responseBody.length];
        }

        NSString *mimeType = transaction.response.MIMEType;
        if ([mimeType hasPrefix:@"image/"] && responseBody.length > 0) {
            // Thumbnail image previews on a separate background queue
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSInteger maxPixelDimension = UIScreen.mainScreen.scale * 32.0;
                transaction.thumbnail = [FLEXUtility
                    thumbnailedImageWithMaxPixelDimension:maxPixelDimension
                    fromImageData:responseBody
                ];
                [self postUpdateNotificationForTransaction:transaction];
            });
        } else if ([mimeType isEqual:@"application/json"]) {
            transaction.thumbnail = FLEXResources.jsonIcon;
        } else if ([mimeType isEqual:@"text/plain"]){
            transaction.thumbnail = FLEXResources.textPlainIcon;
        } else if ([mimeType isEqual:@"text/html"]) {
            transaction.thumbnail = FLEXResources.htmlIcon;
        } else if ([mimeType isEqual:@"application/x-plist"]) {
            transaction.thumbnail = FLEXResources.plistIcon;
        } else if ([mimeType isEqual:@"application/octet-stream"] || [mimeType isEqual:@"application/binary"]) {
            transaction.thumbnail = FLEXResources.binaryIcon;
        } else if ([mimeType containsString:@"javascript"]) {
            transaction.thumbnail = FLEXResources.jsIcon;
        } else if ([mimeType containsString:@"xml"]) {
            transaction.thumbnail = FLEXResources.xmlIcon;
        } else if ([mimeType hasPrefix:@"audio"]) {
            transaction.thumbnail = FLEXResources.audioIcon;
        } else if ([mimeType hasPrefix:@"video"]) {
            transaction.thumbnail = FLEXResources.videoIcon;
        } else if ([mimeType hasPrefix:@"text"]) {
            transaction.thumbnail = FLEXResources.textIcon;
        }
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error {
    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToHTTPTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.transactionState = FLEXNetworkTransactionStateFailed;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToHTTPTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.requestMechanism = mechanism;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark - Websocket Events

- (void)recordWebsocketMessageSend:(NSURLSessionWebSocketMessage *)message task:(NSURLSessionWebSocketTask *)task {
    dispatch_async(self.queue, ^{
        FLEXWebsocketTransaction *send = [FLEXWebsocketTransaction
            withMessage:message task:task direction:FLEXWebsocketOutgoing
        ];
        
        [self.orderedWSTransactions addObject:send];
        [self postNewTransactionNotificationWithTransaction:send];
    });
}

- (void)recordWebsocketMessageSendCompletion:(NSURLSessionWebSocketMessage *)message error:(NSError *)error {
    dispatch_async(self.queue, ^{
        FLEXWebsocketTransaction *send = [self.orderedWSTransactions flex_firstWhere:^BOOL(FLEXWebsocketTransaction *t) {
            return t.message == message;
        }];
        send.error = error;
        send.transactionState = error ? FLEXNetworkTransactionStateFailed : FLEXNetworkTransactionStateFinished;
        
        [self postUpdateNotificationForTransaction:send];
    });
}

- (void)recordWebsocketMessageReceived:(NSURLSessionWebSocketMessage *)message task:(NSURLSessionWebSocketTask *)task {
    dispatch_async(self.queue, ^{
        FLEXWebsocketTransaction *receive = [FLEXWebsocketTransaction
            withMessage:message task:task direction:FLEXWebsocketIncoming
        ];
        
        [self.orderedWSTransactions addObject:receive];
        [self postNewTransactionNotificationWithTransaction:receive];
    });
}

#pragma mark Notification Posting

- (void)postNewTransactionNotificationWithTransaction:(FLEXNetworkTransaction *)transaction {
    [self notify:kFLEXNetworkRecorderNewTransactionNotification transaction:transaction];
}

- (void)postUpdateNotificationForTransaction:(FLEXNetworkTransaction *)transaction {
    [self notify:kFLEXNetworkRecorderTransactionUpdatedNotification transaction:transaction];
}

- (void)notify:(NSString *)name transaction:(FLEXNetworkTransaction *)transaction {
    NSDictionary *userInfo = nil;
    if (transaction) {
        userInfo = @{ kFLEXNetworkRecorderUserInfoTransactionKey : transaction };
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self userInfo:userInfo];
    });
}

@end
