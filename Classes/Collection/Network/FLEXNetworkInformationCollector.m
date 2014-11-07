//
//  FLEXNetworkInformationCollector.m
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXNetworkInformationCollector.h"

#import "NSDate+PDDebugger.h"
#import "NSData+PDDebugger.h"

#import "FLEXNetworkResponse.h"
#import "FLEXNetworkRequest.h"
#import "FLEXNetworkConnection.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/queue.h>


@interface _PDRequestState : NSObject

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, copy) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *dataAccumulator;
@property (nonatomic, copy) NSString *requestID;

@end


@interface FLEXNetworkInformationCollector ()

/**
 *  Stores all requests
 */
@property (nonatomic, strong) NSMutableDictionary *baseRequests;
@property (nonatomic, strong) NSCache *responseCache;
@property (nonatomic, strong) NSMutableDictionary *connectionStates;
@property (nonatomic) dispatch_queue_t queue;

- (void)setResponse:(NSData *)responseBody forRequestID:(NSString *)requestID response:(NSURLResponse *)response request:(NSURLRequest *)request;
- (void)performBlock:(dispatch_block_t)block;

@end


@implementation FLEXNetworkInformationCollector

#pragma mark - Getters and Setters

- (NSArray *)requests
{
    NSArray *requests = [self.baseRequests allValues];
    
    requests = [requests sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        NSNumber* timing1 = [obj1 timing].connectStart;
        NSNumber* timing2 = [obj2 timing].connectStart;
        
        if (timing1 && timing2)
        {
            return [timing1 compare:timing2];
        }
        
        return NSOrderedSame;
    }];
    
    return [self.baseRequests allValues];
}

- (NSMutableDictionary *)baseRequests
{
    if (!_baseRequests)
    {
        _baseRequests = [NSMutableDictionary dictionary];
    }
    
    return _baseRequests;
}

#pragma mark - Statics

/**
 *  Creates unique request ID as a string
 *
 *  @return unique request ID
 */
+ (NSString *)nextRequestID;
{
    static NSInteger sequenceNumber = 0;
    static NSString *seed = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
        seed = (__bridge NSString *)CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
        CFRelease(uuid);
    });
    
    return [[NSString alloc] initWithFormat:@"%@-%ld", seed, (long)(++sequenceNumber)];
}

#pragma mark Delegate Injection Convenience Methods

+ (SEL)swizzledSelectorForSelector:(SEL)selector;
{
    return NSSelectorFromString([NSString stringWithFormat:@"_pd_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

+ (void)domainControllerSwizzleGuardForSwizzledObject:(id)object selector:(SEL)selector implementationBlock:(void (^)(void))implementationBlock;
{
    void *key = (__bridge void *)[[NSString alloc] initWithFormat:@"PDSelectorGuardKeyForSelector:%@", NSStringFromSelector(selector)];
    if (!objc_getAssociatedObject(object, key)) {
        objc_setAssociatedObject(object, key, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_ASSIGN);
        implementationBlock();
        objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
{
    if ([cls instancesRespondToSelector:selector]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);
        
        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (selector == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }
        
        free(methods);
        
        if (!implementsSelector) {
            return YES;
        }
    }
    
    return NO;
}

+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;
{
    if ([self instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }
    
#ifdef __IPHONE_6_0
    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
#else
    IMP implementation = imp_implementationWithBlock((__bridge void *)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
#endif
    
    Method oldMethod = class_getInstanceMethod(cls, selector);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);
        
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, selector, implementation, methodDescription.types);
    }
}

#pragma mark - Delegate Injection

+ (void)injectIntoAllNSURLConnectionDelegateClasses;
{
    // Only allow swizzling once.
    static BOOL swizzled = NO;
    if (swizzled) {
        return;
    }
    
    swizzled = YES;
    
    // Swizzle any classes that implement one of these selectors.
    const SEL selectors[] = {
        @selector(connectionDidFinishLoading:),
        @selector(connection:didReceiveResponse:),
        @selector(URLSession:dataTask:didReceiveResponse:completionHandler:),
        @selector(URLSession:task:didCompleteWithError:),
        @selector(URLSession:downloadTask:didFinishDownloadingToURL:)
    };
    
    const int numSelectors = sizeof(selectors) / sizeof(SEL);
    
    Class *classes = NULL;
    int numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
            Class class = classes[classIndex];
            
            if (class_getClassMethod(class, @selector(isSubclassOfClass:)) == NULL) {
                continue;
            }
            
            if (![class isSubclassOfClass:[NSObject class]]) {
                continue;
            }
            
            if ([class isSubclassOfClass:[FLEXNetworkInformationCollector class]]) {
                continue;
            }
            
            for (int selectorIndex = 0; selectorIndex < numSelectors; ++selectorIndex) {
                if ([class instancesRespondToSelector:selectors[selectorIndex]]) {
                    [self injectIntoDelegateClass:class];
                    break;
                }
            }
        }
        
        free(classes);
    }
}

+ (void)injectIntoDelegateClass:(Class)cls;
{
    // Connections
    [self injectWillSendRequestIntoDelegateClass:cls];
    [self injectDidReceiveDataIntoDelegateClass:cls];
    [self injectDidReceiveResponseIntoDelegateClass:cls];
    [self injectDidFinishLoadingIntoDelegateClass:cls];
    [self injectDidFailWithErrorIntoDelegateClass:cls];
    
    // Sessions
    [self injectTaskWillPerformHTTPRedirectionIntoDelegateClass:cls];
    [self injectTaskDidReceiveDataIntoDelegateClass:cls];
    [self injectTaskDidReceiveResponseIntoDelegateClass:cls];
    [self injectTaskDidCompleteWithErrorIntoDelegateClass:cls];
    [self injectRespondsToSelectorIntoDelegateClass:cls];
    
    // Download tasks
    [self injectDownloadTaskDidWriteDataIntoDelegateClass:cls];
    [self injectDownloadTaskDidFinishDownloadingIntoDelegateClass:cls];
}

+ (void)injectWillSendRequestIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(connection:willSendRequest:redirectResponse:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef NSURLRequest *(^NSURLConnectionWillSendRequestBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response);
    
    NSURLConnectionWillSendRequestBlock undefinedBlock = ^NSURLRequest *(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        [self domainControllerSwizzleGuardForSwizzledObject:slf selector:selector implementationBlock:^{
            [[FLEXNetworkInformationCollector sharedCollector] connection:connection willSendRequest:request redirectResponse:response];
        }];
        
        return request;
    };
    
    NSURLConnectionWillSendRequestBlock implementationBlock = ^NSURLRequest *(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        NSURLRequest *returnValue = ((id(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, connection, request, response);
        undefinedBlock(slf, connection, request, response);
        return returnValue;
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidReceiveResponseIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(connection:didReceiveResponse:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLConnectionDidReceiveResponseBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response);
    
    NSURLConnectionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response) {
        [self domainControllerSwizzleGuardForSwizzledObject:slf selector:selector implementationBlock:^{
            [[FLEXNetworkInformationCollector sharedCollector] connection:connection didReceiveResponse:response];
        }];
    };
    
    NSURLConnectionDidReceiveResponseBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response) {
        undefinedBlock(slf, connection, response);
        ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, response);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidReceiveDataIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(connection:didReceiveData:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLConnectionDidReceiveDataBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSData *data);
    
    NSURLConnectionDidReceiveDataBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSData *data) {
        [[FLEXNetworkInformationCollector sharedCollector] connection:connection didReceiveData:data];
    };
    
    NSURLConnectionDidReceiveDataBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSData *data) {
        undefinedBlock(slf, connection, data);
        ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, data);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidFinishLoadingIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(connectionDidFinishLoading:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLConnectionDidFinishLoadingBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection);
    
    NSURLConnectionDidFinishLoadingBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection) {
        [[FLEXNetworkInformationCollector sharedCollector] connectionDidFinishLoading:connection];
    };
    
    NSURLConnectionDidFinishLoadingBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection) {
        undefinedBlock(slf, connection);
        ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledSelector, connection);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidFailWithErrorIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(connection:didFailWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLConnectionDidFailWithErrorBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error);
    
    NSURLConnectionDidFailWithErrorBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        [[FLEXNetworkInformationCollector sharedCollector] connection:connection didFailWithError:error];
    };
    
    NSURLConnectionDidFailWithErrorBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        undefinedBlock(slf, connection, error);
        ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, error);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectTaskWillPerformHTTPRedirectionIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionWillPerformHTTPRedirectionBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *));
    
    NSURLSessionWillPerformHTTPRedirectionBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        [self domainControllerSwizzleGuardForSwizzledObject:slf selector:selector implementationBlock:^{
            [[FLEXNetworkInformationCollector sharedCollector] URLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler];
        }];
    };
    
    NSURLSessionWillPerformHTTPRedirectionBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        ((id(*)(id, SEL, id, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, task, response, newRequest, completionHandler);
        undefinedBlock(slf, session, task, response, newRequest, completionHandler);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectTaskDidReceiveDataIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didReceiveData:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveDataBlock)(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
    
    NSURLSessionDidReceiveDataBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        [[FLEXNetworkInformationCollector sharedCollector] URLSession:session dataTask:dataTask didReceiveData:data];
    };
    
    NSURLSessionDidReceiveDataBlock implementationBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        undefinedBlock(slf, session, dataTask, data);
        ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, dataTask, data);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectTaskDidReceiveResponseIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLConnectionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition));
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLConnectionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        [self domainControllerSwizzleGuardForSwizzledObject:slf selector:selector implementationBlock:^{
            [[FLEXNetworkInformationCollector sharedCollector] URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }];
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLConnectionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        undefinedBlock(slf, session, dataTask, response, completionHandler);
        ((void(*)(id, SEL, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, dataTask, response, completionHandler);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectTaskDidCompleteWithErrorIntoDelegateClass:(Class)cls;
{
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionTaskDidCompleteWithErrorBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error);
    
    NSURLSessionTaskDidCompleteWithErrorBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [[FLEXNetworkInformationCollector sharedCollector] URLSession:session task:task didCompleteWithError:error];
    };
    
    NSURLSessionTaskDidCompleteWithErrorBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        undefinedBlock(slf, session, task, error);
        ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, error);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

// Used for overriding AFNetworking behavior
+ (void)injectRespondsToSelectorIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(respondsToSelector:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    //Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    Method method = class_getInstanceMethod(cls, selector);
    struct objc_method_description methodDescription = *method_getDescription(method);
    
    typedef void (^NSURLSessionTaskDidCompleteWithErrorBlock)(id slf, SEL sel);
    
    BOOL (^undefinedBlock)(id <NSURLSessionTaskDelegate>, SEL) = ^(id slf, SEL sel) {
        return YES;
    };
    
    BOOL (^implementationBlock)(id <NSURLSessionTaskDelegate>, SEL) = ^(id <NSURLSessionTaskDelegate> slf, SEL sel) {
        if (sel == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
            return undefinedBlock(slf, sel);
        }
        return ((BOOL(*)(id, SEL, SEL))objc_msgSend)(slf, swizzledSelector, sel);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}


+ (void)injectDownloadTaskDidFinishDownloadingIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:downloadTask:didFinishDownloadingToURL:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDownloadDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDownloadTaskDidFinishDownloadingBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location);
    
    NSURLSessionDownloadTaskDidFinishDownloadingBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location) {
        NSData *data = [NSData dataWithContentsOfFile:location.relativePath];
        [[FLEXNetworkInformationCollector sharedCollector] URLSession:session task:task didFinishDownloadingToURL:location data:data];
    };
    
    NSURLSessionDownloadTaskDidFinishDownloadingBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location) {
        undefinedBlock(slf, session, task, location);
        ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, location);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDownloadTaskDidWriteDataIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDownloadDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDownloadTaskDidWriteDataBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
    
    NSURLSessionDownloadTaskDidWriteDataBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [[FLEXNetworkInformationCollector sharedCollector] URLSession:session downloadTask:task didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    };
    
    NSURLSessionDownloadTaskDidWriteDataBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        undefinedBlock(slf, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        ((void(*)(id, SEL, id, id, int64_t, int64_t, int64_t))objc_msgSend)(slf, swizzledSelector, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

#pragma mark - Initialization

- (id)init;
{
    self = [super init];
    
    if (!self)
    {
        return nil;
    }
    
    self.connectionStates = [[NSMutableDictionary alloc] init];
    self.responseCache = [[NSCache alloc] init];
    self.queue = dispatch_queue_create("com.squareup.ponydebugger.PDNetworkDomainController", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

#pragma mark - Private Methods

- (void)setResponse:(NSData *)responseBody forRequestID:(NSString *)requestID response:(NSURLResponse *)response request:(NSURLRequest *)request;
{
     NSString *encodedBody = responseBody.base64Encoding;
     BOOL isBinary = YES;
     
     NSDictionary *responseDict = [NSDictionary dictionaryWithObjectsAndKeys:encodedBody, @"body", [NSNumber numberWithBool:isBinary], @"base64Encoded", nil];
     
     [self.responseCache setObject:responseDict forKey:requestID cost:[responseBody length]];
}

- (void)performBlock:(dispatch_block_t)block;
{
    dispatch_async(_queue, block);
}

#pragma mark - Private Methods (Connections)

- (_PDRequestState *)requestStateForConnection:(NSURLConnection *)connection;
{
    NSValue *key = [NSValue valueWithNonretainedObject:connection];
    _PDRequestState *state = [_connectionStates objectForKey:key];
    
    if (!state)
    {
        state = [[_PDRequestState alloc] init];
        state.requestID = [[self class] nextRequestID];
        [_connectionStates setObject:state forKey:key];
    }
    
    return state;
}

- (NSString *)requestIDForConnection:(NSURLConnection *)connection;
{
    return [self requestStateForConnection:connection].requestID;
}

- (void)setResponse:(NSURLResponse *)response forConnection:(NSURLConnection *)connection;
{
    [self requestStateForConnection:connection].response = response;
}

- (NSURLResponse *)responseForConnection:(NSURLConnection *)connection;
{
    return [self requestStateForConnection:connection].response;
}

- (void)setRequest:(NSURLRequest *)request forConnection:(NSURLConnection *)connection;
{
    [self requestStateForConnection:connection].request = request;
}

- (NSURLRequest *)requestForConnection:(NSURLConnection *)connection;
{
    return [self requestStateForConnection:connection].request;
}

- (void)setAccumulatedData:(NSMutableData *)data forConnection:(NSURLConnection *)connection;
{
    _PDRequestState *requestState = [self requestStateForConnection:connection];
    requestState.dataAccumulator = data;
}

- (void)addAccumulatedData:(NSData *)data forConnection:(NSURLConnection *)connection;
{
    NSMutableData *dataAccumulator = [self requestStateForConnection:connection].dataAccumulator;
    
    [dataAccumulator appendData:data];
}

- (NSData *)accumulatedDataForConnection:(NSURLConnection *)connection;
{
    return [self requestStateForConnection:connection].dataAccumulator;
}

// This removes storing the accumulated request/response from the dictionary so we can release connection
- (void)connectionFinished:(NSURLConnection *)connection;
{
    //
    // Create FLEX network information, so it stays aggregated
    //
    
    _PDRequestState *connectionState = [self requestStateForConnection:connection];
    
    FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:connection];
    networkConnection.request = [FLEXNetworkRequest networkRequestWithURLRequest:connectionState.request];
    networkConnection.response = [FLEXNetworkResponse networkResponseWithURLResponse:connectionState.response request:connectionState.request];
    networkConnection.requestID = connectionState.requestID;
    networkConnection.responseString = [[NSString alloc] initWithData:connectionState.dataAccumulator encoding:NSUTF8StringEncoding];
    networkConnection.size = @(connectionState.dataAccumulator.length);
    
    NSValue *key = [NSValue valueWithNonretainedObject:connection];
    [self.connectionStates removeObjectForKey:key];
}

#pragma mark - Private Methods (Tasks)

- (_PDRequestState *)requestStateForTask:(NSURLSessionTask *)task;
{
    NSValue *key = [NSValue valueWithNonretainedObject:task];
    _PDRequestState *state = [self.connectionStates objectForKey:key];
    if (!state) {
        state = [[_PDRequestState alloc] init];
        state.requestID = [[self class] nextRequestID];
        [self.connectionStates setObject:state forKey:key];
    }
    
    return state;
}

- (NSString *)requestIDForTask:(NSURLSessionTask *)task;
{
    return [self requestStateForTask:task].requestID;
}

- (void)setResponse:(NSURLResponse *)response forTask:(NSURLSessionTask *)task;
{
    [self requestStateForTask:task].response = response;
}

- (NSURLResponse *)responseForTask:(NSURLSessionTask *)task
{
    return [self requestStateForTask:task].response;
}

- (void)setRequest:(NSURLRequest *)request forTask:(NSURLSessionTask *)task;
{
    [self requestStateForTask:task].request = request;
}

- (NSURLRequest *)requestForTask:(NSURLSessionTask *)task;
{
    return [self requestStateForTask:task].request;
}

- (void)setAccumulatedData:(NSMutableData *)data forTask:(NSURLSessionTask *)task;
{
    _PDRequestState *requestState = [self requestStateForTask:task];
    requestState.dataAccumulator = data;
}

- (void)addAccumulatedData:(NSData *)data forTask:(NSURLSessionTask *)task;
{
    NSMutableData *dataAccumulator = [self requestStateForTask:task].dataAccumulator;
    
    [dataAccumulator appendData:data];
}

- (NSData *)accumulatedDataForTask:(NSURLSessionTask *)task;
{
    return [self requestStateForTask:task].dataAccumulator;
}

// This removes storing the accumulated request/response from the dictionary so we can release task
- (void)taskFinished:(NSURLSessionTask *)task;
{
    //
    // Create FLEX network information, so it stays aggregated
    //
    
    _PDRequestState *connectionState = [self requestStateForTask:task];
    
    FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:task];
    networkConnection.request = [FLEXNetworkRequest networkRequestWithURLRequest:connectionState.request];
    networkConnection.response = [FLEXNetworkResponse networkResponseWithURLResponse:connectionState.response request:connectionState.request];
    networkConnection.requestID = connectionState.requestID;
    networkConnection.responseString = [[NSString alloc] initWithData:connectionState.dataAccumulator encoding:NSUTF8StringEncoding];
    networkConnection.size = @(connectionState.dataAccumulator.length);
    
    NSValue *key = [NSValue valueWithNonretainedObject:task];
    [self.connectionStates removeObjectForKey:key];
}


#pragma mark - Data Model Helpers

- (FLEXNetworkConnection *)networkConnectionForObject:(id)object
{
    FLEXNetworkConnection *networkConnection = nil;
    
    if ([object isKindOfClass:[NSURLSessionTask class]])
    {
        networkConnection = [self _networkConnectionForTask:object];
    }
    else if ([object isKindOfClass:[NSURLConnection class]])
    {
        networkConnection = [self _networkConnectionForConnection:object];
    }
    
    if (!networkConnection.timing)
    {
        networkConnection.timing = [[FLEXNetworkResourceTiming alloc] init];
    }
    
    return networkConnection;
}

/**
 *  Creates and returns network connection object, do NOT call directly,
 *  call networkConnectionForObject instead.
 *
 *  @param connection Connection that was sent
 *
 *  @return network connection object
 */
- (FLEXNetworkConnection *)_networkConnectionForConnection:(NSURLConnection *)connection
{
    NSString *requestID = [self requestIDForConnection:connection];
    
    if (!self.baseRequests[requestID])
    {
        FLEXNetworkConnection *connection = [[FLEXNetworkConnection alloc] init];
        connection.type = FLEXNetworkConnectionTypeConnection;
        connection.requestID = [requestID copy];
        
        self.baseRequests[requestID] = connection;
    }
    
    return self.baseRequests[requestID];
}

/**
 *  Creates and returns network connection object, do NOT call directly,
 *  call networkConnectionForObject instead.
 *
 *  @param task URL session task
 *
 *  @return network connection object
 */
- (FLEXNetworkConnection *)_networkConnectionForTask:(NSURLSessionTask *)task
{
    NSString *requestID = [self requestIDForTask:task];
    
    if (!self.baseRequests[requestID])
    {
        FLEXNetworkConnection *connection = [[FLEXNetworkConnection alloc] init];
        connection.type = FLEXNetworkConnectionTypeSession;
        connection.requestID = [requestID copy];
        
        self.baseRequests[requestID] = connection;
    }
    
    return self.baseRequests[requestID];
}

@end


#pragma mark - NSURLConnectionHelpers

@implementation FLEXNetworkInformationCollector (NSURLConnectionHelpers)

- (void)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
{
    [self performBlock:^{
        [self setRequest:request forConnection:connection];
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:connection];
        networkConnection.timing.connectStart = [NSDate PD_timestamp];
        
        [networkConnection updateWithRequest:[FLEXNetworkRequest networkRequestWithURLRequest:request] withResponse:nil];
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    [self performBlock:^
    {
        if ([response respondsToSelector:@selector(copyWithZone:)])
        {
            // If the request wasn't generated yet, then willSendRequest was not called. This appears to be an inconsistency in documentation
            // and behavior.
            NSURLRequest *request = [self requestForConnection:connection];
            
            if (!request && [connection respondsToSelector:@selector(currentRequest)])
            {
                
                NSLog(@"Warning: -[FLEXNetworkInformationCollector connection:willSendRequest:redirectResponse:] not called, request timestamp may be inaccurate. See Known Issues in the README for more information.");
                
                request = connection.currentRequest;
                [self setRequest:request forConnection:connection];
            }
            
            [self setResponse:response forConnection:connection];
            
            NSMutableData *dataAccumulator = nil;
            if (response.expectedContentLength < 0) {
                dataAccumulator = [[NSMutableData alloc] init];
            } else {
                dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger)response.expectedContentLength];
            }
            
            [self setAccumulatedData:dataAccumulator forConnection:connection];
            
            FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:connection];
            
            if (!networkConnection.timing.receiveHeadersEnd)
            {
                networkConnection.timing.receiveHeadersEnd = [NSDate PD_timestamp];
            }
            
            [networkConnection updateWithRequest:[FLEXNetworkRequest networkRequestWithURLRequest:request] withResponse:nil];
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    // Just to be safe since we're doing this async
    data = [data copy];
    [self performBlock:^{
        [self addAccumulatedData:data forConnection:connection];
        
        if ([self accumulatedDataForConnection:connection] == nil)
        {
            return;
        }
        
        /*NSNumber *length = [NSNumber numberWithInteger:data.length];
        NSString *requestID = [self requestIDForConnection:connection];
        
        [self.domain dataReceivedWithRequestId:requestID
         timestamp:[NSDate PD_timestamp]
         dataLength:length
         encodedDataLength:length];*/
    }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    [self performBlock:^
    {
        NSURLResponse *response = [self responseForConnection:connection];
        NSString *requestID = [self requestIDForConnection:connection];
        
        NSData *accumulatedData = [self accumulatedDataForConnection:connection];
        
        [self setResponse:accumulatedData forRequestID:requestID response:response request:[self requestForConnection:connection]];
        
        /*[self.domain loadingFinishedWithRequestId:requestID
         timestamp:[NSDate PD_timestamp]];*/
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:connection];
        networkConnection.timing.connectEnd = [NSDate PD_timestamp];
        
        [self connectionFinished:connection];
        
    }];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    [self performBlock:^
    {
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:connection];
        networkConnection.timing.connectEnd = [NSDate PD_timestamp];
        
        [self connectionFinished:connection];
    }];
}

@end

#pragma mark - NSURLSessionTaskHelpers

@implementation FLEXNetworkInformationCollector (NSURLSessionTaskHelpers)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    [self performBlock:^
    {
        [self setRequest:request forTask:task];
        FLEXNetworkRequest *networkRequest = [FLEXNetworkRequest networkRequestWithURLRequest:request];
        FLEXNetworkResponse *networkRedirectResponse = response ? [[FLEXNetworkResponse alloc] initWithURLResponse:response request:request] : nil;
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:task];
        [networkConnection updateWithRequest:networkRequest withResponse:networkRedirectResponse];
        
        networkConnection.timing.connectStart = [NSDate PD_timestamp];
        [networkConnection updateWithRequest:networkRequest withResponse:nil];
    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
{
    if ([response respondsToSelector:@selector(copyWithZone:)]) {
        
        // willSendRequest does not exist in NSURLSession. Here's a workaround.
        NSURLRequest *request = [self requestForTask:dataTask];
        if (!request && [dataTask respondsToSelector:@selector(currentRequest)]) {
            
            NSLog(@"PonyDebugger Warning: request timestamp may be inaccurate. See Known Issues in the README for more information.");
            
            request = dataTask.currentRequest;
            [self setRequest:request forTask:dataTask];
        }
        
        [self setResponse:response forTask:dataTask];
        
        NSMutableData *dataAccumulator = nil;
        if (response.expectedContentLength < 0) {
            dataAccumulator = [[NSMutableData alloc] init];
        } else {
            dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger)response.expectedContentLength];
        }
        
        [self setAccumulatedData:dataAccumulator forTask:dataTask];
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:dataTask];
        
        if (!networkConnection.timing.receiveHeadersEnd)
        {
            networkConnection.timing.receiveHeadersEnd = [NSDate PD_timestamp];
        }
        
        [networkConnection updateWithRequest:[FLEXNetworkRequest networkRequestWithURLRequest:request] withResponse:nil];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // Just to be safe since we're doing this async
    data = [data copy];
    
    [self performBlock:^
    {
        [self addAccumulatedData:data forTask:dataTask];
        
        if ([self accumulatedDataForTask:dataTask] == nil)
        {
            return;
        }
        
        /*NSNumber *length = [NSNumber numberWithInteger:data.length];
        NSString *requestID = [self requestIDForTask:dataTask];*/
        
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
{
    [self performBlock:^
    {
        NSURLResponse *response = [self responseForTask:task];
        NSString *requestID = [self requestIDForTask:task];
        
        NSData *accumulatedData = [self accumulatedDataForTask:task];
        
        if (!error)
        {
            [self setResponse:accumulatedData forRequestID:requestID response:response request:[self requestForTask:task]];
        }
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:task];
        
        networkConnection.timing.connectEnd = [NSDate PD_timestamp];
        
        [self taskFinished:task];
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    [self performBlock:^
    {
        // If the request wasn't generated yet, then willSendRequest was not called. This appears to be an inconsistency in documentation
        // and behavior.
        NSURLRequest *request = [self requestForTask:downloadTask];
        if (!request && [downloadTask respondsToSelector:@selector(currentRequest)])
        {
            
            request = downloadTask.currentRequest;
            [self setRequest:request forTask:downloadTask];
            //NSString *requestID = [self requestIDForTask:downloadTask];
            
            [self setResponse:downloadTask.response forTask:downloadTask];
            
            NSMutableData *dataAccumulator = nil;
            dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger) totalBytesExpectedToWrite];
            [self setAccumulatedData:dataAccumulator forTask:downloadTask];
            
        }
        
        [self addAccumulatedData:[NSData emptyDataOfLength:(NSUInteger) bytesWritten] forTask:downloadTask];
        
        /*NSNumber *length = [NSNumber numberWithInteger:(NSInteger) bytesWritten];
        NSString *requestID = [self requestIDForTask:downloadTask];*/
        
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location data:(NSData *)data
{
    [self performBlock:^
    {
        NSURLResponse *response = [self responseForTask:downloadTask];
        NSString *requestID = [self requestIDForTask:downloadTask];
        
        [self setResponse:data forRequestID:requestID response:response request:[self requestForTask:downloadTask]];
        
        FLEXNetworkConnection *networkConnection = [self networkConnectionForObject:downloadTask];
        
        networkConnection.timing.connectEnd = [NSDate PD_timestamp];
        
        [self taskFinished:downloadTask];
    }];
}

@end


@implementation _PDRequestState

@end