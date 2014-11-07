//
//  FLEXNetworkResponse.m
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXNetworkResponse.h"

@implementation FLEXNetworkResponse

- (id)initWithURLResponse:(NSURLResponse *)response request:(NSURLRequest *)request
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.url = [response.URL absoluteString];
    
    // Set statusText if this was a HTTP Response
    self.statusText = @"";
    
    self.mimeType = response.MIMEType;
    self.requestHeaders = request.allHTTPHeaderFields;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        self.status = [NSNumber numberWithInteger:httpResponse.statusCode];
        self.statusText = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
        self.headers = httpResponse.allHeaderFields;
    }
    
    return self;
}

+ (FLEXNetworkResponse *)networkResponseWithURLResponse:(NSURLResponse *)response request:(NSURLRequest *)request;
{
    return [[[self class] alloc] initWithURLResponse:response request:request];
}

@end
