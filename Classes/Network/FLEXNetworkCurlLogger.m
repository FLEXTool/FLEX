//
// FLEXCurlLogger.m
//
//
// Created by Ji Pei on 07/27/16
//

#import "FLEXNetworkCurlLogger.h"
#import "FLEXUtility.h"

@implementation FLEXNetworkCurlLogger

+ (NSString *)curlCommandString:(NSURLRequest *)request {
    __block NSMutableString *curlCommandString = [NSMutableString stringWithFormat:@"curl -v -X %@ ", request.HTTPMethod];

    [curlCommandString appendFormat:@"\'%@\' ", request.URL.absoluteString];

    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        [curlCommandString appendFormat:@"-H \'%@: %@\' ", key, val];
    }];

    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:request.URL];
    if (cookies) {
        [curlCommandString appendFormat:@"-H \'Cookie:"];
        for (NSHTTPCookie *cookie in cookies) {
            [curlCommandString appendFormat:@" %@=%@;", cookie.name, cookie.value];
        }
        [curlCommandString appendFormat:@"\' "];
    }

    if (request.HTTPBody) {
        NSData *bodyData = request.HTTPBody;
        if ([FLEXUtility hasCompressedContentEncoding:request]) {
            bodyData = [FLEXUtility inflatedDataFromCompressedData:bodyData];
        }
        NSString *body = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        [curlCommandString appendFormat:@"-d \'%@\'", body];
    }

    return curlCommandString;
}

@end
