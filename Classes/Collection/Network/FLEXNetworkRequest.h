//
//  FLEXNetworkRequest.h
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "JSONModel.h"

@interface FLEXNetworkRequest : JSONModel

// Request URL.
// Type: string
@property (nonatomic, strong) NSString *url;

// HTTP request method.
// Type: string
@property (nonatomic, strong) NSString *method;

// HTTP request headers.
@property (nonatomic, strong) NSDictionary *headers;

// HTTP POST request data.
// Type: string
@property (nonatomic, strong) NSString *postData;

- (id)initWithURLRequest:(NSURLRequest *)request;
+ (FLEXNetworkRequest *)networkRequestWithURLRequest:(NSURLRequest *)request;

@end