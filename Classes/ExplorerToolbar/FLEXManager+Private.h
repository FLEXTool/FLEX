//
//  FLEXManager+Private.h
//  PebbleApp
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 Pebble Technology. All rights reserved.
//

#import "FLEXManager.h"

@interface FLEXManager ()

/// An array of FLEXGlobalsTableViewControllerEntry objects that have been registered by the user.
@property (nonatomic, readonly, strong) NSArray *userGlobalEntries;

@end
