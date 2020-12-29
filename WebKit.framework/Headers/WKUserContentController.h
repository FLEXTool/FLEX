/*
 * Copyright (C) 2014-2017 Apple Inc. All rights reserved.
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

@class WKContentRuleList;
@class WKUserScript;
@protocol WKScriptMessageHandler;

/*! A WKUserContentController object provides a way for JavaScript to post
 messages to a web view.
 The user content controller associated with a web view is specified by its
 web view configuration.
 */
WK_EXTERN API_AVAILABLE(macos(10.10), ios(8.0))
@interface WKUserContentController : NSObject <NSSecureCoding>

/*! @abstract The user scripts associated with this user content
 controller.
*/
@property (nonatomic, readonly, copy) NSArray<WKUserScript *> *userScripts;

/*! @abstract Adds a user script.
 @param userScript The user script to add.
*/
- (void)addUserScript:(WKUserScript *)userScript;

/*! @abstract Removes all associated user scripts.
*/
- (void)removeAllUserScripts;

/*! @abstract Adds a script message handler.
 @param scriptMessageHandler The message handler to add.
 @param name The name of the message handler.
 @discussion Adding a scriptMessageHandler adds a function
 window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all
 frames.
 */
- (void)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;

/*! @abstract Removes a script message handler.
 @param name The name of the message handler to remove.
 */
- (void)removeScriptMessageHandlerForName:(NSString *)name;

/*! @abstract Adds a content rule list.
 @param contentRuleList The content rule list to add.
 */
- (void)addContentRuleList:(WKContentRuleList *)contentRuleList API_AVAILABLE(macos(10.13), ios(11.0));

/*! @abstract Removes a content rule list.
 @param contentRuleList The content rule list to remove.
 */
- (void)removeContentRuleList:(WKContentRuleList *)contentRuleList API_AVAILABLE(macos(10.13), ios(11.0));

/*! @abstract Removes all associated content rule lists.
 */
- (void)removeAllContentRuleLists API_AVAILABLE(macos(10.13), ios(11.0));

@end

NS_ASSUME_NONNULL_END
