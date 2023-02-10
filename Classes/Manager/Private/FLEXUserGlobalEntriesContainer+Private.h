//
//  FLEXUserGlobalEntriesContainer+Private.h
//  FLEX
//
//  Created by Iulian Onofrei on 2023-02-10.
//  Copyright © 2023 FLEX Team. All rights reserved.
//

#import "FLEXUserGlobalEntriesContainer.h"

@class FLEXGlobalsEntry;

@interface FLEXUserGlobalEntriesContainer (Private)

/// An array of FLEXGlobalsEntry objects that have been registered by the user.
@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *entries;

@end
