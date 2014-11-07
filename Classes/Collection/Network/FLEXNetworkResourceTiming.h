//
//  FLEXNetworkResourceTiming.h
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "JSONModel.h"

@interface FLEXNetworkResourceTiming : JSONModel

// Timing's requestTime is a baseline in seconds, while the other numbers are ticks in milliseconds relatively to this requestTime.
// Type: number
@property (nonatomic, strong) NSNumber *requestTime;

// Started resolving proxy.
// Type: number
@property (nonatomic, strong) NSNumber *proxyStart;

// Finished resolving proxy.
// Type: number
@property (nonatomic, strong) NSNumber *proxyEnd;

// Started DNS address resolve.
// Type: number
@property (nonatomic, strong) NSNumber *dnsStart;

// Finished DNS address resolve.
// Type: number
@property (nonatomic, strong) NSNumber *dnsEnd;

// Started connecting to the remote host.
// Type: number
@property (nonatomic, strong) NSNumber *connectStart;

// Connected to the remote host.
// Type: number
@property (nonatomic, strong) NSNumber *connectEnd;

// Started SSL handshake.
// Type: number
@property (nonatomic, strong) NSNumber *sslStart;

// Finished SSL handshake.
// Type: number
@property (nonatomic, strong) NSNumber *sslEnd;

// Started sending request.
// Type: number
@property (nonatomic, strong) NSNumber *sendStart;

// Finished sending request.
// Type: number
@property (nonatomic, strong) NSNumber *sendEnd;

// Finished receiving response headers.
// Type: number
@property (nonatomic, strong) NSNumber *receiveHeadersEnd;

@end
