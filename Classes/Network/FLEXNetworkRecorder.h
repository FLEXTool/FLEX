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

@class FLEXNetworkTransaction;

@interface FLEXNetworkRecorder : NSObject

/// In general, it only makes sense to have one recorder for the entire application.
+ (instancetype)defaultRecorder;

/// Defaults to 50 MB if never set. Values set here are presisted across launches of the app.
@property (nonatomic, assign) NSUInteger responseCacheByteLimit;

// Accessing recorded network activity

/// Array of FLEXNetworkTransaction objects ordered by start time with the newest first.
- (NSArray *)networkTransactions;

/// The full response data IFF it hasn't been purged due to memory pressure.
- (NSData *)cachedResponseBodyForTransaction:(FLEXNetworkTransaction *)transaction;


// Recording network activity

/// Call when app is about to send HTTP request.
- (void)recordRequestWillBeSentWithRequestId:(NSString *)requestId request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;

/// Call when HTTP response is available.
- (void)recordResponseReceivedWithRequestId:(NSString *)requestId response:(NSURLResponse *)response;

/// Call when data chunk is received over the network.
- (void)recordDataReceivedWithRequestId:(NSString *)requestId dataLength:(int64_t)dataLength;

/// Call when HTTP request has finished loading.
- (void)recordLoadingFinishedWithRequestId:(NSString *)requestId responseBody:(NSData *)responseBody;

/// Call when HTTP request has failed to load.
- (void)recordLoadingFailedWithRequestId:(NSString *)requestId error:(NSError *)error;

@end
