//
//  FLEXNetworkRequest.m
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXNetworkRequest.h"

@implementation FLEXNetworkRequest

- (id)initWithURLRequest:(NSURLRequest *)request
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.url = [request.URL absoluteString];
    self.method = request.HTTPMethod;
    self.headers = request.allHTTPHeaderFields;
    
    
    NSData *body = request.HTTPBody;
    
    self.postData = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    
    return self;
}

+ (FLEXNetworkRequest *)networkRequestWithURLRequest:(NSURLRequest *)request;
{
    return [[[self class] alloc] initWithURLRequest:request];
}

@end
