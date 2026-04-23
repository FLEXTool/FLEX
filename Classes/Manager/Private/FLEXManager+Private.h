//
//  FLEXManager+Private.h
//  PebbleApp
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXWindow.h"

@class FLEXUserGlobalEntriesContainer, FLEXExplorerViewController;

@interface FLEXManager (Private)

@property (nonatomic, readonly) FLEXWindow *explorerWindow;
@property (nonatomic, readonly) FLEXExplorerViewController *explorerViewController;

@property (nonatomic, readonly) NSMutableDictionary<NSString *, FLEXCustomContentViewerFuture> *customContentTypeViewers;

@end
