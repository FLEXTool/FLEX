//
//  FLEXNetworkTransaction.h
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
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

@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSURLResponse *response;
@property (nonatomic, copy) NSString *requestMechanism;
@property (nonatomic) FLEXNetworkTransactionState transactionState;
@property (nonatomic) NSError *error;

@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSTimeInterval latency;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) int64_t receivedDataLength;

/// Only applicable for image downloads. A small thumbnail to preview the full response.
@property (nonatomic) UIImage *responseThumbnail;

/// Populated lazily. Handles both normal HTTPBody data and HTTPBodyStreams.
@property (nonatomic, readonly) NSData *cachedRequestBody;

+ (NSString *)readableStringFromTransactionState:(FLEXNetworkTransactionState)state;

@end
