//
//  FLEXSwiftPrintRedirector.h
//  FLEX
//
//  Created by 김인환 on 2025.
//  Copyright © 2025 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FLEXSystemLogMessage;

/// Redirects Swift print() output to FLEX System Log
@interface FLEXSwiftPrintRedirector : NSObject

/// Enable redirection of stdout/stderr to capture Swift print output
+ (void)enableSwiftPrintRedirection;

/// Disable redirection and restore original stdout/stderr
+ (void)disableSwiftPrintRedirection;

/// Check if redirection is currently enabled
+ (BOOL)isRedirectionEnabled;

/// Set a callback to receive captured messages
+ (void)setMessageHandler:(void(^)(FLEXSystemLogMessage *message))handler;

@end

NS_ASSUME_NONNULL_END