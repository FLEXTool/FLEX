//
//  FLEXNetworkTransaction.h
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

typedef NS_ENUM(NSInteger, FLEXNetworkTransactionState) {
    FLEXNetworkTransactionStateUnstarted,
    FLEXNetworkTransactionStateAwaitingResponse,
    FLEXNetworkTransactionStateReceivingData,
    FLEXNetworkTransactionStateFinished,
    FLEXNetworkTransactionStateFailed
};

@interface FLEXNetworkTransaction : NSObject

@property (nonatomic, copy) NSString *requestID;

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, copy) NSString *requestMechanism;
@property (nonatomic, assign) FLEXNetworkTransactionState transactionState;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSTimeInterval latency;
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, assign) int64_t receivedDataLength;

/// Only applicable for image downloads. A small thumbnail to preview the full response.
@property (nonatomic, strong) UIImage *responseThumbnail;

/// Populated lazily. Handles both normal HTTPBody data and HTTPBodyStreams.
@property (nonatomic, strong, readonly) NSData *cachedRequestBody;

+ (NSString *)readableStringFromTransactionState:(FLEXNetworkTransactionState)state;

@end
