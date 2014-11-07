//
//  FLEXNetworkConnection.m
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXNetworkConnection.h"

@implementation FLEXNetworkConnection

- (void)updateWithRequest:(FLEXNetworkRequest *)request withResponse:(FLEXNetworkResponse *)response
{
    if (request)
    {
        self.request = request;
    }
    
    if (response)
    {
        self.response = response;
    }
}

@end
