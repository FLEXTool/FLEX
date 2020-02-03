//
//  FLEXManager+Networking.m
//  FLEX
//
//  Created by Tanner on 2/1/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXManager+Networking.h"
#import "FLEXManager+Private.h"
#import "FLEXNetworkObserver.h"
#import "FLEXNetworkRecorder.h"

@implementation FLEXManager (Networking)

- (BOOL)isNetworkDebuggingEnabled {
    return FLEXNetworkObserver.isEnabled;
}

- (void)setNetworkDebuggingEnabled:(BOOL)networkDebuggingEnabled {
    FLEXNetworkObserver.enabled = networkDebuggingEnabled;
}

- (NSUInteger)networkResponseCacheByteLimit {
    return FLEXNetworkRecorder.defaultRecorder.responseCacheByteLimit;
}

- (void)setNetworkResponseCacheByteLimit:(NSUInteger)networkResponseCacheByteLimit {
    FLEXNetworkRecorder.defaultRecorder.responseCacheByteLimit = networkResponseCacheByteLimit;
}

- (NSArray<NSString *> *)networkRequestHostBlacklist {
    return FLEXNetworkRecorder.defaultRecorder.hostBlacklist;
}

- (void)setNetworkRequestHostBlacklist:(NSArray<NSString *> *)networkRequestHostBlacklist {
    FLEXNetworkRecorder.defaultRecorder.hostBlacklist = networkRequestHostBlacklist;
}

- (void)setCustomViewerForContentType:(NSString *)contentType viewControllerFutureBlock:(FLEXCustomContentViewerFuture)viewControllerFutureBlock {
    NSParameterAssert(contentType.length);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    self.customContentTypeViewers[contentType.lowercaseString] = viewControllerFutureBlock;
}

@end
