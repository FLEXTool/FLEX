/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <WebKit/WKFoundation.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WKHTTPCookieStore;

API_AVAILABLE(macos(10.13), ios(11.0))
@protocol WKHTTPCookieStoreObserver <NSObject>
@optional
- (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore;
@end

/*!
 A WKHTTPCookieStore object allows managing the HTTP cookies associated with a particular WKWebsiteDataStore.
 */
WK_EXTERN API_AVAILABLE(macos(10.13), ios(11.0))
@interface WKHTTPCookieStore : NSObject

- (instancetype)init NS_UNAVAILABLE;

/*! @abstract Fetches all stored cookies.
 @param completionHandler A block to invoke with the fetched cookies.
 */
- (void)getAllCookies:(void (^)(NSArray<NSHTTPCookie *> *))completionHandler;

/*! @abstract Set a cookie.
 @param cookie The cookie to set.
 @param completionHandler A block to invoke once the cookie has been stored.
 */
- (void)setCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;

/*! @abstract Delete the specified cookie.
 @param completionHandler A block to invoke once the cookie has been deleted.
 */
- (void)deleteCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;

/*! @abstract Adds a WKHTTPCookieStoreObserver object with the cookie store.
 @param observer The observer object to add.
 @discussion The observer is not retained by the receiver. It is your responsibility
 to unregister the observer before it becomes invalid.
 */
- (void)addObserver:(id<WKHTTPCookieStoreObserver>)observer;

/*! @abstract Removes a WKHTTPCookieStoreObserver object from the cookie store.
 @param observer The observer to remove.
 */
- (void)removeObserver:(id<WKHTTPCookieStoreObserver>)observer;

@end

NS_ASSUME_NONNULL_END
