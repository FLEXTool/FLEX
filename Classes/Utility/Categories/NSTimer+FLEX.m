//
//  NSTimer+Blocks.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//

#import "NSTimer+FLEX.h"

@interface Block : NSObject
- (void)invoke;
@end

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NSTimer (Blocks)

+ (instancetype)flex_fireSecondsFromNow:(NSTimeInterval)delay block:(VoidBlock)block {
    return [self scheduledTimerWithTimeInterval:delay repeats:NO block:(id)block];
}

@end
