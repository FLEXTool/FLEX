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
@property (atomic) NSMutableArray<FLEXHTTPTransaction *> *orderedHTTPTransactions;
@property (atomic) NSMutableArray<FLEXWebsocketTransaction *> *orderedWSTransactions;
@property (atomic) NSMutableArray<FLEXFirebaseTransaction *> *orderedFirebaseTransactions;
@property (atomic) NSMutableDictionary<NSString *, __kindof FLEXNetworkTransaction *> *requestIDsToTransactions;
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
        self.orderedFirebaseTransactions = [NSMutableArray new];
        self.requestIDsToTransactions = [NSMutableDictionary new];
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

- (NSArray<FLEXFirebaseTransaction *> *)firebaseTransactions {
    return self.orderedFirebaseTransactions.copy;
}

- (NSData *)cachedResponseBodyForTransaction:(FLEXHTTPTransaction *)transaction {
    return [self.restCache objectForKey:transaction.requestID];
}

- (void)clearRecordedActivity {
    dispatch_async(self.queue, ^{
        [self.restCache removeAllObjects];
        [self.orderedWSTransactions removeAllObjects];
        [self.orderedHTTPTransactions removeAllObjects];
        [self.orderedFirebaseTransactions removeAllObjects];
        [self.requestIDsToTransactions removeAllObjects];
        
        [self notify:kFLEXNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearRecordedActivity:(FLEXNetworkTransactionKind)kind matching:(NSString *)query {
    dispatch_async(self.queue, ^{
        switch (kind) {
            case FLEXNetworkTransactionKindFirebase: {
                [self.orderedFirebaseTransactions flex_filter:^BOOL(FLEXFirebaseTransaction *obj, NSUInteger idx) {
                    return ![obj matchesQuery:query];
                }];
                break;
            }
            case FLEXNetworkTransactionKindREST: {
                NSArray<FLEXHTTPTransaction *> *toRemove;
                toRemove = [self.orderedHTTPTransactions flex_filtered:^BOOL(FLEXHTTPTransaction *obj, NSUInteger idx) {
                    return [obj matchesQuery:query];
                }];
                
                // Remove from cache
                for (FLEXHTTPTransaction *t in toRemove) {
                    [self.restCache removeObjectForKey:t.requestID];
                }
                
                // Remove from list
                [self.orderedHTTPTransactions removeObjectsInArray:toRemove];
                
                break;
            }
            case FLEXNetworkTransactionKindWebsockets: {
                [self.orderedWSTransactions flex_filter:^BOOL(FLEXWebsocketTransaction *obj, NSUInteger idx) {
                    return ![obj matchesQuery:query];
                }];
                break;
            }
        }
        
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

    // A redirect is always a new request
    dispatch_async(self.queue, ^{
        [self.orderedHTTPTransactions insertObject:transaction atIndex:0];
        self.requestIDsToTransactions[requestID] = transaction;

        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    // Before async block to stay accurate
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.response = response;
        transaction.state = FLEXNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
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
        FLEXHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.state = FLEXNetworkTransactionStateFinished;
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
        FLEXHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.state = FLEXNetworkTransactionStateFailed;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        FLEXHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
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
        
        [self.orderedWSTransactions insertObject:send atIndex:0];
        [self postNewTransactionNotificationWithTransaction:send];
    });
}

- (void)recordWebsocketMessageSendCompletion:(NSURLSessionWebSocketMessage *)message error:(NSError *)error {
    dispatch_async(self.queue, ^{
        FLEXWebsocketTransaction *send = [self.orderedWSTransactions flex_firstWhere:^BOOL(FLEXWebsocketTransaction *t) {
            return t.message == message;
        }];
        send.error = error;
        send.state = error ? FLEXNetworkTransactionStateFailed : FLEXNetworkTransactionStateFinished;
        
        [self postUpdateNotificationForTransaction:send];
    });
}

- (void)recordWebsocketMessageReceived:(NSURLSessionWebSocketMessage *)message task:(NSURLSessionWebSocketTask *)task {
    dispatch_async(self.queue, ^{
        FLEXWebsocketTransaction *receive = [FLEXWebsocketTransaction
            withMessage:message task:task direction:FLEXWebsocketIncoming
        ];
        
        [self.orderedWSTransactions insertObject:receive atIndex:0];
        [self postNewTransactionNotificationWithTransaction:receive];
    });
}

#pragma mark - Firebase, Reading

- (void)recordFIRQueryWillFetch:(FIRQuery *)query withTransactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction queryFetch:query];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRDocumentWillFetch:(FIRDocumentReference *)document withTransactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction documentFetch:document];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRQueryDidFetch:(FIRQuerySnapshot *)response error:(NSError *)error transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.documents = response.documents;
        transaction.state = FLEXNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordFIRDocumentDidFetch:(FIRDocumentSnapshot *)response error:(NSError *)error transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.documents = response ? @[response] : @[];
        transaction.state = FLEXNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark Firebase, Writing

- (void)recordFIRWillSetData:(FIRDocumentReference *)doc
                        data:(NSDictionary *)documentData
                       merge:(NSNumber *)yesorno
                 mergeFields:(NSArray *)fields
               transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction
            setData:doc data:documentData merge:yesorno mergeFields:fields
        ];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillUpdateData:(FIRDocumentReference *)doc fields:(NSDictionary *)fields
                  transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction updateData:doc data:fields];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillDeleteDocument:(FIRDocumentReference *)doc transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction deleteDocument:doc];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillAddDocument:(FIRCollectionReference *)initiator document:(FIRDocumentReference *)doc
                   transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = [FLEXFirebaseTransaction
            addDocument:initiator document:doc
        ];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRDidSetData:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidUpdateData:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidDeleteDocument:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidAddDocument:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)firebaseTransaction:(NSString *)transactionID didUpdate:(NSError *)error {
    dispatch_async(self.queue, ^{
        FLEXFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.state = FLEXNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark - Notification Posting

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
