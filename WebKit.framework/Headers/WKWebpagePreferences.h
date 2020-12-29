/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

/*! @enum WKContentMode
 @abstract A content mode represents the type of content to load, as well as
 additional layout and rendering adaptations that are applied as a result of
 loading the content
 @constant WKContentModeRecommended  The recommended content mode for the current platform
 @constant WKContentModeMobile       Represents content targeting mobile browsers
 @constant WKContentModeDesktop      Represents content targeting desktop browsers
 @discussion WKContentModeRecommended behaves like WKContentModeMobile on iPhone and iPad mini
 and WKContentModeDesktop on other iPad models as well as Mac.
 */
typedef NS_ENUM(NSInteger, WKContentMode) {
    WKContentModeRecommended,
    WKContentModeMobile,
    WKContentModeDesktop
} API_AVAILABLE(ios(13.0));

/*! A WKWebpagePreferences object is a collection of properties that
 determine the preferences to use when loading and rendering a page.
 @discussion Contains properties used to determine webpage preferences.
 */
WK_EXTERN API_AVAILABLE(macos(10.15), ios(13.0))
@interface WKWebpagePreferences : NSObject

/*! @abstract A WKContentMode indicating the content mode to prefer
 when loading and rendering a webpage.
 @discussion The default value is WKContentModeRecommended. The stated
 preference is ignored on subframe navigation
 */
@property (nonatomic) WKContentMode preferredContentMode API_AVAILABLE(ios(13.0));

@end
