//
//  FLEXNetworkExporter.m
//  FLEX
//
//  Created by Enes OZTURK on 4/1/26.
//

#import "FLEXNetworkExporter.h"
#import "FLEXNetworkCurlLogger.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import "NSDateFormatter+FLEX.h"
#import "NSUserDefaults+FLEX.h"

@implementation FLEXNetworkExporter

#pragma mark - Single Transaction Export

+ (NSString *)requestStringForTransaction:(FLEXHTTPTransaction *)transaction
{
    NSMutableString *output = [NSMutableString new];

    NSURLRequest *request = transaction.request;

    // Request Line
    [output appendFormat:@"%@ %@ HTTP/1.1\n", request.HTTPMethod ?: @"GET", request.URL.absoluteString];

    // Headers
    [output appendString:@"\n--- Request Headers ---\n"];
    NSDictionary *headers = request.allHTTPHeaderFields;
    for (NSString *key in [headers.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
        [output appendFormat:@"%@: %@\n", key, headers[key]];
    }

    // Body
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0) {
        [output appendString:@"\n--- Request Body ---\n"];
        NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if (bodyString) {
            // Try to pretty print JSON
            if ([FLEXUtility isValidJSONData:bodyData]) {
                NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:bodyData];
                [output appendString:prettyJSON ?: bodyString];
            } else {
                [output appendString:bodyString];
            }
        } else {
            [output appendFormat:@"[Binary data: %@ bytes]", @(bodyData.length)];
        }
        [output appendString:@"\n"];
    }

    return output;
}

+ (NSString *)responseStringForTransaction:(FLEXHTTPTransaction *)transaction
{
    NSMutableString *output = [NSMutableString new];

    NSHTTPURLResponse *response = (NSHTTPURLResponse *)transaction.response;

    // Status Line
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        [output appendFormat:@"HTTP/1.1 %ld %@\n",
            (long)response.statusCode,
            [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];

        // Response Headers
        [output appendString:@"\n--- Response Headers ---\n"];
        NSDictionary *headers = response.allHeaderFields;
        for (NSString *key in [headers.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
            [output appendFormat:@"%@: %@\n", key, headers[key]];
        }
    }

    // Response Body
    NSData *responseData = [FLEXNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        [output appendString:@"\n--- Response Body ---\n"];
        NSString *bodyString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if (bodyString) {
            // Try to pretty print JSON
            if ([FLEXUtility isValidJSONData:responseData]) {
                NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:responseData];
                [output appendString:prettyJSON ?: bodyString];
            } else {
                [output appendString:bodyString];
            }
        } else {
            [output appendFormat:@"[Binary data: %@ bytes]", @(responseData.length)];
        }
        [output appendString:@"\n"];
    } else if (transaction.receivedDataLength > 0) {
        [output appendString:@"\n--- Response Body ---\n"];
        [output appendFormat:@"[Response not in cache: %lld bytes received]", transaction.receivedDataLength];
        [output appendString:@"\n"];
    }

    // Error if any
    if (transaction.error) {
        [output appendString:@"\n--- Error ---\n"];
        [output appendFormat:@"%@\n", transaction.error.localizedDescription];
    }

    return output;
}

+ (NSString *)rawStringForTransaction:(FLEXHTTPTransaction *)transaction
{
    NSMutableString *output = [NSMutableString new];

    // Metadata
    [output appendString:@"================================================================================\n"];
    [output appendFormat:@"URL: %@\n", transaction.request.URL.absoluteString];
    [output appendFormat:@"Start Time: %@\n", [NSDateFormatter flex_stringFrom:transaction.startTime format:FLEXDateFormatVerbose]];
    [output appendFormat:@"Duration: %.3f ms\n", transaction.duration * 1000];
    [output appendFormat:@"Latency: %.3f ms\n", transaction.latency * 1000];
    [output appendString:@"================================================================================\n\n"];

    // Request
    [output appendString:@">>> REQUEST >>>\n\n"];
    [output appendString:[self requestStringForTransaction:transaction]];

    // Response
    [output appendString:@"\n<<< RESPONSE <<<\n\n"];
    [output appendString:[self responseStringForTransaction:transaction]];

    return output;
}

+ (NSDictionary *)harEntryForTransaction:(FLEXHTTPTransaction *)transaction
{
    NSURLRequest *request = transaction.request;
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)transaction.response;

    // Format the start time as ISO 8601
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    isoFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSString *startedDateTime = [isoFormatter stringFromDate:transaction.startTime] ?: @"";

    // Build request headers array
    NSMutableArray *requestHeaders = [NSMutableArray new];
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [requestHeaders addObject:@ {@"name" : key, @"value" : value}];
    }];

    // Build query string array
    NSMutableArray *queryString = [NSMutableArray new];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in urlComponents.queryItems) {
        [queryString addObject:@{@"name" : item.name ?: @"", @"value" : item.value ?: @""}];
    }

    // Build post data if present
    NSMutableDictionary *postData = nil;
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0) {
        postData = [NSMutableDictionary new];
        NSString *mimeType = [request valueForHTTPHeaderField:@"Content-Type"] ?: @"application/octet-stream";
        postData[@"mimeType"] = mimeType;

        NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if (bodyString) {
            postData[@"text"] = bodyString;
        } else {
            postData[@"text"] = [bodyData base64EncodedStringWithOptions:0];
            postData[@"encoding"] = @"base64";
        }
    }

    // Build response headers array
    NSMutableArray *responseHeaders = [NSMutableArray new];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        [response.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [responseHeaders addObject:@ {@"name" : key, @"value" : value}];
        }];
    }

    // Build response content
    NSMutableDictionary *content = [NSMutableDictionary new];
    content[@"size"] = @(transaction.receivedDataLength);
    content[@"mimeType"] = response.MIMEType ?: @"application/octet-stream";

    NSData *responseData = [FLEXNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if (responseString) {
            content[@"text"] = responseString;
        } else {
            content[@"text"] = [responseData base64EncodedStringWithOptions:0];
            content[@"encoding"] = @"base64";
        }
    }

    // Build the HAR entry
    NSMutableDictionary *entry = [NSMutableDictionary new];
    entry[@"startedDateTime"] = startedDateTime;
    entry[@"time"] = @(transaction.duration * 1000); // Convert to milliseconds

    // Request object
    NSMutableDictionary *requestObj = [NSMutableDictionary new];
    requestObj[@"method"] = request.HTTPMethod ?: @"GET";
    requestObj[@"url"] = request.URL.absoluteString ?: @"";
    requestObj[@"httpVersion"] = @"HTTP/1.1";
    requestObj[@"cookies"] = @[];
    requestObj[@"headers"] = requestHeaders;
    requestObj[@"queryString"] = queryString;
    requestObj[@"headersSize"] = @(-1);
    requestObj[@"bodySize"] = @(bodyData.length);
    if (postData) {
        requestObj[@"postData"] = postData;
    }
    entry[@"request"] = requestObj;

    // Response object
    NSMutableDictionary *responseObj = [NSMutableDictionary new];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseObj[@"status"] = @(response.statusCode);
        responseObj[@"statusText"] = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
    } else {
        responseObj[@"status"] = @(0);
        responseObj[@"statusText"] = @"";
    }
    responseObj[@"httpVersion"] = @"HTTP/1.1";
    responseObj[@"cookies"] = @[];
    responseObj[@"headers"] = responseHeaders;
    responseObj[@"content"] = content;
    responseObj[@"redirectURL"] = @"";
    responseObj[@"headersSize"] = @(-1);
    responseObj[@"bodySize"] = @(transaction.receivedDataLength);
    entry[@"response"] = responseObj;

    // Timings
    entry[@"timings"] = @{
        @"blocked" : @(-1),
        @"dns" : @(-1),
        @"connect" : @(-1),
        @"send" : @(0),
        @"wait" : @(transaction.latency * 1000),
        @"receive" : @((transaction.duration - transaction.latency) * 1000),
        @"ssl" : @(-1)
    };

    entry[@"cache"] = @{};

    return entry;
}

#pragma mark - Multiple Transactions Export

+ (NSString *)rawStringForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSMutableString *output = [NSMutableString new];

    [output appendFormat:@"FLEX Network Export - %lu requests\n", (unsigned long)transactions.count];
    [output appendFormat:@"Exported at: %@\n", [NSDateFormatter flex_stringFrom:[NSDate date] format:FLEXDateFormatVerbose]];
    [output appendString:@"\n"];

    for (NSUInteger i = 0; i < transactions.count; i++) {
        [output appendFormat:@"\n#%lu of %lu\n", (unsigned long)(i + 1), (unsigned long)transactions.count];
        [output appendString:[self rawStringForTransaction:transactions[i]]];
        [output appendString:@"\n"];
    }

    return output;
}

+ (NSDictionary *)harFileForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSMutableArray *entries = [NSMutableArray new];

    for (FLEXHTTPTransaction *transaction in transactions) {
        [entries addObject:[self harEntryForTransaction:transaction]];
    }

    NSDictionary *harFile = @{
        @"log" : @ {
            @"version" : @"1.2",
            @"creator" : @ {
                @"name" : @"FLEX",
                @"version" : @"5.0"
            },
            @"entries" : entries
        }
    };

    return harFile;
}

+ (NSString *)harJSONStringForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSDictionary *harFile = [self harFileForTransactions:transactions];

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:harFile
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (error || !jsonData) {
        return nil;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Postman Export

+ (NSString *)postmanCollectionForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSMutableArray *items = [NSMutableArray new];

    for (FLEXHTTPTransaction *transaction in transactions) {
        NSURLRequest *request = transaction.request;

        // Build URL object for Postman
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];

        // Query parameters
        NSMutableArray *queryParams = [NSMutableArray new];
        for (NSURLQueryItem *item in urlComponents.queryItems) {
            [queryParams addObject:@{
                @"key" : item.name ?: @"",
                @"value" : item.value ?: @""
            }];
        }

        // Headers
        NSMutableArray *headers = [NSMutableArray new];
        [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [headers addObject:@ {
                @"key" : key,
                @"value" : value
            }];
        }];

        // Build URL object
        NSMutableDictionary *urlObj = [NSMutableDictionary new];
        urlObj[@"raw"] = request.URL.absoluteString ?: @"";
        urlObj[@"protocol"] = urlComponents.scheme ?: @"https";
        urlObj[@"host"] = @[ urlComponents.host ?: @"" ];
        if (urlComponents.path.length > 0) {
            NSArray *pathComponents = [urlComponents.path componentsSeparatedByString:@"/"];
            urlObj[@"path"] = [pathComponents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        }
        if (queryParams.count > 0) {
            urlObj[@"query"] = queryParams;
        }

        // Build request object
        NSMutableDictionary *requestObj = [NSMutableDictionary new];
        requestObj[@"method"] = request.HTTPMethod ?: @"GET";
        requestObj[@"header"] = headers;
        requestObj[@"url"] = urlObj;

        // Body if present
        NSData *bodyData = transaction.cachedRequestBody;
        if (bodyData.length > 0) {
            NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"] ?: @"";
            NSMutableDictionary *body = [NSMutableDictionary new];

            if ([contentType containsString:@"application/json"]) {
                body[@"mode"] = @"raw";
                body[@"raw"] = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] ?: @"";
                body[@"options"] = @{@"raw" : @ {@"language" : @"json"}};
            } else if ([contentType containsString:@"x-www-form-urlencoded"]) {
                body[@"mode"] = @"urlencoded";
                NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
                NSMutableArray *urlencoded = [NSMutableArray new];
                for (NSString *pair in [bodyString componentsSeparatedByString:@"&"]) {
                    NSArray *keyValue = [pair componentsSeparatedByString:@"="];
                    if (keyValue.count >= 2) {
                        [urlencoded addObject:@{
                            @"key" : [keyValue[0] stringByRemovingPercentEncoding] ?: @"",
                            @"value" : [keyValue[1] stringByRemovingPercentEncoding] ?: @""
                        }];
                    }
                }
                body[@"urlencoded"] = urlencoded;
            } else {
                body[@"mode"] = @"raw";
                body[@"raw"] = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] ?: @"";
            }
            requestObj[@"body"] = body;
        }

        // Build item
        NSString *itemName = request.URL.lastPathComponent.length > 0 ? request.URL.lastPathComponent : request.URL.host;
        NSDictionary *item = @{
            @"name" : itemName ?: @"Request",
            @"request" : requestObj,
            @"response" : @[]
        };

        [items addObject:item];
    }

    // Build collection
    NSDictionary *collection = @{
        @"info" : @ {
            @"name" : @"FLEX Network Export",
            @"description" : [NSString stringWithFormat:@"Exported from FLEX on %@", [NSDate date]],
            @"schema" : @"https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        @"item" : items
    };

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:collection
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (error || !jsonData) {
        return nil;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Swagger/OpenAPI Export

+ (NSString *)swaggerSpecForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    // Group transactions by path
    NSMutableDictionary *paths = [NSMutableDictionary new];
    NSMutableSet *servers = [NSMutableSet new];

    for (FLEXHTTPTransaction *transaction in transactions) {
        NSURLRequest *request = transaction.request;
        NSURL *url = request.URL;

        // Collect servers
        NSString *serverURL = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
        if (url.port) {
            serverURL = [serverURL stringByAppendingFormat:@":%@", url.port];
        }
        [servers addObject:serverURL];

        // Get path without query
        NSString *path = url.path.length > 0 ? url.path : @"/";
        NSString *method = [request.HTTPMethod lowercaseString] ?: @"get";

        // Build operation
        NSMutableDictionary *operation = [NSMutableDictionary new];
        operation[@"summary"] = [NSString stringWithFormat:@"%@ %@", request.HTTPMethod, path];
        operation[@"operationId"] = [NSString stringWithFormat:@"%@_%@", method,
            [[path stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]]];

        // Parameters (query string)
        NSMutableArray *parameters = [NSMutableArray new];
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *item in urlComponents.queryItems) {
            [parameters addObject:@{
                @"name" : item.name ?: @"",
                @"in" : @"query",
                @"schema" : @ {@"type" : @"string"},
                @"example" : item.value ?: @""
            }];
        }
        if (parameters.count > 0) {
            operation[@"parameters"] = parameters;
        }

        // Request body
        NSData *bodyData = transaction.cachedRequestBody;
        if (bodyData.length > 0) {
            NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"] ?: @"application/json";
            NSMutableDictionary *requestBody = [NSMutableDictionary new];
            requestBody[@"required"] = @YES;

            NSMutableDictionary *content = [NSMutableDictionary new];
            NSMutableDictionary *mediaType = [NSMutableDictionary new];

            NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
            if (bodyString) {
                // Try to parse as JSON for schema
                NSError *jsonError = nil;
                id jsonObj = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&jsonError];
                if (!jsonError && jsonObj) {
                    mediaType[@"example"] = jsonObj;
                } else {
                    mediaType[@"example"] = bodyString;
                }
            }
            mediaType[@"schema"] = @{@"type" : @"object"};
            content[contentType] = mediaType;
            requestBody[@"content"] = content;
            operation[@"requestBody"] = requestBody;
        }

        // Response
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)transaction.response;
        NSMutableDictionary *responses = [NSMutableDictionary new];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSString *statusCode = [NSString stringWithFormat:@"%ld", (long)response.statusCode];
            responses[statusCode] = @{
                @"description" : [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]
            };
        } else {
            responses[@"200"] = @{@"description" : @"Successful response"};
        }
        operation[@"responses"] = responses;

        // Add to paths
        if (!paths[path]) {
            paths[path] = [NSMutableDictionary new];
        }
        paths[path][method] = operation;
    }

    // Build servers array
    NSMutableArray *serversArray = [NSMutableArray new];
    for (NSString *server in servers) {
        [serversArray addObject:@{@"url" : server}];
    }

    // Build OpenAPI spec
    NSDictionary *spec = @{
        @"openapi" : @"3.0.3",
        @"info" : @ {
            @"title" : @"FLEX Network Export",
            @"description" : @"API documentation generated from FLEX network capture",
            @"version" : @"1.0.0"
        },
        @"servers" : serversArray.count > 0 ? serversArray : @[ @{@"url" : @"https://api.example.com"} ],
        @"paths" : paths
    };

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:spec
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (error || !jsonData) {
        return nil;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Curl ZIP Export

+ (NSURL *)curlZipForTransactions:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd_HHmmss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];

    NSString *tempDir = NSTemporaryDirectory();
    NSString *curlFolderName = [NSString stringWithFormat:@"curl_requests_%@", timestamp];
    NSString *curlFolderPath = [tempDir stringByAppendingPathComponent:curlFolderName];
    NSString *zipPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", curlFolderName]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    // Remove existing folder/zip if exists
    [fileManager removeItemAtPath:curlFolderPath error:nil];
    [fileManager removeItemAtPath:zipPath error:nil];

    // Create folder for curl files
    if (![fileManager createDirectoryAtPath:curlFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"[FLEX] Failed to create curl folder: %@", error.localizedDescription);
        return nil;
    }

    // Generate curl files
    for (NSUInteger i = 0; i < transactions.count; i++) {
        FLEXHTTPTransaction *transaction = transactions[i];
        NSURLRequest *request = transaction.request;

        // Generate curl command
        NSString *curlCommand = [FLEXNetworkCurlLogger curlCommandString:request];

        // Create filename from URL path
        NSString *urlPath = request.URL.lastPathComponent ?: @"request";
        urlPath = [urlPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        urlPath = [urlPath stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
        if (urlPath.length > 50) {
            urlPath = [urlPath substringToIndex:50];
        }

        NSString *filename = [NSString stringWithFormat:@"%03lu_%@_%@.sh",
            (unsigned long)(i + 1),
            request.HTTPMethod ?: @"GET",
            urlPath];

        NSString *filePath = [curlFolderPath stringByAppendingPathComponent:filename];

        // Add shebang and make executable
        NSString *content = [NSString stringWithFormat:@"#!/bin/bash\n# %@\n\n%@\n",
            request.URL.absoluteString, curlCommand];

        [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

    // Create README
    NSString *readme = [NSString stringWithFormat:
            @"# FLEX Network Export - Curl Commands\n\n"
            @"Exported: %@\n"
            @"Total Requests: %lu\n\n"
            @"## Usage\n\n"
            @"```bash\n"
            @"chmod +x *.sh\n"
            @"./001_GET_endpoint.sh\n"
            @"```\n\n"
            @"## Run All\n\n"
            @"```bash\n"
            @"for f in *.sh; do bash \"$f\"; done\n"
            @"```\n",
        [formatter stringFromDate:[NSDate date]],
        (unsigned long)transactions.count];
    NSString *readmePath = [curlFolderPath stringByAppendingPathComponent:@"README.md"];
    [readme writeToFile:readmePath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // Create ZIP using NSFileCoordinator
    NSURL *folderURL = [NSURL fileURLWithPath:curlFolderPath isDirectory:YES];
    NSURL *zipURL = [NSURL fileURLWithPath:zipPath];

    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    __block BOOL success = NO;
    __block NSError *coordinatorError = nil;

    [coordinator coordinateReadingItemAtURL:folderURL
                                    options:NSFileCoordinatorReadingForUploading
                                      error:&coordinatorError
                                 byAccessor:^(NSURL *newURL) {
                                     NSError *copyError = nil;
                                     success = [fileManager copyItemAtURL:newURL toURL:zipURL error:&copyError];
                                     if (!success) {
                                         NSLog(@"[FLEX] Failed to create ZIP: %@", copyError.localizedDescription);
                                     }
                                 }];

    // Cleanup folder
    [fileManager removeItemAtPath:curlFolderPath error:nil];

    if (!success || coordinatorError) {
        return nil;
    }

    return zipURL;
}

#pragma mark - Filtering

+ (NSArray<FLEXHTTPTransaction *> *)filterTransactionsForExport:(NSArray<FLEXHTTPTransaction *> *)transactions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL excludeImages = defaults.flex_exportExcludeImages;
    BOOL excludeAnalytics = defaults.flex_exportExcludeAnalytics;
    BOOL excludeFirebaseAnalytics = defaults.flex_exportExcludeFirebaseAnalytics;

    // If no filters enabled, return as-is
    if (!excludeImages && !excludeAnalytics && !excludeFirebaseAnalytics) {
        return transactions;
    }

    // Analytics hosts to exclude
    NSArray *analyticsHosts = @[
        // Mobile attribution & analytics
        @"adjust.com",
        @"adjust.io",
        @"adj.st",
        @"appsflyer.com",
        @"onelink.me",
        @"app.link",
        @"branch.io",
        @"amplitude.com",
        @"mixpanel.com",
        @"segment.io",
        @"segment.com",
        @"segmentapis.com",
        @"kochava.com",
        @"singular.net",
        @"tenjin.io",
        @"tenjin.com",

        // Facebook/Meta
        @"facebook.com",
        @"facebook.net",
        @"graph.facebook.com",
        @"fbcdn.net",
        @"fb.com",
        @"fb.gg",
        @"facebookanalytics",

        // Google Analytics
        @"google-analytics.com",
        @"googleanalytics.com",
        @"analytics.google.com",
        @"doubleclick.net",

        // Advertising & tracking
        @"criteo.com",
        @"criteo.net",
        @"mopub.com",
        @"applovin.com",
        @"unity3d.com",
        @"unityads.unity3d.com",
        @"ironsrc.com",
        @"ironsource.com",
        @"vungle.com",
        @"chartboost.com",
        @"adcolony.com",
        @"inmobi.com",
        @"tapjoy.com",
        @"fyber.com",
        @"liftoff.io",

        // Crash & performance
        @"crashlytics.com",
        @"bugsnag.com",
        @"sentry.io",
        @"raygun.io",
        @"instabug.com",

        // Other analytics
        @"flurry.com",
        @"localytics.com",
        @"braze.com",
        @"appboy.com",
        @"clevertap.com",
        @"moengage.com",
        @"leanplum.com",
        @"airship.com",
        @"urbanairship.com",
        @"onesignal.com",
        @"batch.com",
        @"uxcam.com",
        @"smartlook.com",
        @"hotjar.com",
        @"fullstory.com",
        @"heap.io",
        @"heapanalytics.com",
        @"countly.com",
        @"appmetrica",
        @"apptimize.com",
        @"optimizely.com",
        @"abtasty.com",
        @"launchdarkly.com",
    ];

    // Image extensions
    NSArray *imageExtensions = @[ @".jpg", @".jpeg", @".png", @".gif", @".webp", @".svg", @".ico", @".bmp", @".heic", @".heif" ];

    // Firebase Analytics patterns (but NOT Remote Config)
    NSArray *firebaseAnalyticsPatterns = @[
        @"app-measurement.com",
        @"firebase-analytics",
        @"firebaseanalytics",
        @"google-analytics.com/g/collect",
        @"analyticsdata.googleapis.com",
    ];

    return [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FLEXHTTPTransaction *transaction, NSDictionary *bindings) {
        NSString *urlString = transaction.request.URL.absoluteString.lowercaseString;
        NSString *host = transaction.request.URL.host.lowercaseString ?: @"";
        NSString *contentType = [transaction.response.MIMEType lowercaseString] ?: @"";

        // Exclude images
        if (excludeImages) {
            // Check Content-Type
            if ([contentType hasPrefix:@"image/"]) {
                return NO;
            }
            // Check URL extension
            for (NSString *ext in imageExtensions) {
                if ([urlString containsString:ext]) {
                    return NO;
                }
            }
        }

        // Exclude analytics
        if (excludeAnalytics) {
            for (NSString *analyticsHost in analyticsHosts) {
                if ([host containsString:analyticsHost] || [urlString containsString:analyticsHost]) {
                    return NO;
                }
            }
        }

        // Exclude Firebase Analytics (but keep Remote Config)
        if (excludeFirebaseAnalytics) {
            // First check if this is Remote Config - always keep
            if ([urlString containsString:@"remoteconfig"] ||
                [urlString containsString:@"firebaseremoteconfig"] ||
                [host containsString:@"firebaseremoteconfig"]) {
                return YES;
            }

            // Check Firebase Analytics patterns
            for (NSString *pattern in firebaseAnalyticsPatterns) {
                if ([urlString containsString:pattern] || [host containsString:pattern]) {
                    return NO;
                }
            }
        }

        return YES;
    }]];
}

#pragma mark - File Operations

+ (NSURL *)saveToTemporaryFile:(NSString *)content withFilename:(NSString *)filename
{
    NSString *tempDir = NSTemporaryDirectory();
    NSString *filePath = [tempDir stringByAppendingPathComponent:filename];

    NSError *error = nil;
    BOOL success = [content writeToFile:filePath
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&error];

    if (!success || error) {
        NSLog(@"[FLEX] Failed to save export file: %@", error.localizedDescription);
        return nil;
    }

    return [NSURL fileURLWithPath:filePath];
}

+ (NSString *)suggestedFilenameForFormat:(FLEXNetworkExportFormat)format isMultiple:(BOOL)isMultiple
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd_HHmmss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];

    NSString *prefix = isMultiple ? @"network_export" : @"request";

    switch (format) {
        case FLEXNetworkExportFormatRequestOnly:
            return [NSString stringWithFormat:@"%@_%@_request.txt", prefix, timestamp];
        case FLEXNetworkExportFormatResponseOnly:
            return [NSString stringWithFormat:@"%@_%@_response.txt", prefix, timestamp];
        case FLEXNetworkExportFormatRaw:
            return [NSString stringWithFormat:@"%@_%@.txt", prefix, timestamp];
        case FLEXNetworkExportFormatHAR:
            return [NSString stringWithFormat:@"%@_%@.har", prefix, timestamp];
        case FLEXNetworkExportFormatPostman:
            return [NSString stringWithFormat:@"%@_%@_postman.json", prefix, timestamp];
        case FLEXNetworkExportFormatSwagger:
            return [NSString stringWithFormat:@"%@_%@_swagger.json", prefix, timestamp];
        case FLEXNetworkExportFormatCurlZip:
            return [NSString stringWithFormat:@"curl_requests_%@.zip", timestamp];
    }
}

@end
