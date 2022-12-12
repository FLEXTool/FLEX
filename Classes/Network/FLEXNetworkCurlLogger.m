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
        
        if (body != nil) {
            [curlCommandString appendFormat:@"-d \'%@\'", body];
        } else {
            // Fallback to using base64 encoding
            [curlCommandString appendString:@"--data-binary @-"];

            NSString *base64 = [request.HTTPBody base64EncodedStringWithOptions:0];
            NSString *prefix = [NSString stringWithFormat:@"echo -n '%@' | base64 -D | ", base64];
            [curlCommandString insertString:prefix atIndex:0];
        }
    }

    return curlCommandString;
}

@end
