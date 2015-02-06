//
//  FLEXNetworkObserver.h
//  Derived from:
//
//  PDAFNetworkDomainController.h
//  PonyDebugger
//
//  Created by Mike Lewis on 2/27/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

@class FLEXNetworkRecorder;

/// This class swizzles NSURLConnection and NSURLSession delegate methods to observe events in the URL loading system.
/// High level network events are sent to the default FLEXNetworkRecorder instance which maintains the request history and caches response bodies.
@interface FLEXNetworkObserver : NSObject

/// Swizzling occurs when the observer is enabled for the first time.
/// This reduces the impact of FLEX if network debugging is not desired.
+ (void)setEnabled:(BOOL)enabled;

@end
