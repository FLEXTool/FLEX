//
//  FLEXBookmarkManager.m
//  FLEX
//
//  Created by Tanner on 2/6/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXBookmarkManager.h"

static NSMutableArray *kFLEXBookmarkManagerBookmarks = nil;

@implementation FLEXBookmarkManager

+ (void)initialize {
    if (self == [FLEXBookmarkManager class]) {
        kFLEXBookmarkManagerBookmarks = [NSMutableArray new];
    }
}

+ (NSMutableArray *)bookmarks {
    return kFLEXBookmarkManagerBookmarks;
}

@end
