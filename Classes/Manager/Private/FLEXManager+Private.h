//
//  FLEXManager+Private.h
//  PebbleApp
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXWindow.h"

@class FLEXGlobalsEntry, FLEXExplorerViewController;

@interface FLEXManager (Private)

@property (nonatomic, readonly) FLEXWindow *explorerWindow;
@property (nonatomic, readonly) FLEXExplorerViewController *explorerViewController;

/// An array of FLEXGlobalsEntry objects that have been registered by the user.
@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *userGlobalEntries;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, FLEXCustomContentViewerFuture> *customContentTypeViewers;

@end
