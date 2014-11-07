//
//  FLEXNetworkResponse.h
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "JSONModel.h"

#import "FLEXNetworkResourceTiming.h"

@interface FLEXNetworkResponse : JSONModel

// Response URL.
// Type: string
@property (nonatomic, strong) NSString *url;

// HTTP response status code.
// Type: number
@property (nonatomic, strong) NSNumber *status;

// HTTP response status text.
// Type: string
@property (nonatomic, strong) NSString *statusText;

// HTTP response headers.
@property (nonatomic, strong) NSDictionary *headers;

// HTTP response headers text.
// Type: string
@property (nonatomic, strong) NSString *headersText;

// Resource mimeType as determined by the browser.
// Type: string
@property (nonatomic, strong) NSString *mimeType;

// Refined HTTP request headers that were actually transmitted over the network.
@property (nonatomic, strong) NSDictionary *requestHeaders;

// HTTP request headers text.
// Type: string
@property (nonatomic, strong) NSString *requestHeadersText;

// Specifies whether physical connection was actually reused for this request.
// Type: boolean
@property (nonatomic, strong) NSNumber *connectionReused;

// Physical connection id that was actually used for this request.
// Type: number
@property (nonatomic, strong) NSNumber *connectionId;

// Specifies that the request was served from the disk cache.
// Type: boolean
@property (nonatomic, strong) NSNumber *fromDiskCache;

- (id)initWithURLResponse:(NSURLResponse *)response request:(NSURLRequest *)request;
+ (FLEXNetworkResponse *)networkResponseWithURLResponse:(NSURLResponse *)response request:(NSURLRequest *)request;

@end
