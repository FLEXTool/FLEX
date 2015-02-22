//
//  FLEXNetworkRecorder.h
//  Flipboard
//
//  Created by Ryan Olson on 2/4/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

// Notifications posted when the record is updated
extern NSString *const kFLEXNetworkRecorderNewTransactionNotification;
extern NSString *const kFLEXNetworkRecorderTransactionUpdatedNotification;
extern NSString *const kFLEXNetworkRecorderUserInfoTransactionKey;
extern NSString *const kFLEXNetworkRecorderTransactionsClearedNotification;

@class FLEXNetworkTransaction;

@interface FLEXNetworkRecorder : NSObject

/// In general, it only makes sense to have one recorder for the entire application.
+ (instancetype)defaultRecorder;

/// Defaults to 25 MB if never set. Values set here are presisted across launches of the app.
@property (nonatomic, assign) NSUInteger responseCacheByteLimit;

/// If NO, the recorder not cache will not cache response for content types with an "image", "video", or "audio" prefix.
@property (nonatomic, assign) BOOL shouldCacheMediaResponses;

// Accessing recorded network activity

/// Array of FLEXNetworkTransaction objects ordered by start time with the newest first.
- (NSArray *)networkTransactions;

/// The full response data IFF it hasn't been purged due to memory pressure.
- (NSData *)cachedResponseBodyForTransaction:(FLEXNetworkTransaction *)transaction;

/// Dumps all network transactions and cached response bodies.
- (void)clearRecordedActivity;


// Recording network activity

/// Call when app is about to send HTTP request.
/// This method must be called for each recorded reqeust. Prior to this call, no information will be recorded for the request.
- (void)recordRequestWillBeSentWithRequestId:(NSString *)requestId request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse requestMechanism:(NSString *)mechanism;

/// Call when HTTP response is available.
- (void)recordResponseReceivedWithRequestId:(NSString *)requestId request:(NSURLRequest *)request response:(NSURLResponse *)response;

/// Call when data chunk is received over the network.
- (void)recordDataReceivedWithRequestId:(NSString *)requestId request:(NSURLRequest *)request dataLength:(int64_t)dataLength;

/// Call when HTTP request has finished loading.
- (void)recordLoadingFinishedWithRequestId:(NSString *)requestId request:(NSURLRequest *)request responseBody:(NSData *)responseBody;

/// Call when HTTP request has failed to load.
- (void)recordLoadingFailedWithRequestId:(NSString *)requestId request:(NSURLRequest *)request error:(NSError *)error;

@end
