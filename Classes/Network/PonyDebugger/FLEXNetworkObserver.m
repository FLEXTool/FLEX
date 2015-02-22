//
//  FLEXNetworkObserver.m
//  Derived from:
//
//  PDAFNetworkDomainController.m
//  PonyDebugger
//
//  Created by Mike Lewis on 2/27/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/queue.h>

NSString *const kFLEXNetworkObserverEnabledStateChangedNotification = @"kFLEXNetworkObserverEnabledStateChangedNotification";
static NSString *const kFLEXNetworkObserverEnableOnLaunchDefaultsKey = @"com.flex.FLEXNetworkObserver.enableOnLaunch";

@interface FLEXInternalRequestState : NSObject

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) NSMutableData *dataAccumulator;
@property (nonatomic, copy) NSString *requestID;

@end

@implementation FLEXInternalRequestState

@end

@interface FLEXNetworkObserver (NSURLConnectionHelpers)

- (void)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response delegate:(id <NSURLConnectionDelegate>)delegate;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response delegate:(id <NSURLConnectionDelegate>)delegate;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data delegate:(id <NSURLConnectionDelegate>)delegate;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection delegate:(id <NSURLConnectionDelegate>)delegate;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error delegate:(id <NSURLConnectionDelegate>)delegate;

@end


@interface FLEXNetworkObserver (NSURLSessionTaskHelpers)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler delegate:(id <NSURLSessionDelegate>)delegate;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler delegate:(id <NSURLSessionDelegate>)delegate;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data delegate:(id <NSURLSessionDelegate>)delegate;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error delegate:(id <NSURLSessionDelegate>)delegate;
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite delegate:(id <NSURLSessionDelegate>)delegate;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location data:(NSData *)data delegate:(id <NSURLSessionDelegate>)delegate;

@end

@interface FLEXNetworkObserver ()

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, strong) NSMutableDictionary *connectionStates;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation FLEXNetworkObserver

#pragma mark - Public Methods

+ (void)setEnabled:(BOOL)enabled
{
    if (enabled) {
        // Inject if needed. This injection is protected with a dispatch_once, so we're ok calling it multiple times.
        // By doing the injection lazily, we keep the impact of the tool lower when this feature isn't enabled.
        [self injectIntoAllNSURLConnectionDelegateClasses];
    }
    [[self sharedObserver] setEnabled:enabled];
}

+ (BOOL)isEnabled
{
    return [[self sharedObserver] isEnabled];
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:kFLEXNetworkObserverEnabledStateChangedNotification object:self];
    }
}

+ (void)setShouldEnableOnLaunch:(BOOL)shouldEnableOnLaunch
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kFLEXNetworkObserverEnableOnLaunchDefaultsKey];
}

+ (BOOL)shouldEnableOnLaunch
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kFLEXNetworkObserverEnableOnLaunchDefaultsKey] boolValue];
}

+ (void)load
{
    // We don't want to do the swizzling from +load because not all the classes may be loaded at this point.
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self shouldEnableOnLaunch]) {
            [self setEnabled:YES];
        }
    });
}

#pragma mark - Statics

+ (instancetype)sharedObserver
{
    static FLEXNetworkObserver *sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[[self class] alloc] init];
    });
    return sharedObserver;
}

+ (NSString *)nextRequestID
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

+ (SEL)swizzledSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"_flex_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

/// All swizzled delegate methods should make use of this guard.
/// This will prevent duplicated sniffing when the original implementation calls up to a superclass implementation which we've also swizzled.
/// The superclass implementation (and implementations in classes above that) will be executed without inteference if called from the original implementation.
+ (void)sniffWithoutDuplicationForObject:(NSObject *)object selector:(SEL)selector sniffingBlock:(void (^)(void))sniffingBlock originalImplementationBlock:(void (^)(void))originalImplementationBlock
{
    const void *key = selector;

    // Don't run the sniffing block if we're inside a nested call
    if (!objc_getAssociatedObject(object, key)) {
        sniffingBlock();
    }

    // Mark that we're calling through to the original so we can detect nested calls
    objc_setAssociatedObject(object, key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    originalImplementationBlock();
    objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls
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

+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock
{
    if ([self instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }

    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
    
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

+ (void)injectIntoAllNSURLConnectionDelegateClasses
{
    // Only allow swizzling once.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
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

                if (class == [FLEXNetworkObserver class]) {
                    continue;
                }

                // Use the runtime API rather than the methods on NSObject to avoid sending messages to
                // classes we're not interested in swizzling. Otherwise we hit +initialize on all classes.
                for (int selectorIndex = 0; selectorIndex < numSelectors; ++selectorIndex) {
                    if (class_getInstanceMethod(class, selectors[selectorIndex])) {
                        [self injectIntoDelegateClass:class];
                        break;
                    }
                }
            }
            
            free(classes);
        }
    });
}

+ (void)injectIntoDelegateClass:(Class)cls
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

+ (void)injectWillSendRequestIntoDelegateClass:(Class)cls
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
        [[FLEXNetworkObserver sharedObserver] connection:connection willSendRequest:request redirectResponse:response delegate:slf];
        return request;
    };
    
    NSURLConnectionWillSendRequestBlock implementationBlock = ^NSURLRequest *(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        __block NSURLRequest *returnValue = nil;
        [self sniffWithoutDuplicationForObject:connection selector:selector sniffingBlock:^{
            undefinedBlock(slf, connection, request, response);
        } originalImplementationBlock:^{
            returnValue = ((id(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, connection, request, response);
        }];
        return returnValue;
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidReceiveResponseIntoDelegateClass:(Class)cls
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
        [[FLEXNetworkObserver sharedObserver] connection:connection didReceiveResponse:response delegate:slf];
    };
    
    NSURLConnectionDidReceiveResponseBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response) {
        [self sniffWithoutDuplicationForObject:connection selector:selector sniffingBlock:^{
            undefinedBlock(slf, connection, response);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, response);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidReceiveDataIntoDelegateClass:(Class)cls
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
        [[FLEXNetworkObserver sharedObserver] connection:connection didReceiveData:data delegate:slf];
    };
    
    NSURLConnectionDidReceiveDataBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSData *data) {
        [self sniffWithoutDuplicationForObject:connection selector:selector sniffingBlock:^{
            undefinedBlock(slf, connection, data);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, data);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidFinishLoadingIntoDelegateClass:(Class)cls
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
        [[FLEXNetworkObserver sharedObserver] connectionDidFinishLoading:connection delegate:slf];
    };
    
    NSURLConnectionDidFinishLoadingBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection) {
        [self sniffWithoutDuplicationForObject:connection selector:selector sniffingBlock:^{
            undefinedBlock(slf, connection);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledSelector, connection);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidFailWithErrorIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(connection:didFailWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLConnectionDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLConnectionDidFailWithErrorBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error);
    
    NSURLConnectionDidFailWithErrorBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        [[FLEXNetworkObserver sharedObserver] connection:connection didFailWithError:error delegate:slf];
    };
    
    NSURLConnectionDidFailWithErrorBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        [self sniffWithoutDuplicationForObject:connection selector:selector sniffingBlock:^{
            undefinedBlock(slf, connection, error);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, error);
        }];
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
        [[FLEXNetworkObserver sharedObserver] URLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler delegate:slf];
    };

    NSURLSessionWillPerformHTTPRedirectionBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, response, newRequest, completionHandler);
        } originalImplementationBlock:^{
            ((id(*)(id, SEL, id, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, task, response, newRequest, completionHandler);
        }];
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
        [[FLEXNetworkObserver sharedObserver] URLSession:session dataTask:dataTask didReceiveData:data delegate:slf];
    };
    
    NSURLSessionDidReceiveDataBlock implementationBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, dataTask, data);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, dataTask, data);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];

}

+ (void)injectTaskDidReceiveResponseIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition));
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        [[FLEXNetworkObserver sharedObserver] URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler delegate:slf];
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, dataTask, response, completionHandler);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, dataTask, response, completionHandler);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];

}

+ (void)injectTaskDidCompleteWithErrorIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionTaskDidCompleteWithErrorBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error);

    NSURLSessionTaskDidCompleteWithErrorBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [[FLEXNetworkObserver sharedObserver] URLSession:session task:task didCompleteWithError:error delegate:slf];
    };

    NSURLSessionTaskDidCompleteWithErrorBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, error);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, error);
        }];
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
        [[FLEXNetworkObserver sharedObserver] URLSession:session task:task didFinishDownloadingToURL:location data:data delegate:slf];
    };

    NSURLSessionDownloadTaskDidFinishDownloadingBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, location);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, location);
        }];
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
        [[FLEXNetworkObserver sharedObserver] URLSession:session downloadTask:task didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite delegate:slf];
    };

    NSURLSessionDownloadTaskDidWriteDataBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, int64_t, int64_t, int64_t))objc_msgSend)(slf, swizzledSelector, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }];
    };

    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];

}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _connectionStates = [[NSMutableDictionary alloc] init];
    _queue = dispatch_queue_create("com.flex.FLEXNetworkObserver", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

#pragma mark - Private Methods

- (void)performBlock:(dispatch_block_t)block
{
    if (self.isEnabled) {
        dispatch_async(_queue, block);
    }
}

#pragma mark - Private Methods (Connections)

- (FLEXInternalRequestState *)requestStateForConnection:(NSURLConnection *)connection
{
    NSValue *key = [NSValue valueWithNonretainedObject:connection];
    FLEXInternalRequestState *state = [_connectionStates objectForKey:key];
    if (!state) {
        state = [[FLEXInternalRequestState alloc] init];
        state.requestID = [[self class] nextRequestID];
        [_connectionStates setObject:state forKey:key];
    }

    return state;
}

- (NSString *)requestIDForConnection:(NSURLConnection *)connection
{
    return [self requestStateForConnection:connection].requestID;
}

- (void)setRequest:(NSURLRequest *)request forConnection:(NSURLConnection *)connection
{
    [self requestStateForConnection:connection].request = request;
}

- (NSURLRequest *)requestForConnection:(NSURLConnection *)connection
{
    return [self requestStateForConnection:connection].request;
}

- (void)setAccumulatedData:(NSMutableData *)data forConnection:(NSURLConnection *)connection
{
    FLEXInternalRequestState *requestState = [self requestStateForConnection:connection];
    requestState.dataAccumulator = data;
}

- (void)addAccumulatedData:(NSData *)data forConnection:(NSURLConnection *)connection
{
    NSMutableData *dataAccumulator = [self requestStateForConnection:connection].dataAccumulator;
    
    [dataAccumulator appendData:data];
}

- (NSData *)accumulatedDataForConnection:(NSURLConnection *)connection
{
    return [self requestStateForConnection:connection].dataAccumulator;
}

// This removes storing the accumulated request/response from the dictionary so we can release connection
- (void)connectionFinished:(NSURLConnection *)connection
{
    NSValue *key = [NSValue valueWithNonretainedObject:connection];
    [_connectionStates removeObjectForKey:key];
}

#pragma mark - Private Methods (Tasks)

- (FLEXInternalRequestState *)requestStateForTask:(NSURLSessionTask *)task
{
    NSValue *key = [NSValue valueWithNonretainedObject:task];
    FLEXInternalRequestState *state = [_connectionStates objectForKey:key];
    if (!state) {
        state = [[FLEXInternalRequestState alloc] init];
        state.requestID = [[self class] nextRequestID];
        [_connectionStates setObject:state forKey:key];
    }

    return state;
}

- (NSString *)requestIDForTask:(NSURLSessionTask *)task
{
    return [self requestStateForTask:task].requestID;
}

- (void)setRequest:(NSURLRequest *)request forTask:(NSURLSessionTask *)task
{
    [self requestStateForTask:task].request = request;
}

- (NSURLRequest *)requestForTask:(NSURLSessionTask *)task
{
    return [self requestStateForTask:task].request;
}

- (void)setAccumulatedData:(NSMutableData *)data forTask:(NSURLSessionTask *)task
{
    FLEXInternalRequestState *requestState = [self requestStateForTask:task];
    requestState.dataAccumulator = data;
}

- (void)addAccumulatedData:(NSData *)data forTask:(NSURLSessionTask *)task
{
    NSMutableData *dataAccumulator = [self requestStateForTask:task].dataAccumulator;

    [dataAccumulator appendData:data];
}

- (NSData *)accumulatedDataForTask:(NSURLSessionTask *)task
{
    return [self requestStateForTask:task].dataAccumulator;
}

// This removes storing the accumulated request/response from the dictionary so we can release task
- (void)taskFinished:(NSURLSessionTask *)task
{
    NSValue *key = [NSValue valueWithNonretainedObject:task];
    [_connectionStates removeObjectForKey:key];
}

@end


@implementation FLEXNetworkObserver (NSURLConnectionHelpers)

- (void)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response delegate:(id<NSURLConnectionDelegate>)delegate
{
    [self performBlock:^{
        [self setRequest:request forConnection:connection];
        NSString *requestId = [self requestIDForConnection:connection];
        [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestId:requestId request:request redirectResponse:response requestMechanism:[NSString stringWithFormat:@"NSURLConnection (%@)", [delegate class]]];
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response delegate:(id<NSURLConnectionDelegate>)delegate
{
    [self performBlock:^{
        // If the request wasn't generated yet, then willSendRequest was not called. This appears to be an inconsistency in documentation
        // and behavior.
        NSURLRequest *request = [self requestForConnection:connection];
        if (!request) {
            request = connection.currentRequest;
            [self setRequest:request forConnection:connection];
            [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestId:[self requestIDForConnection:connection] request:request redirectResponse:nil requestMechanism:[NSString stringWithFormat:@"NSURLConnection (delegate: %@)", [delegate class]]];
        }

        NSMutableData *dataAccumulator = nil;
        if (response.expectedContentLength < 0) {
            dataAccumulator = [[NSMutableData alloc] init];
        } else {
            dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger)response.expectedContentLength];
        }

        [self setAccumulatedData:dataAccumulator forConnection:connection];

        NSString *requestID = [self requestIDForConnection:connection];
        [[FLEXNetworkRecorder defaultRecorder] recordResponseReceivedWithRequestId:requestID request:connection.currentRequest response:response];
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data delegate:(id<NSURLConnectionDelegate>)delegate
{
    // Just to be safe since we're doing this async
    data = [data copy];
    [self performBlock:^{
        [self addAccumulatedData:data forConnection:connection];

        if ([self accumulatedDataForConnection:connection] == nil) return;
        
        NSString *requestID = [self requestIDForConnection:connection];
        
        [[FLEXNetworkRecorder defaultRecorder] recordDataReceivedWithRequestId:requestID request:connection.currentRequest dataLength:data.length];
    }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection delegate:(id<NSURLConnectionDelegate>)delegate
{
    [self performBlock:^{
        NSString *requestID = [self requestIDForConnection:connection];

        NSData *accumulatedData = [self accumulatedDataForConnection:connection];
        
        [[FLEXNetworkRecorder defaultRecorder] recordLoadingFinishedWithRequestId:requestID request:connection.currentRequest responseBody:accumulatedData];
        
        [self connectionFinished:connection];
    }];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error delegate:(id<NSURLConnectionDelegate>)delegate
{
    [self performBlock:^{
        NSString *requestID = [self requestIDForConnection:connection];
        [[FLEXNetworkRecorder defaultRecorder] recordLoadingFailedWithRequestId:requestID request:connection.currentRequest error:error];
        
        [self connectionFinished:connection];
    }];
}

@end


@implementation FLEXNetworkObserver (NSURLSessionTaskHelpers)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler delegate:(id<NSURLSessionDelegate>)delegate
{
    [self performBlock:^{
        [self setRequest:request forTask:task];
        [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestId:[self requestIDForTask:task] request:request redirectResponse:response requestMechanism:[NSString stringWithFormat:@"NSURLSessionTask (delegate: %@)", [delegate class]]];
    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler delegate:(id<NSURLSessionDelegate>)delegate
{
    // willSendRequest does not exist in NSURLSession. Here's a workaround.
    NSURLRequest *request = [self requestForTask:dataTask];
    if (!request) {
        request = dataTask.currentRequest;
        [self setRequest:request forTask:dataTask];

        [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestId:[self requestIDForTask:dataTask] request:request redirectResponse:nil requestMechanism:[NSString stringWithFormat:@"NSURLSessionDataTask (delegate: %@)", [delegate class]]];
    }

    NSMutableData *dataAccumulator = nil;
    if (response.expectedContentLength < 0) {
        dataAccumulator = [[NSMutableData alloc] init];
    } else {
        dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger)response.expectedContentLength];
    }

    [self setAccumulatedData:dataAccumulator forTask:dataTask];

    NSString *requestID = [self requestIDForTask:dataTask];
    [[FLEXNetworkRecorder defaultRecorder] recordResponseReceivedWithRequestId:requestID request:dataTask.currentRequest response:response];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data delegate:(id<NSURLSessionDelegate>)delegate
{
    // Just to be safe since we're doing this async
    data = [data copy];
    [self performBlock:^{
        [self addAccumulatedData:data forTask:dataTask];

        if ([self accumulatedDataForTask:dataTask] == nil) return;

        NSString *requestID = [self requestIDForTask:dataTask];

        [[FLEXNetworkRecorder defaultRecorder] recordDataReceivedWithRequestId:requestID request:dataTask.currentRequest dataLength:data.length];
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error delegate:(id<NSURLSessionDelegate>)delegate
{
    [self performBlock:^{
        NSString *requestID = [self requestIDForTask:task];

        NSData *accumulatedData = [self accumulatedDataForTask:task];

        if (error) {
            [[FLEXNetworkRecorder defaultRecorder] recordLoadingFailedWithRequestId:requestID request:task.currentRequest error:error];
        } else {
            [[FLEXNetworkRecorder defaultRecorder] recordLoadingFinishedWithRequestId:requestID request:task.currentRequest responseBody:accumulatedData];
        }

        [self taskFinished:task];
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite delegate:(id<NSURLSessionDelegate>)delegate
{
    [self performBlock:^{
        // If the request wasn't generated yet, then willSendRequest was not called. This appears to be an inconsistency in documentation
        // and behavior.
        NSURLRequest *request = [self requestForTask:downloadTask];
        if (!request) {
            request = downloadTask.currentRequest;
            [self setRequest:request forTask:downloadTask];
            NSString *requestID = [self requestIDForTask:downloadTask];

            [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestId:requestID request:request redirectResponse:nil requestMechanism:[NSString stringWithFormat:@"NSURLSessionDownloadTask (delegate: %@)", [delegate class]]];

            NSMutableData *dataAccumulator = nil;
            dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger) totalBytesExpectedToWrite];
            [self setAccumulatedData:dataAccumulator forTask:downloadTask];

            [[FLEXNetworkRecorder defaultRecorder] recordResponseReceivedWithRequestId:requestID request:request response:downloadTask.response];
        }

        NSString *requestID = [self requestIDForTask:downloadTask];

        [[FLEXNetworkRecorder defaultRecorder] recordDataReceivedWithRequestId:requestID request:downloadTask.currentRequest dataLength:bytesWritten];
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location data:(NSData *)data delegate:(id<NSURLSessionDelegate>)delegate
{
    [self performBlock:^{
        NSString *requestID = [self requestIDForTask:downloadTask];
        [[FLEXNetworkRecorder defaultRecorder] recordLoadingFinishedWithRequestId:requestID request:downloadTask.currentRequest responseBody:data];

        [self taskFinished:downloadTask];
    }];
}

@end
