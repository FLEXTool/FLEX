//
//  FLEXObjectExplorerFactory.h
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FLEXObjectExplorerViewController;

@interface FLEXObjectExplorerFactory : NSObject

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object;

@end
