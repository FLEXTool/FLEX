//
//  FLEXManager.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerToolbar.h"

#if !FLEX_AT_LEAST_IOS13_SDK
@class UIWindowScene;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager : NSObject

@property (nonatomic, readonly, class) FLEXManager *sharedManager;

@property (nonatomic, readonly) BOOL isHidden;
@property (nonatomic, readonly) FLEXExplorerToolbar *toolbar;

- (void)showExplorer;
- (void)hideExplorer;
- (void)toggleExplorer;

/// Use this to present the explorer in a specific scene when the one
/// it chooses by default is not the one you wish to display it in.
- (void)showExplorerFromScene:(UIWindowScene *)scene API_AVAILABLE(ios(13.0));

#pragma mark - Misc

/// Default database password is @c nil by default.
/// Set this to the password you want the databases to open with.
@property (copy, nonatomic) NSString *defaultSqliteDatabasePassword;

@end


typedef UIViewController * _Nullable(^FLEXCustomContentViewerFuture)(NSData *data);

NS_ASSUME_NONNULL_END
