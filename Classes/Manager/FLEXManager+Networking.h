//
//  FLEXManager+Networking.h
//  FLEX
//
//  Created by Tanner on 2/1/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Networking)

/// If this property is set to YES, FLEX will swizzle NSURLConnection*Delegate and NSURLSession*Delegate methods
/// on classes that conform to the protocols. This allows you to view network activity history from the main FLEX menu.
/// Full responses are kept temporarily in a size-limited cache and may be pruned under memory pressure.
@property (nonatomic, getter=isNetworkDebuggingEnabled) BOOL networkDebuggingEnabled;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
/// The response cache uses an NSCache, so it may purge prior to hitting the limit when the app is under memory pressure.
@property (nonatomic) NSUInteger networkResponseCacheByteLimit;

/// Requests whose host ends with one of the excluded entries in this array will be not be recorded (eg. google.com).
/// Wildcard or subdomain entries are not required (eg. google.com will match any subdomain under google.com).
/// Useful to remove requests that are typically noisy, such as analytics requests that you aren't interested in tracking.
@property (nonatomic) NSMutableArray<NSString *> *networkRequestHostDenylist;

/// Sets custom viewer for specific content type.
/// @param contentType Mime type like application/json
/// @param viewControllerFutureBlock Viewer (view controller) creation block
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retain for the duration of the application, you may want to use __weak references.
- (void)setCustomViewerForContentType:(NSString *)contentType
            viewControllerFutureBlock:(FLEXCustomContentViewerFuture)viewControllerFutureBlock;

@end

NS_ASSUME_NONNULL_END
