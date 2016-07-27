//
// FLEXCurlLogger.h
// Instagram
//
// Created by Ji Pei on 07/27/16
// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@interface FLEXNetworkCurlLogger : NSObject

/**
 * Generates a cURL command equivalent to the given request.
 *
 * @param request The request to be translated
 */
+ (NSString *)curlCommandString:(NSURLRequest *)request;

@end
