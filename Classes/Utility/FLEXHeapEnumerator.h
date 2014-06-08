//
//  FLEXHeapEnumerator.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^flex_object_enumeration_block_t)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

@interface FLEXHeapEnumerator : NSObject

+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)block;

@end
