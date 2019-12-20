//
//  FLEXObjectExplorerFactory.h
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXGlobalsEntry.h"

#ifndef _FLEXObjectExplorerViewController_h
#import "FLEXObjectExplorerViewController.h"
#else
@class FLEXObjectExplorerViewController;
#endif

@interface FLEXObjectExplorerFactory : NSObject <FLEXGlobalsEntry>

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object;

@end
